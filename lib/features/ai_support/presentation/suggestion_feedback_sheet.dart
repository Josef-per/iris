import 'package:flutter/material.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

/// Feedback sem campo livre, usado apenas para ajustar a demonstração local.
class SuggestionFeedbackSheet extends StatelessWidget {
  const SuggestionFeedbackSheet({
    super.key,
    required this.store,
    required this.suggestion,
  });

  final MockAiSupportStore store;
  final SupportSuggestion suggestion;

  static Future<void> show(
    BuildContext context, {
    required MockAiSupportStore store,
    required SupportSuggestion suggestion,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          SuggestionFeedbackSheet(store: store, suggestion: suggestion),
    );
  }

  void _select(BuildContext context, SuggestionFeedbackType type) {
    final messenger = ScaffoldMessenger.of(context);
    store.recordFeedback(type, suggestion: suggestion);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(_messageFor(type))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Como foi esta sugestão?',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            store.isDemonstration
                ? 'Seu feedback fica nesta demonstração e ajuda a reduzir repetições.'
                : 'Sua resposta ajuda a evitar repetições e ajustar os próximos apoios.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final choice in _FeedbackChoice.values) ...[
            OutlinedButton(
              key: Key('ai-support-feedback-${choice.name}'),
              onPressed: () => _select(context, choice.type),
              child: Text(choice.label),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
        ],
      ),
    );
  }

  String _messageFor(SuggestionFeedbackType type) => switch (type) {
    SuggestionFeedbackType.helpful => 'Entendido. Vou considerar isso.',
    SuggestionFeedbackType.neutral => 'Entendido. Vou considerar isso.',
    SuggestionFeedbackType.notHelpful || SuggestionFeedbackType.harmful =>
      'Esta sugestão será evitada por enquanto.',
    _ => 'Resposta registrada.',
  };
}

enum _FeedbackChoice {
  helpful('Foi útil', SuggestionFeedbackType.helpful),
  neutral('Foi neutra', SuggestionFeedbackType.neutral),
  notHelpful('Não ajudou', SuggestionFeedbackType.notHelpful),
  harmful('Prefiro não receber algo assim', SuggestionFeedbackType.harmful);

  const _FeedbackChoice(this.label, this.type);

  final String label;
  final SuggestionFeedbackType type;
}
