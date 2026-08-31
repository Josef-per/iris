import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';

/// Apoio opcional exibido depois de salvar um check-in ou diário.
///
/// Os acessos de segurança são sempre estáticos. Quando autorizado, uma
/// sugestão estruturada pode aparecer sem analisar o texto livre do diário.
class AfterJournalSupportSheet extends StatelessWidget {
  const AfterJournalSupportSheet({
    super.key,
    this.personalizedSuggestion,
    this.onOpenPersonalized,
    this.onNotNow,
  });

  final Future<SupportSuggestion?>? personalizedSuggestion;
  final ValueChanged<SupportSuggestion>? onOpenPersonalized;
  final VoidCallback? onNotNow;

  static Future<void> show(
    BuildContext context, {
    Future<SupportSuggestion?>? personalizedSuggestion,
    ValueChanged<SupportSuggestion>? onOpenPersonalized,
    VoidCallback? onNotNow,
    VoidCallback? onClosedWithoutPersonalized,
  }) async {
    var openedPersonalized = false;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AfterJournalSupportSheet(
        personalizedSuggestion: personalizedSuggestion,
        onOpenPersonalized: (suggestion) {
          openedPersonalized = true;
          onOpenPersonalized?.call(suggestion);
        },
        onNotNow: onNotNow,
      ),
    );
    if (!openedPersonalized) onClosedWithoutPersonalized?.call();
  }

  void _openFlow(BuildContext context, SupportFlowScreen flow) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => flow));
  }

  void _openPersonalized(BuildContext context, SupportSuggestion suggestion) {
    Navigator.of(context).pop();
    onOpenPersonalized?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Registro salvo', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Text(
              'Quer cuidar um pouco de você agora?',
              style: theme.textTheme.bodyMedium,
            ),
            if (personalizedSuggestion case final future?) ...[
              const SizedBox(height: 18),
              FutureBuilder<SupportSuggestion?>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _PreparingPersonalizedSupport();
                  }
                  final suggestion = snapshot.data;
                  final template = suggestion == null
                      ? null
                      : MockSupportTemplateCatalog.catalog.templateById(
                          suggestion.templateId,
                        );
                  if (template == null) {
                    return _PracticeButton(
                      onPressed: () => _openFlow(
                        context,
                        const SupportFlowScreen(
                          start: SupportFlowStart.catalog,
                        ),
                      ),
                    );
                  }
                  return _PersonalizedSupportCard(
                    title: template.inAppTitle,
                    onOpen: () => _openPersonalized(context, suggestion!),
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 18),
              _PracticeButton(
                onPressed: () => _openFlow(
                  context,
                  const SupportFlowScreen(start: SupportFlowStart.catalog),
                ),
              ),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  key: const Key('after-journal-not-ok'),
                  onPressed: () =>
                      _openFlow(context, const SupportFlowScreen()),
                  child: const Text('Não estou bem'),
                ),
                TextButton(
                  key: const Key('after-journal-urgent-help'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () => _openFlow(
                    context,
                    const SupportFlowScreen(
                      start: SupportFlowStart.safetyCheck,
                    ),
                  ),
                  child: const Text('Ajuda urgente'),
                ),
              ],
            ),
            Text(
              'A Íris não monitora seu diário nem avisa ninguém automaticamente.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('after-journal-not-now'),
                onPressed: () {
                  onNotNow?.call();
                  Navigator.of(context).pop();
                },
                child: const Text('Agora não'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeButton extends StatelessWidget {
  const _PracticeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const Key('after-journal-exercises'),
      onPressed: onPressed,
      icon: const Icon(Icons.self_improvement_rounded),
      label: const Text('Escolher uma prática'),
    );
  }
}

class _PreparingPersonalizedSupport extends StatelessWidget {
  const _PreparingPersonalizedSupport();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: Key('after-journal-preparing-personalized'),
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Expanded(child: Text('Preparando uma sugestão para você…')),
      ],
    );
  }
}

class _PersonalizedSupportCard extends StatelessWidget {
  const _PersonalizedSupportCard({required this.title, required this.onOpen});

  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('after-journal-personalized'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('after-journal-open-personalized'),
            onPressed: onOpen,
            child: const Text('Ver sugestão para mim'),
          ),
        ],
      ),
    );
  }
}
