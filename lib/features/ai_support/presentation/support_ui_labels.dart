import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

extension SupportSignalSourceLabels on SupportSignalSource {
  String get label => switch (this) {
    SupportSignalSource.moodHistory => 'Humor dos últimos dias',
    SupportSignalSource.diaryTags => 'Tags escolhidas no diário',
    SupportSignalSource.exerciseFeedback =>
      'Avaliação de exercícios concluídos',
    SupportSignalSource.notificationInteractions =>
      'Interações com notificações simuladas',
  };

  String get description => switch (this) {
    SupportSignalSource.moodHistory =>
      'Usado somente para notar uma tendência simples em check-ins estruturados.',
    SupportSignalSource.diaryTags =>
      'Usado apenas quando você escolhe e confirma uma tag da lista fechada.',
    SupportSignalSource.exerciseFeedback =>
      'Evita repetir logo uma prática marcada como não útil.',
    SupportSignalSource.notificationInteractions =>
      'Reduz interrupções depois de dispensas ou feedback negativo.',
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
    LockScreenPreview.none => 'Nenhuma prévia',
    LockScreenPreview.generic => 'Prévia genérica',
  };
}

extension SupportReasonCodeLabels on SupportReasonCode {
  String get explanation => switch (this) {
    SupportReasonCode.recentDifficultCheckIns =>
      'alguns check-ins estruturados recentes pareceram mais difíceis',
    SupportReasonCode.prefersShortPractice =>
      'a demonstração está configurada para práticas curtas',
    SupportReasonCode.confirmedOverload =>
      'você confirmou uma tag sobre sobrecarga',
    SupportReasonCode.confirmedLoneliness =>
      'você confirmou uma tag sobre solidão',
    SupportReasonCode.previousExerciseWasNotHelpful =>
      'um exercício anterior foi marcado como não útil',
  };
}

String formatSupportTime(SupportTimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
