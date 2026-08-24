import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/presentation/suggestion_feedback_sheet.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/features/ai_support/presentation/why_this_suggestion_sheet.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Detalhe autenticado de uma sugestão aprovada pelo catálogo local.
class SupportSuggestionScreen extends StatelessWidget {
  const SupportSuggestionScreen({
    super.key,
    required this.store,
    required this.suggestion,
    this.onManageData,
  });

  final MockAiSupportStore store;
  final SupportSuggestion suggestion;
  final VoidCallback? onManageData;

  void _answer(BuildContext context, SuggestionFeedbackType type) {
    final messenger = ScaffoldMessenger.of(context);
    store.recordFeedback(type, suggestion: suggestion);
    if (type == SuggestionFeedbackType.doesNotMatch) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Entendido. Essa informação não será mais usada; seu diário não mudou.',
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Resposta registrada somente nesta sessão.'),
      ),
    );
  }

  void _openUrgentHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const SupportFlowScreen(start: SupportFlowStart.safetyCheck),
      ),
    );
  }

  void _openPrimaryAction(
    BuildContext context,
    SupportSuggestionTemplate template,
  ) {
    switch (suggestion.category) {
      case SupportSuggestionCategory.exercise:
        final exerciseId = suggestion.exerciseId;
        if (exerciseId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SupportFlowScreen(initialExerciseId: exerciseId),
          ),
        );
      case SupportSuggestionCategory.humanConnection:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const SupportFlowScreen(start: SupportFlowStart.supportNetwork),
          ),
        );
      case SupportSuggestionCategory.professionalConversation:
        _showProfessionalCard(context);
      case SupportSuggestionCategory.video:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const SupportFlowScreen(start: SupportFlowStart.catalog),
          ),
        );
      case SupportSuggestionCategory.reflection:
        _showReflection(context, template);
    }
  }

  void _hideCategory(BuildContext context) {
    final categories = <SupportSuggestionCategory>{
      ...store.preferences.allowedCategories,
    }..remove(suggestion.category);
    store.configurePreferences(
      store.preferences.copyWith(allowedCategories: categories),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sugestões de ${suggestion.category.label.toLowerCase()} foram desativadas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = MockSupportTemplateCatalog.catalog.templateById(
      suggestion.templateId,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Sugestão de apoio')),
      body: AppResponsive(
        maxWidth: 720,
        child: ListView(
          children: [
            OutlinedButton.icon(
              key: const Key('ai-support-detail-urgent-help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: () => _openUrgentHelp(context),
              icon: const Icon(Icons.emergency_share_rounded),
              label: const Text('Ajuda urgente'),
            ),
            const SizedBox(height: 20),
            Text(
              'Uma observação tentativa',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(_observation(), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text(
              'Isso combina com sua percepção?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  key: const Key('ai-support-detail-matches'),
                  onPressed: () => _answer(
                    context,
                    SuggestionFeedbackType.matchesPerception,
                  ),
                  child: const Text('Sim'),
                ),
                OutlinedButton(
                  key: const Key('ai-support-detail-does-not-match'),
                  onPressed: () =>
                      _answer(context, SuggestionFeedbackType.doesNotMatch),
                  child: const Text('Não'),
                ),
                TextButton(
                  key: const Key('ai-support-detail-prefer-not-answer'),
                  onPressed: () => _answer(
                    context,
                    SuggestionFeedbackType.preferNotToAnswer,
                  ),
                  child: const Text('Prefiro não responder'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (template == null)
              _UnavailableSuggestion(theme: theme)
            else
              _SuggestionContent(
                template: template,
                category: suggestion.category,
                onPrimaryAction: () => _openPrimaryAction(context, template),
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('ai-support-detail-why'),
              onPressed: () => WhyThisSuggestionSheet.show(
                context,
                store: store,
                suggestion: suggestion,
                onManageData: onManageData,
              ),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Por que estou vendo isto?'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('ai-support-detail-feedback'),
              onPressed: () => SuggestionFeedbackSheet.show(
                context,
                store: store,
                suggestion: suggestion,
              ),
              icon: const Icon(Icons.thumb_up_outlined),
              label: const Text('Avaliar esta sugestão'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('ai-support-detail-hide-category'),
              onPressed: () => _hideCategory(context),
              child: Text(
                'Não mostrar sugestões de ${suggestion.category.label.toLowerCase()}',
              ),
            ),
            TextButton(
              key: const Key('ai-support-detail-not-now'),
              onPressed: () {
                store.recordFeedback(
                  SuggestionFeedbackType.dismissed,
                  suggestion: suggestion,
                );
                Navigator.of(context).maybePop();
              },
              child: const Text('Agora não'),
            ),
            const SizedBox(height: 12),
            Text(
              'Nada foi compartilhado com outra pessoa.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _observation() {
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.recentDifficultCheckIns,
    )) {
      return 'Seus check-ins recentes pareceram mais difíceis.';
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.confirmedLoneliness,
    )) {
      return 'Você confirmou uma tag que pode indicar vontade de companhia.';
    }
    if (suggestion.reasonCodes.contains(SupportReasonCode.confirmedOverload)) {
      return 'Você confirmou uma tag relacionada a sobrecarga.';
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.previousExerciseWasNotHelpful,
    )) {
      return 'Você marcou uma prática anterior como não útil.';
    }
    return 'Uma sugestão de apoio está disponível, se fizer sentido.';
  }

  Future<void> _showReflection(
    BuildContext context,
    SupportSuggestionTemplate template,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refletir no seu ritmo'),
        content: Text(
          '${template.inAppBody}\n\nVocê não precisa responder nem registrar nada agora.',
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

  Future<void> _showProfessionalCard(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Guardar para conversar'),
        content: const Text(
          'Este é apenas um cartão fictício. Nenhum profissional recebeu, '
          'leu ou responderá a uma mensagem.',
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

class _UnavailableSuggestion extends StatelessWidget {
  const _UnavailableSuggestion({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text(
        'Este conteúdo não está mais disponível. Você pode escolher um '
        'exercício ou outra forma de apoio.',
      ),
    );
  }
}

class _SuggestionContent extends StatelessWidget {
  const _SuggestionContent({
    required this.template,
    required this.category,
    required this.onPrimaryAction,
  });

  final SupportSuggestionTemplate template;
  final SupportSuggestionCategory category;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('ai-support-detail-content'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(template.inAppTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(template.inAppBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('ai-support-detail-primary-action'),
            onPressed: onPrimaryAction,
            icon: Icon(_iconFor(category)),
            label: Text(_actionLabelFor(category)),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(SupportSuggestionCategory category) => switch (category) {
    SupportSuggestionCategory.reflection => Icons.question_mark_rounded,
    SupportSuggestionCategory.exercise => Icons.self_improvement_rounded,
    SupportSuggestionCategory.video => Icons.play_circle_outline_rounded,
    SupportSuggestionCategory.humanConnection => Icons.people_outline_rounded,
    SupportSuggestionCategory.professionalConversation =>
      Icons.support_agent_rounded,
  };

  String _actionLabelFor(SupportSuggestionCategory category) =>
      switch (category) {
        SupportSuggestionCategory.reflection => 'Refletir agora',
        SupportSuggestionCategory.exercise => 'Fazer exercício',
        SupportSuggestionCategory.video => 'Abrir vídeos',
        SupportSuggestionCategory.humanConnection => 'Falar com alguém seguro',
        SupportSuggestionCategory.professionalConversation =>
          'Guardar para o profissional',
      };
}
