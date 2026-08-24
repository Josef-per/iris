import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/notification_candidate.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Simulador visual local de uma notificação discreta.
///
/// A tela recebe somente candidato/IDs de template e consulta o texto genérico
/// aprovado. Nunca exibe sinal de humor, tag ou conteúdo do diário.
class NotificationPreviewScreen extends StatelessWidget {
  const NotificationPreviewScreen({
    super.key,
    required this.store,
    this.onBack,
    this.onOpenSuggestion,
  });

  final MockAiSupportStore store;
  final VoidCallback? onBack;
  final ValueChanged<SupportSuggestion>? onOpenSuggestion;

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
        final candidates = store.notificationCandidates;
        final preview = store.preferences.notifications.lockScreenPreview;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => _back(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Notificações simuladas'),
          ),
          body: AppResponsive(
            maxWidth: 680,
            child: ListView(
              children: [
                Text('Simulador interno', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Demonstração — não é uma notificação do sistema, não pede '
                  'permissão e não envia nada.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (preview == LockScreenPreview.none)
                  _NoLockScreenPreview(theme: theme)
                else if (candidates.isEmpty)
                  _EmptyGenericPreview(theme: theme)
                else
                  for (final candidate in candidates.reversed) ...[
                    _NotificationCard(
                      candidate: candidate,
                      onOpen: () {
                        final suggestion = _suggestionFor(candidate);
                        if (suggestion != null) onOpenSuggestion?.call(suggestion);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                if (candidates.isEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Quando uma sugestão local respeitar suas escolhas de '
                    'fonte, horário e frequência, ela poderá aparecer aqui.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  SupportSuggestion? _suggestionFor(NotificationCandidate candidate) {
    for (final suggestion in store.suggestionInbox) {
      if (suggestion.id == candidate.suggestionId) return suggestion;
    }
    return null;
  }
}

class _EmptyGenericPreview extends StatelessWidget {
  const _EmptyGenericPreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Exemplo de prévia bloqueada',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        _PreviewSurface(
          text: MockSupportTemplateCatalog.genericNotifications.first.text,
          onOpen: null,
        ),
        const SizedBox(height: 8),
        Text(
          'Este exemplo é sempre genérico; não inclui humor, tag, diário, '
          'exercício ou contato.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NoLockScreenPreview extends StatelessWidget {
  const _NoLockScreenPreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prévia bloqueada desativada', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Nenhum conteúdo aparece na tela bloqueada. O detalhe só fica '
            'disponível depois de abrir a Íris autenticada.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.candidate, required this.onOpen});

  final NotificationCandidate candidate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = MockSupportTemplateCatalog.catalog
        .genericNotificationById(candidate.genericNotificationTemplateId)
        ?.text;
    if (text == null) return const SizedBox.shrink();
    return _PreviewSurface(text: text, onOpen: onOpen);
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.text, required this.onOpen});

  final String text;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      key: const Key('ai-support-notification-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Íris', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
    if (onOpen == null) return child;
    return Semantics(
      button: true,
      label: 'Abrir sugestão de apoio simulada',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: child,
        ),
      ),
    );
  }
}
