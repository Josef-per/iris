import 'package:iris/features/ai_support/domain/support_signal.dart';

/// Check-in fictício sem nota textual.
enum MockMoodValue { difficult, neutral, okay }

class MockMoodCheckIn {
  const MockMoodCheckIn({required this.recordedAt, required this.value});

  final DateTime recordedAt;
  final MockMoodValue value;
}

/// Dados estruturados para cenários de demonstração.
abstract final class MockMoodHistory {
  static List<MockMoodCheckIn> difficultPattern(DateTime now) {
    return <MockMoodCheckIn>[
      MockMoodCheckIn(
        recordedAt: now.subtract(const Duration(days: 3)),
        value: MockMoodValue.difficult,
      ),
      MockMoodCheckIn(
        recordedAt: now.subtract(const Duration(days: 2)),
        value: MockMoodValue.difficult,
      ),
      MockMoodCheckIn(
        recordedAt: now.subtract(const Duration(days: 1)),
        value: MockMoodValue.neutral,
      ),
      MockMoodCheckIn(recordedAt: now, value: MockMoodValue.difficult),
    ];
  }

  static MoodTrendSignal trendFrom(
    Iterable<MockMoodCheckIn> checkIns, {
    required DateTime now,
    String id = 'mood-trend-demo-1',
  }) {
    final recent = checkIns.toList(growable: false);
    final difficult = recent.where(
      (checkIn) => checkIn.value == MockMoodValue.difficult,
    );
    return MoodTrendSignal(
      id: id,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 2)),
      direction: difficult.length >= 3
          ? MoodTrendDirection.difficult
          : MoodTrendDirection.stable,
      difficultCheckInCount: difficult.length,
      sampleSize: recent.length,
      windowDays: 4,
    );
  }
}
