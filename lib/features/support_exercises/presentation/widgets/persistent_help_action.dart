import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

/// Ação “Ajuda urgente” disponível em um toque no cabeçalho de todas as
/// telas do fluxo. Tocar nela abre a checagem de segurança — nunca uma
/// pergunta automática sobre suicídio.
///
/// Usa `colorScheme.error` para manter contraste AA também no tema escuro.
class PersistentHelpAction extends StatelessWidget {
  const PersistentHelpAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return TextButton.icon(
      key: const Key('support-urgent-help'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: error,
        backgroundColor: error.withValues(alpha: .08),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      icon: const Icon(Icons.emergency_share_rounded, size: 20),
      label: const Text('Ajuda urgente'),
    );
  }
}