import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';

/// Acesso estático exibido depois de salvar um check-in ou diário.
///
/// Ele não usa o conteúdo nem a pontuação do registro: as mesmas opções são
/// oferecidas para todas as pessoas, sem inferir risco ou abrir a checagem de
/// segurança automaticamente.
class AfterJournalSupportSheet extends StatelessWidget {
  const AfterJournalSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AfterJournalSupportSheet(),
    );
  }

  void _openFlow(BuildContext context, SupportFlowScreen flow) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => flow));
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
              child: Text('Quer apoio agora?', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Text(
              'Estas opções aparecem para qualquer registro. A Íris não '
              'interpreta o texto nem monitora você em tempo real.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('after-journal-exercises'),
              onPressed: () => _openFlow(
                context,
                const SupportFlowScreen(start: SupportFlowStart.catalog),
              ),
              icon: const Icon(Icons.self_improvement_rounded),
              label: const Text('Iniciar um exercício'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('after-journal-not-ok'),
              onPressed: () => _openFlow(context, const SupportFlowScreen()),
              icon: const Icon(Icons.favorite_outline_rounded),
              label: const Text('Não estou bem'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('after-journal-urgent-help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: () => _openFlow(
                context,
                const SupportFlowScreen(start: SupportFlowStart.safetyCheck),
              ),
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: const Text('Ajuda urgente'),
            ),
            const SizedBox(height: 12),
            Text(
              'Demonstração — nenhuma mensagem será enviada.',
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('after-journal-not-now'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Agora não'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
