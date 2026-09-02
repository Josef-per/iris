import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_builder.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/emotional_diary/daily_emotional_record.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/emotional_diary/emotional_diary_support_topics.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);

  DailyEmotionalRecord record({
    required String id,
    required int daysAgo,
    int? moodScore,
    Set<String> topics = const <String>{},
    DateTime? updatedAt,
  }) {
    final recordedAt = now.subtract(Duration(days: daysAgo));
    return DailyEmotionalRecord(
      id: id,
      localDay: DateTime.utc(recordedAt.year, recordedAt.month, recordedAt.day),
      recordedAt: recordedAt,
      updatedAt: updatedAt,
      moodScore: moodScore,
      confirmedSupportTopicCodes: topics,
    );
  }

  group('DailyEmotionalRecord', () {
    test('mapeia só check-in e tópicos, ignorando os demais campos', () {
      final result = DailyEmotionalRecord.fromMap(<String, dynamic>{
        'id': 'record-1',
        'data_local': '2026-08-24',
        'data_registro': '2026-08-24T10:00:00Z',
        'atualizado_em': '2026-08-24T11:00:00Z',
        'humor': 'Difícil',
        'como_sentiu': 2,
        'avaliacao_alimentacao': 3,
        'sintomas_emocionais_hoje': <String>['ansiedade'],
        'sintomas_fisicos_hoje': <String>['tontura'],
        'topicos_apoio': <String>['overload', 'loneliness'],
        'diario_emocional': 'este texto não pertence ao modelo estruturado',
      });

      expect(result.id, 'record-1');
      expect(result.moodScore, 2);
      expect(result.confirmedSupportTopicCodes, <String>{
        'overload',
        'loneliness',
      });
      expect(result.updatedAt, DateTime.utc(2026, 8, 24, 11));
    });

    test(
      'rejeita score fora da escala em vez de normalizar silenciosamente',
      () {
        expect(
          () => DailyEmotionalRecord.fromMap(<String, dynamic>{
            'id': 'record-1',
            'data_local': '2026-08-24',
            'data_registro': '2026-08-24T10:00:00Z',
            'como_sentiu': 6,
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('EmotionalDiarySupportTopic', () {
    test('mantém apenas tópicos confirmados, válidos e não expirados', () {
      final rows = <Map<String, dynamic>>[
        {
          'topico': 'overload',
          'estado': 'confirmado',
          'expira_em': now.add(const Duration(days: 1)).toIso8601String(),
          'invalidado_em': null,
        },
        {
          'topico': 'loneliness',
          'estado': 'pendente',
          'expira_em': now.add(const Duration(days: 1)).toIso8601String(),
          'invalidado_em': null,
        },
        {
          'topico': 'self_kindness',
          'estado': 'confirmado',
          'expira_em': now
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
          'invalidado_em': null,
        },
        {
          'topico': 'loneliness',
          'estado': 'confirmado',
          'expira_em': now.add(const Duration(days: 1)).toIso8601String(),
          'invalidado_em': now.toIso8601String(),
        },
        {
          'topico': 'unknown',
          'estado': 'confirmado',
          'expira_em': now.add(const Duration(days: 1)).toIso8601String(),
          'invalidado_em': null,
        },
      ];

      expect(
        EmotionalDiarySupportTopic.confirmedCodesFromRows(rows, now: now),
        <String>{EmotionalDiarySupportTopic.overload},
      );
    });
  });

  group('AiSupportSignalBuilder', () {
    test('resume os quatro check-ins mais recentes em tendência difícil', () {
      final signals = const AiSupportSignalBuilder().build(
        records: <DailyEmotionalRecord>[
          record(id: 'today', daysAgo: 0, moodScore: 2),
          record(id: 'one', daysAgo: 1, moodScore: 1),
          record(id: 'two', daysAgo: 2, moodScore: 2),
          record(id: 'three', daysAgo: 3, moodScore: 4),
          record(id: 'older', daysAgo: 4, moodScore: 1),
        ],
        now: now,
      );

      final mood = signals.whereType<MoodTrendSignal>().single;
      expect(mood.direction, MoodTrendDirection.difficult);
      expect(mood.difficultCheckInCount, 3);
      expect(mood.sampleSize, 4);
      expect(mood.windowDays, 7);
    });

    test('converte apenas tópicos conhecidos e mantém o mais recente', () {
      final signals = const AiSupportSignalBuilder().build(
        records: <DailyEmotionalRecord>[
          record(
            id: 'today',
            daysAgo: 0,
            topics: const <String>{'overload', 'unknown'},
          ),
          record(
            id: 'yesterday',
            daysAgo: 1,
            topics: const <String>{'sobrecarga', 'solidão'},
          ),
        ],
        now: now,
      );

      final topics = signals.whereType<ConfirmedTopicSignal>().toList();
      expect(topics, hasLength(2));
      expect(topics.map((signal) => signal.topic), <SupportTopicKey>{
        SupportTopicKey.overload,
        SupportTopicKey.loneliness,
      });
      expect(topics.every((signal) => signal.isConfirmed), isTrue);
      expect(
        topics
            .singleWhere((signal) => signal.topic == SupportTopicKey.overload)
            .createdAt,
        now,
      );
    });

    test('não produz sinais vencidos nem usa registros futuros', () {
      final old = record(
        id: 'old',
        daysAgo: 8,
        moodScore: 1,
        topics: const <String>{'loneliness'},
      );
      final future = DailyEmotionalRecord(
        id: 'future',
        localDay: now.add(const Duration(days: 1)),
        recordedAt: now.add(const Duration(days: 1)),
        moodScore: 1,
        confirmedSupportTopicCodes: const <String>{'overload'},
      );

      final signals = const AiSupportSignalBuilder().build(
        records: <DailyEmotionalRecord>[old, future],
        now: now,
      );

      expect(signals, isEmpty);
    });

    test('não apresenta o check-in de ontem como se fosse de hoje', () {
      final signals = const AiSupportSignalBuilder().build(
        records: <DailyEmotionalRecord>[
          record(id: 'yesterday', daysAgo: 1, moodScore: 2),
        ],
        now: now,
      );

      expect(signals.whereType<DailyCheckInSignal>(), isEmpty);
      expect(signals.whereType<MoodTrendSignal>(), hasLength(1));
    });
  });

  test(
    'repositório solicita a janela configurada e entrega sinais tipados',
    () async {
      final source = _StructuredDataSource(<DailyEmotionalRecord>[
        record(id: 'today', daysAgo: 0, moodScore: 2),
        record(id: 'one', daysAgo: 1, moodScore: 1),
        record(id: 'two', daysAgo: 2, moodScore: 2),
        record(id: 'three', daysAgo: 3, moodScore: 4),
      ]);
      final repository = AiSupportSignalRepository(
        emotionalDiary: source,
        historyDays: 7,
        clock: () => now,
      );

      final signals = await repository.loadRecentSignals();

      expect(source.requestedDays, 7);
      expect(signals.whereType<MoodTrendSignal>(), hasLength(1));
    },
  );
}

class _StructuredDataSource implements StructuredEmotionalDiaryDataSource {
  _StructuredDataSource(this.records);

  final List<DailyEmotionalRecord> records;
  int? requestedDays;

  @override
  Future<List<DailyEmotionalRecord>> listRecentStructuredRecords({
    int days = 7,
  }) async {
    requestedDays = days;
    return records;
  }
}
