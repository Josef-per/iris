import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Central interna de sugestões já produzidas pelo simulador.
class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({
    super.key,
    required this.store,
    this.onBack,
    required this.onOpenSuggestion,
  });

  final MockAiSupportStore store;
  final VoidCallback? onBack;
  final ValueChanged<SupportSuggestion> onOpenSuggestion;

  void _back(BuildContext context) {
    if (onBack case final callback?) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final suggestions = store.suggestionInbox;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => _back(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Central de sugestões'),
          ),
          body: AppResponsive(
            maxWidth: 720,
            child: ListView(
              children: [
                Text(
                  'Somente nesta demonstração',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estas sugestões ficam no app. Nenhum contato ou '
                  'profissional foi avisado.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (suggestions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Text(
                      'Ainda não há uma sugestão local. Você pode usar '
                      'exercícios e “Não estou bem” sem personalização.',
                    ),
                  )
                else
                  for (final suggestion in suggestions.reversed) ...[
                    _InboxSuggestionCard(
                      suggestion: suggestion,
                      onTap: () => onOpenSuggestion(suggestion),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InboxSuggestionCard extends StatelessWidget {
  const _InboxSuggestionCard({required this.suggestion, required this.onTap});

  final SupportSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final template = MockSupportTemplateCatalog.catalog.templateById(
      suggestion.templateId,
    );
    if (template == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${template.inAppTitle}. ${suggestion.category.label}',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(suggestion.category),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.inAppTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.inAppBody,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
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
}
