import 'ai_support_consent.dart';
import 'ai_support_preferences.dart';

/// Direção simples de uma tendência de humor estruturada.
enum MoodTrendDirection { difficult, stable, easier }

extension MoodTrendDirectionLabel on MoodTrendDirection {
  String get label => switch (this) {
    MoodTrendDirection.difficult => 'Mais difícil',
    MoodTrendDirection.stable => 'Estável',
    MoodTrendDirection.easier => 'Mais leve',
  };
}

/// Tópicos fechados e confirmáveis pelo usuário.
///
/// Não existe valor que transporte texto bruto do diário.
enum SupportTopicKey { overload, loneliness, selfKindness }

extension SupportTopicKeyLabel on SupportTopicKey {
  String get label => switch (this) {
    SupportTopicKey.overload => 'Sobrecarga',
    SupportTopicKey.loneliness => 'Solidão',
    SupportTopicKey.selfKindness => 'Autogentileza',
  };
}

/// Avaliação estruturada de um exercício já concluído.
enum ExerciseHelpfulness { helpful, neutral, notHelpful, madeThingsWorse }

extension ExerciseHelpfulnessLabel on ExerciseHelpfulness {
  String get label => switch (this) {
    ExerciseHelpfulness.helpful => 'Ajudou',
    ExerciseHelpfulness.neutral => 'Foi neutro',
    ExerciseHelpfulness.notHelpful => 'Não ajudou',
    ExerciseHelpfulness.madeThingsWorse => 'Piorou',
  };
}

/// Interações que podem ser usadas somente para reduzir interrupções.
enum NotificationInteractionType { opened, dismissed, markedUnhelpful }

/// Sinal mínimo e temporário usado pelo recomendador local.
abstract class SupportSignal {
  const SupportSignal({
    required this.id,
    required this.source,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Identificador opaco local. Nunca contém texto de diário.
  final String id;
  final SupportSignalSource source;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isUsableAt(DateTime now) => now.isBefore(expiresAt);
}

/// Tendência calculada somente a partir de check-ins de humor estruturados.
class MoodTrendSignal extends SupportSignal {
  const MoodTrendSignal({
    required super.id,
    required super.createdAt,
    required super.expiresAt,
    required this.direction,
    required this.difficultCheckInCount,
    required this.sampleSize,
    required this.windowDays,
  }) : assert(difficultCheckInCount >= 0),
       assert(sampleSize > 0),
       assert(difficultCheckInCount <= sampleSize),
       assert(windowDays > 0),
       super(source: SupportSignalSource.moodHistory);

  final MoodTrendDirection direction;
  final int difficultCheckInCount;
  final int sampleSize;
  final int windowDays;

  bool get hasRecentDifficultPattern {
    return direction == MoodTrendDirection.difficult &&
        difficultCheckInCount >= 3 &&
        sampleSize >= 4;
  }
}

/// Check-in estruturado mais recente, sem texto livre ou sintomas clínicos.
///
/// O sinal permite que a sugestão responda ao registro do próprio dia sem
/// transformar a pontuação em diagnóstico ou avaliação de risco.
class DailyCheckInSignal extends SupportSignal {
  const DailyCheckInSignal({
    required super.id,
    required super.createdAt,
    required super.expiresAt,
    required this.moodScore,
  }) : assert(moodScore >= 1 && moodScore <= 5),
       super(source: SupportSignalSource.moodHistory);

  final int moodScore;

  bool get isDifficult => moodScore <= 2;
  bool get isSteady => moodScore == 3;
  bool get isLighter => moodScore >= 4;
}

/// Tema de uma taxonomia fechada, confirmado ou recusável pela pessoa.
class ConfirmedTopicSignal extends SupportSignal {
  const ConfirmedTopicSignal({
    required super.id,
    required super.createdAt,
    required super.expiresAt,
    required this.topic,
    this.isConfirmed = true,
  }) : super(source: SupportSignalSource.diaryTags);

  final SupportTopicKey topic;

  /// Sinais não confirmados nunca devem influenciar uma recomendação.
  final bool isConfirmed;
}

/// Feedback de exercício sem observação de texto livre.
class ExerciseFeedbackSignal extends SupportSignal {
  const ExerciseFeedbackSignal({
    required super.id,
    required super.createdAt,
    required super.expiresAt,
    required this.exerciseId,
    required this.helpfulness,
  }) : super(source: SupportSignalSource.exerciseFeedback);

  final String exerciseId;
  final ExerciseHelpfulness helpfulness;

  bool get isNegative {
    return helpfulness == ExerciseHelpfulness.notHelpful ||
        helpfulness == ExerciseHelpfulness.madeThingsWorse;
  }
}

/// Interação agregada de notificação, usada apenas para diminuir frequência.
class NotificationInteractionSignal extends SupportSignal {
  const NotificationInteractionSignal({
    required super.id,
    required super.createdAt,
    required super.expiresAt,
    required this.interaction,
    this.templateId,
    this.category,
  }) : super(source: SupportSignalSource.notificationInteractions);

  final NotificationInteractionType interaction;
  final String? templateId;
  final SupportSuggestionCategory? category;
}
