import 'package:iris/features/ai_support/data/ai_support_signal_builder.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';

abstract interface class AiSupportSignalDataSource {
  Future<List<SupportSignal>> loadRecentSignals();
}

/// Carrega somente o histórico estruturado e o converte em sinais de apoio.
class AiSupportSignalRepository implements AiSupportSignalDataSource {
  AiSupportSignalRepository({
    required StructuredEmotionalDiaryDataSource emotionalDiary,
    AiSupportSignalBuilder builder = const AiSupportSignalBuilder(),
    DateTime Function()? clock,
    this.historyDays = 7,
  }) : _emotionalDiary = emotionalDiary,
       _builder = builder,
       _clock = clock ?? DateTime.now {
    if (historyDays <= 0) {
      throw ArgumentError.value(
        historyDays,
        'historyDays',
        'Informe ao menos um dia.',
      );
    }
  }

  final StructuredEmotionalDiaryDataSource _emotionalDiary;
  final AiSupportSignalBuilder _builder;
  final DateTime Function() _clock;
  final int historyDays;

  @override
  Future<List<SupportSignal>> loadRecentSignals() async {
    final records = await _emotionalDiary.listRecentStructuredRecords(
      days: historyDays,
    );
    return _builder.build(records: records, now: _clock());
  }
}
