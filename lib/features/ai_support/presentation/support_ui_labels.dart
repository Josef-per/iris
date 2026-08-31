import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

const patientAvailableSupportCategories = <SupportSuggestionCategory>[
  SupportSuggestionCategory.reflection,
  SupportSuggestionCategory.exercise,
];

const patientAvailableSupportSources = <SupportSignalSource>[
  SupportSignalSource.moodHistory,
  SupportSignalSource.diaryTags,
  SupportSignalSource.notificationInteractions,
];

extension SupportSignalSourceLabels on SupportSignalSource {
  String get label => switch (this) {
    SupportSignalSource.moodHistory => 'Humor dos últimos dias',
    SupportSignalSource.diaryTags => 'Tags escolhidas no diário',
    SupportSignalSource.exerciseFeedback =>
      'Avaliação de exercícios concluídos',
    SupportSignalSource.notificationInteractions =>
      'O que você abre ou prefere não receber',
  };

  String get description => switch (this) {
    SupportSignalSource.moodHistory =>
      'Usado somente para notar uma tendência simples em check-ins estruturados.',
    SupportSignalSource.diaryTags =>
      'Usado apenas quando você escolhe e confirma uma tag da lista fechada.',
    SupportSignalSource.exerciseFeedback =>
      'Evita repetir logo uma prática marcada como não útil.',
    SupportSignalSource.notificationInteractions =>
      'Ajuda a priorizar o que funciona e reduzir o que incomoda.',
  };
}

extension SupportSuggestionCategoryLabels on SupportSuggestionCategory {
  String get label => switch (this) {
    SupportSuggestionCategory.reflection => 'Reflexão',
    SupportSuggestionCategory.exercise => 'Exercício',
    SupportSuggestionCategory.video => 'Vídeo',
    SupportSuggestionCategory.humanConnection => 'Conexão humana',
    SupportSuggestionCategory.professionalConversation =>
      'Conversa com profissional',
  };
}

extension NotificationFrequencyLabels on NotificationFrequency {
  String get label => switch (this) {
    NotificationFrequency.never => 'Nunca',
    NotificationFrequency.oncePerWeek => 'Até 1 por semana',
    NotificationFrequency.twicePerWeek => 'Até 2 por semana',
    NotificationFrequency.threeTimesPerWeek => 'Até 3 por semana',
  };
}

extension LockScreenPreviewLabels on LockScreenPreview {
  String get label => switch (this) {
    LockScreenPreview.none => 'Ocultar conteúdo',
    LockScreenPreview.generic => 'Prévia genérica',
  };
}

extension SupportReasonCodeLabels on SupportReasonCode {
  String get explanation => switch (this) {
    SupportReasonCode.todayDifficultCheckIn =>
      'o check-in de hoje indicou um momento mais difícil',
    SupportReasonCode.todaySteadyCheckIn =>
      'o check-in de hoje ficou no meio da escala',
    SupportReasonCode.todayLighterCheckIn =>
      'o check-in de hoje indicou um momento mais leve',
    SupportReasonCode.recentDifficultCheckIns =>
      'alguns check-ins estruturados recentes pareceram mais difíceis',
    SupportReasonCode.prefersShortPractice => 'você prefere práticas curtas',
    SupportReasonCode.confirmedOverload =>
      'você confirmou uma tag sobre sobrecarga',
    SupportReasonCode.confirmedLoneliness =>
      'você confirmou uma tag sobre solidão',
    SupportReasonCode.confirmedSelfKindness =>
      'você escolheu um tema de autogentileza no diário',
    SupportReasonCode.preferredFromPastInteractions =>
      'você costuma abrir este tipo de apoio',
    SupportReasonCode.previousExerciseWasNotHelpful =>
      'um exercício anterior foi marcado como não útil',
  };
}

String formatSupportTime(SupportTimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
