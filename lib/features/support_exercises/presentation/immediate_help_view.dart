import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/presentation/support_phone_launcher.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

/// Tela de ajuda imediata com contatos reais acionáveis (SAMU 192, CVV 188),
/// contatos simulados claramente marcados e “Voltar” sempre disponível.
///
/// O protótipo nunca afirma ter notificado ou acionado alguém.
class ImmediateHelpView extends StatefulWidget {
  const ImmediateHelpView({
    super.key,
    required this.onBack,
    this.phoneLauncher = defaultPhoneLauncher,
  });

  final VoidCallback onBack;
  final PhoneLauncher phoneLauncher;

  @override
  State<ImmediateHelpView> createState() => _ImmediateHelpViewState();
}

class _ImmediateHelpViewState extends State<ImmediateHelpView> {
  Future<void> _openPhone(String number) async {
    final opened = await widget.phoneLauncher(number);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir a discagem aqui. Ligue você mesmo '
              'para $number.',
            ),
          ),
        );
    }
  }

  Future<void> _showSimulatedContact(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ligar para o SAMU — 192',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Risco ou emergência. Serviço gratuito 24 horas.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('help-samu-192'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
          ),
          onPressed: () => _openPhone('192'),
          icon: const Icon(Icons.phone_rounded),
          label: const Text('Ligar para 192'),
        ),
        const SizedBox(height: 24),
        Text(
          'Ligar para o CVV — 188',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Apoio emocional 24 horas. Gratuito e confidencial.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('help-cvv-188'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () => _openPhone('188'),
          icon: const Icon(Icons.headset_mic_rounded),
          label: const Text('Ligar para 188'),
        ),
        const SizedBox(height: 24),
        OptionCard(
          key: const Key('help-trusted-person'),
          label: 'Chamar uma pessoa de confiança',
          subtitle: 'Simulado — nenhuma mensagem será enviada',
          selected: false,
          highlight: false,
          icon: Icons.favorite_rounded,
          onTap: () => _showSimulatedContact(
            'Chamar uma pessoa de confiança',
            'Este é um protótipo: nenhuma mensagem será enviada e nenhum '
            'contato será feito. No app final, você escolheria uma pessoa '
            'segura e os passos para chegar até ela.',
          ),
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('help-professional'),
          label: 'Falar com meu profissional',
          subtitle: 'Simulado e claramente marcado',
          selected: false,
          icon: Icons.support_agent_rounded,
          onTap: () => _showSimulatedContact(
            'Falar com meu profissional',
            'Este é um protótipo: nenhuma mensagem será enviada ao seu '
            'profissional. No app final, este contato seguiria o canal '
            'combinado com a sua equipe.',
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Se puder, fique com alguém e afaste-se de meios que possam '
            'ferir você enquanto busca ajuda.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Demonstração — nenhuma mensagem será enviada.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Contatos verificados em agosto de 2026.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('help-back'),
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar'),
        ),
      ],
    );
  }
}