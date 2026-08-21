import 'package:flutter/material.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

/// Checagem de segurança. Aparece somente quando a própria pessoa toca em
/// “Ajuda urgente”. “Sim” e “Talvez” seguem a mesma rota determinística;
/// “Não” volta às opções de apoio sem bloquear exercícios.
class SafetyCheckView extends StatelessWidget {
  const SafetyCheckView({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Checagem de segurança',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Você corre risco de se machucar, não consegue se manter em '
          'segurança ou está com um sintoma físico grave agora?',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        OptionCard(
          key: const Key('safety-yes'),
          label: 'Sim',
          selected: false,
          onTap: onYes,
          icon: Icons.emergency_rounded,
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('safety-maybe'),
          label: 'Talvez / não tenho certeza',
          selected: false,
          onTap: onYes,
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('safety-no'),
          label: 'Não',
          selected: false,
          onTap: onNo,
          icon: Icons.arrow_back_rounded,
        ),
        const SizedBox(height: 20),
        Text(
          'Nenhuma resposta é salva. Esta pergunta não decide nada por '
          'você — só ajuda a encontrar o próximo passo.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}