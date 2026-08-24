import 'package:flutter/material.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';

/// Explicação local, baseada somente nos reason codes e fontes consentidas.
class WhyThisSuggestionSheet extends StatelessWidget {
  const WhyThisSuggestionSheet({
    super.key,
    required this.store,
    required this.suggestion,
    this.onManageData,
  });

  final MockAiSupportStore store;
  final SupportSuggestion suggestion;
  final VoidCallback? onManageData;

  static Future<void> show(
    BuildContext context, {
    required MockAiSupportStore store,
    required SupportSuggestion suggestion,
    VoidCallback? onManageData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => WhyThisSuggestionSheet(
        store: store,
        suggestion: suggestion,
        onManageData: onManageData,
      ),
    );
  }

  void _doesNotMatch(BuildContext context) {
    store.recordFeedback(
      SuggestionFeedbackType.doesNotMatch,
      suggestion: suggestion,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Essa informação não será mais usada. Seu diário não foi alterado.',
        ),
      ),
    );
  }

  void _discardFirstSignal(BuildContext context) {
    final matchingSignals = store.activeSignals
        .where((item) => suggestion.usedSources.contains(item.source))
        .toList(growable: false);
    final signal = matchingSignals.isEmpty ? null : matchingSignals.first;
    if (signal == null) return;
    store.discardSignal(signal.id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Essa informação deixou de ser usada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDiscardSignal = store.activeSignals.any(
      (item) => suggestion.usedSources.contains(item.source),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Por que estou vendo isto?',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usamos somente as informações que você permitiu.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final source in suggestion.usedSources) ...[
              Text(source.label, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(source.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            Text('O que influenciou', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              _reasonSentence(suggestion),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('ai-support-does-not-match'),
              onPressed: () => _doesNotMatch(context),
              child: const Text('Isso não combina comigo'),
            ),
            if (canDiscardSignal) ...[
              const SizedBox(height: 8),
              TextButton(
                key: const Key('ai-support-discard-signal'),
                onPressed: () => _discardFirstSignal(context),
                child: const Text('Não usar este sinal'),
              ),
            ],
            TextButton(
              key: const Key('ai-support-manage-data'),
              onPressed: () {
                Navigator.of(context).pop();
                onManageData?.call();
              },
              child: const Text('Gerenciar dados usados'),
            ),
            TextButton(
              key: const Key('ai-support-pause-from-why'),
              onPressed: () {
                store.disablePersonalization();
                Navigator.of(context).pop();
              },
              child: const Text('Pausar ou desligar personalização'),
            ),
            TextButton(
              onPressed: () => _showReviewExplanation(context),
              child: const Text('Solicitar revisão/explicação'),
            ),
          ],
        ),
      ),
    );
  }

  String _reasonSentence(SupportSuggestion suggestion) {
    final reasons = suggestion.reasonCodes
        .map((reason) => reason.explanation)
        .toList(growable: false);
    if (reasons.isEmpty) {
      return 'Nenhum motivo foi registrado.';
    }
    if (reasons.length == 1) {
      return 'A sugestão apareceu porque ${reasons.first}.';
    }
    return 'A sugestão apareceu porque ${reasons.join(' e ')}.';
  }

  Future<void> _showReviewExplanation(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisão na demonstração'),
        content: const Text(
          'Nenhuma solicitação será enviada nesta primeira versão. Você pode '
          'usar os controles desta tela para corrigir, pausar ou desligar as '
          'sugestões agora.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
