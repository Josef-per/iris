import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/food/food_record_repository.dart';

abstract interface class PatientTodayDataSource {
  Future<PatientTodaySummary> loadToday();
}

class PatientTodaySummary {
  const PatientTodaySummary({
    required this.mealCount,
    required this.moodScore,
    required this.hasCheckIn,
    required this.hasDiaryEntry,
  });

  final int mealCount;
  final int? moodScore;
  final bool hasCheckIn;
  final bool hasDiaryEntry;

  String get moodLabel => switch (moodScore) {
    5 => 'Muito feliz',
    4 => 'Bem',
    3 => 'Regular',
    2 => 'Difícil',
    1 => 'Muito difícil',
    _ => 'Sem registro',
  };

  String get checkInLabel => hasCheckIn ? 'Concluído' : 'Aguardando você';
}

class PatientTodayRepository implements PatientTodayDataSource {
  PatientTodayRepository({
    FoodRecordDataSource? foodRecords,
    EmotionalDiaryDataSource? emotionalDiary,
    DateTime Function()? clock,
  }) : _foodRecords = foodRecords ?? FoodRecordRepository(),
       _emotionalDiary = emotionalDiary ?? EmotionalDiaryRepository(),
       _clock = clock ?? DateTime.now;

  final FoodRecordDataSource _foodRecords;
  final EmotionalDiaryDataSource _emotionalDiary;
  final DateTime Function() _clock;

  @override
  Future<PatientTodaySummary> loadToday() async {
    final results = await Future.wait<Object?>([
      _foodRecords.countRecordsForLocalDay(_clock()),
      _emotionalDiary.getTodayRecord(),
    ]);
    final mealCount = results[0] as int;
    final emotionalRecord = results[1] as Map<String, dynamic>?;
    final moodScore = _integer(emotionalRecord?['como_sentiu']);
    final foodScore = _integer(emotionalRecord?['avaliacao_alimentacao']);
    final diary = emotionalRecord?['diario_emocional']?.toString().trim();

    return PatientTodaySummary(
      mealCount: mealCount,
      moodScore: moodScore != null && moodScore >= 1 && moodScore <= 5
          ? moodScore
          : null,
      hasCheckIn: moodScore != null && foodScore != null,
      hasDiaryEntry: diary != null && diary.isNotEmpty,
    );
  }

  int? _integer(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
