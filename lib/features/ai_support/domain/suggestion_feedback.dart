/// Feedback estruturado. Não há campo de comentário livre neste protótipo.
enum SuggestionFeedbackType {
  matchesPerception,
  doesNotMatch,
  preferNotToAnswer,
  helpful,
  neutral,
  notHelpful,
  harmful,
  dismissed,
}

extension SuggestionFeedbackTypeLabel on SuggestionFeedbackType {
  String get label => switch (this) {
    SuggestionFeedbackType.matchesPerception => 'Isso combina comigo',
    SuggestionFeedbackType.doesNotMatch => 'Isso não combina comigo',
    SuggestionFeedbackType.preferNotToAnswer => 'Prefiro não responder',
    SuggestionFeedbackType.helpful => 'Foi útil',
    SuggestionFeedbackType.neutral => 'Foi neutro',
    SuggestionFeedbackType.notHelpful => 'Não ajudou',
    SuggestionFeedbackType.harmful => 'Foi prejudicial',
    SuggestionFeedbackType.dismissed => 'Agora não',
  };
}

class SuggestionFeedback {
  const SuggestionFeedback({
    required this.id,
    required this.suggestionId,
    required this.templateId,
    required this.type,
    required this.createdAt,
    this.exerciseId,
  });

  final String id;
  final String suggestionId;
  final String templateId;
  final String? exerciseId;
  final SuggestionFeedbackType type;
  final DateTime createdAt;

  bool get isDismissal => type == SuggestionFeedbackType.dismissed;

  bool get triggersCooldown {
    return isDismissal ||
        type == SuggestionFeedbackType.notHelpful ||
        type == SuggestionFeedbackType.harmful;
  }
}
