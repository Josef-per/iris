import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/presentation/suggestion_feedback_sheet.dart';
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
            'Entendido. Vou evitar sugestões como esta; seu diário não mudou.',
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          store.isDemonstration
              ? 'Resposta registrada somente nesta sessão.'
              : 'Entendido. Vou considerar isso nas próximas sugestões.',
        ),
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
    store.recordActionStarted(suggestion);
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
            Text('Para o seu momento', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_observation(), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            if (template == null)
              _UnavailableSuggestion(theme: theme)
            else
              _SuggestionContent(
                template: template,
                category: suggestion.category,
                onPrimaryAction: () => _openPrimaryAction(context, template),
              ),
            const SizedBox(height: 22),
            Text(
              'Isso combina com o que você sente?',
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
              ],
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              key: const Key('ai-support-detail-feedback'),
              onPressed: () => SuggestionFeedbackSheet.show(
                context,
                store: store,
                suggestion: suggestion,
              ),
              icon: const Icon(Icons.thumb_up_outlined),
              label: const Text('Contar se ajudou'),
            ),
            TextButton.icon(
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
            const Divider(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('ai-support-detail-urgent-help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: () => _openUrgentHelp(context),
              icon: const Icon(Icons.emergency_share_rounded),
              label: const Text('Preciso de ajuda urgente'),
            ),
          ],
        ),
      ),
    );
  }

  String _observation() {
    final observations = <String>[];
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.todayDifficultCheckIn,
    )) {
      observations.add('Seu check-in de hoje pareceu mais difícil.');
    } else if (suggestion.reasonCodes.contains(
      SupportReasonCode.todayLighterCheckIn,
    )) {
      observations.add('Seu check-in de hoje pareceu um pouco mais leve.');
    } else if (suggestion.reasonCodes.contains(
      SupportReasonCode.todaySteadyCheckIn,
    )) {
      observations.add('Seu check-in de hoje ficou no meio da escala.');
    } else if (suggestion.reasonCodes.contains(
      SupportReasonCode.recentDifficultCheckIns,
    )) {
      observations.add('Seus check-ins recentes pareceram mais difíceis.');
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.confirmedLoneliness,
    )) {
      observations.add(
        'No diário, você marcou um tema ligado a vontade de companhia.',
      );
    }
    if (suggestion.reasonCodes.contains(SupportReasonCode.confirmedOverload)) {
      observations.add('No diário, você marcou um tema ligado a sobrecarga.');
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.confirmedSelfKindness,
    )) {
      observations.add(
        'No diário, você marcou vontade de ser mais gentil com você.',
      );
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.previousExerciseWasNotHelpful,
    )) {
      observations.add('Você marcou uma prática anterior como não útil.');
    }
    if (suggestion.reasonCodes.contains(
      SupportReasonCode.preferredFromPastInteractions,
    )) {
      observations.add('Você já abriu apoios desse tipo antes.');
    }
    if (observations.isEmpty) {
      return 'Uma sugestão de apoio está disponível, se fizer sentido.';
    }
    return observations.take(2).join(' ');
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
