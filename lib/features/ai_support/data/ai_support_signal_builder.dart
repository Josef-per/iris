import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/emotional_diary/daily_emotional_record.dart';

/// Converte registros estruturados em sinais mínimos e temporários.
///
/// Alimentação e sintomas permanecem disponíveis no registro clínico, mas não
/// participam deste recomendador geral. O builder nunca recebe texto livre.
class AiSupportSignalBuilder {
  const AiSupportSignalBuilder({
    this.maximumMoodSamples = 4,
    this.moodWindowDays = 7,
    this.moodSignalLifetime = const Duration(days: 2),
    this.topicSignalLifetime = const Duration(days: 7),
  }) : assert(maximumMoodSamples > 0),
       assert(moodWindowDays > 0);

  final int maximumMoodSamples;
  final int moodWindowDays;
  final Duration moodSignalLifetime;
  final Duration topicSignalLifetime;

  List<SupportSignal> build({
    required Iterable<DailyEmotionalRecord> records,
    required DateTime now,
  }) {
    final usableRecords =
        records
            .where((record) => !record.recordedAt.isAfter(now))
            .toList(growable: false)
          ..sort(_newestFirst);

    return <SupportSignal>[
      ..._moodSignals(usableRecords, now),
      ..._topicSignals(usableRecords, now),
    ];
  }

  Iterable<SupportSignal> _moodSignals(
    List<DailyEmotionalRecord> records,
    DateTime now,
  ) sync* {
    final moodRecords = records
        .where((record) => record.moodScore != null)
        .take(maximumMoodSamples)
        .toList(growable: false);
    if (moodRecords.isEmpty) return;

    final latest = moodRecords.first;
    final expiresAt = latest.recordedAt.add(moodSignalLifetime);
    if (!now.isBefore(expiresAt)) return;

    if (_sameLocalDay(latest.localDay, now)) {
      yield DailyCheckInSignal(
        id: _opaqueId('checkin', latest.id, latest.recordedAt),
        createdAt: latest.recordedAt,
        expiresAt: expiresAt,
        moodScore: latest.moodScore!,
      );
    }

    final difficultCount = moodRecords
        .where((record) => record.moodScore! <= 2)
        .length;
    final oldestScore = moodRecords.last.moodScore!;
    final latestScore = latest.moodScore!;
    final direction = moodRecords.length >= 4 && difficultCount >= 3
        ? MoodTrendDirection.difficult
        : moodRecords.length >= 2 && latestScore > oldestScore
        ? MoodTrendDirection.easier
        : MoodTrendDirection.stable;

    yield MoodTrendSignal(
      id: _opaqueId('mood', latest.id, latest.recordedAt),
      createdAt: latest.recordedAt,
      expiresAt: expiresAt,
      direction: direction,
      difficultCheckInCount: difficultCount,
      sampleSize: moodRecords.length,
      windowDays: moodWindowDays,
    );
  }

  Iterable<SupportSignal> _topicSignals(
    List<DailyEmotionalRecord> records,
    DateTime now,
  ) sync* {
    final emitted = <SupportTopicKey>{};
    for (final record in records) {
      final expiresAt = record.updatedAt.add(topicSignalLifetime);
      if (!now.isBefore(expiresAt)) continue;

      final topics = record.confirmedSupportTopicCodes
          .map(_topicFromCode)
          .whereType<SupportTopicKey>()
          .toSet();
      for (final topic in topics) {
        if (!emitted.add(topic)) continue;
        yield ConfirmedTopicSignal(
          id: _opaqueId(
            'topic',
            '${record.id}:${topic.name}',
            record.updatedAt,
          ),
          createdAt: record.updatedAt,
          expiresAt: expiresAt,
          topic: topic,
        );
      }
    }
  }

  int _newestFirst(DailyEmotionalRecord first, DailyEmotionalRecord second) {
    final localDayOrder = second.localDay.compareTo(first.localDay);
    if (localDayOrder != 0) return localDayOrder;
    return second.recordedAt.compareTo(first.recordedAt);
  }

  bool _sameLocalDay(DateTime day, DateTime now) {
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  SupportTopicKey? _topicFromCode(String rawCode) {
    final code = rawCode.trim().toLowerCase().replaceAll('ã', 'a');
    return switch (code) {
      'overload' || 'sobrecarga' => SupportTopicKey.overload,
      'loneliness' || 'solidao' => SupportTopicKey.loneliness,
      'self_kindness' ||
      'selfkindness' ||
      'autogentileza' => SupportTopicKey.selfKindness,
      _ => null,
    };
  }

  String _opaqueId(String prefix, String seed, DateTime createdAt) {
    var hash = 5381;
    for (final unit in seed.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    final timestamp = createdAt.toUtc().millisecondsSinceEpoch.toRadixString(
      36,
    );
    return '$prefix-$timestamp-${hash.abs().toRadixString(36)}';
  }
}
