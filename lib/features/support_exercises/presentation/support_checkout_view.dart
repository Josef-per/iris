import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/domain/support_session.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

/// Check-out sem promessa terapêutica: “Como este momento está agora?”.
///
/// “Pior” prioriza ajuda humana sem presumir intenção suicida. Nenhuma
/// resposta é julgada ou bloqueada.
class SupportCheckoutView extends StatefulWidget {
  const SupportCheckoutView({
    super.key,
    required this.onTalkToSomeone,
    required this.onUrgentHelp,
    required this.onChooseAnother,
    required this.onWatchVideo,
    required this.onFinish,
    this.initialLabel,
    this.onAnswer,
  });

  final VoidCallback onTalkToSomeone;
  final VoidCallback onUrgentHelp;
  final VoidCallback onChooseAnother;
  final VoidCallback onWatchVideo;

  /// Encerra com o rótulo da resposta escolhida (ex.: “Um pouco melhor”).
  final ValueChanged<String> onFinish;

  /// Restaura uma resposta já dada quando a tela é recriada (ex.: após voltar
  /// da rede de apoio).
  final String? initialLabel;

  /// Notifica cada nova resposta (rótulo), para o fluxo manter o estado.
  final ValueChanged<String>? onAnswer;

  @override
  State<SupportCheckoutView> createState() => _SupportCheckoutViewState();
}

enum _CheckoutAnswer { worse, same, aLittleBetter, better }

extension on _CheckoutAnswer {
  String get label => switch (this) {
    _CheckoutAnswer.worse => 'Pior',
    _CheckoutAnswer.same => 'Igual',
    _CheckoutAnswer.aLittleBetter => 'Um pouco melhor',
    _CheckoutAnswer.better => 'Melhor',
  };
}

_CheckoutAnswer? _answerFromLabel(String? label) => switch (label) {
  'Pior' => _CheckoutAnswer.worse,
  'Igual' => _CheckoutAnswer.same,
  'Um pouco melhor' => _CheckoutAnswer.aLittleBetter,
  'Melhor' => _CheckoutAnswer.better,
  _ => null,
};

class _SupportCheckoutViewState extends State<SupportCheckoutView> {
  _CheckoutAnswer? _answer;

  _CheckoutAnswer? get _effectiveAnswer =>
      _answer ?? _answerFromLabel(widget.initialLabel);

  void _select(_CheckoutAnswer option) {
    setState(() => _answer = option);
    widget.onAnswer?.call(option.label);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = _effectiveAnswer;
    if (answer != null) {
      return _resultPanel(answer);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Como este momento está agora?',
          key: const Key('checkout-question'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Não há resposta certa. Você pode escolher como seguir.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final option in _CheckoutAnswer.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OptionCard(
              key: Key('checkout-${option.name}'),
              label: option.label,
              selected: false,
              onTap: () => _select(option),
            ),
          ),
      ],
    );
  }

  Widget _resultPanel(_CheckoutAnswer answer) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Obrigado por me contar.', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(answer.message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        ...switch (answer) {
          _CheckoutAnswer.worse => <Widget>[
            FilledButton.icon(
              key: const Key('checkout-talk'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: widget.onTalkToSomeone,
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Falar com alguém seguro'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('checkout-urgent'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
              ),
              onPressed: widget.onUrgentHelp,
              icon: const Icon(Icons.emergency_share_rounded),
              label: const Text('Ajuda urgente'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('checkout-finish'),
              onPressed: () => widget.onFinish(answer.label),
              child: const Text('Encerrar'),
            ),
          ],
          _CheckoutAnswer.same => <Widget>[
            OutlinedButton.icon(
              key: const Key('checkout-another'),
              onPressed: widget.onChooseAnother,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Escolher outra ferramenta'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('checkout-video'),
              onPressed: widget.onWatchVideo,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Ver um vídeo'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('checkout-finish'),
              onPressed: () => widget.onFinish(answer.label),
              child: const Text('Encerrar'),
            ),
          ],
          _CheckoutAnswer.aLittleBetter || _CheckoutAnswer.better => <Widget>[
            FilledButton(
              key: const Key('checkout-finish'),
              onPressed: () => widget.onFinish(answer.label),
              child: const Text('Concluir'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('checkout-another'),
              onPressed: widget.onChooseAnother,
              child: const Text('Escolher outra ferramenta'),
            ),
          ],
        },
      ],
    );
  }
}

extension on _CheckoutAnswer {
  String get message => switch (this) {
    _CheckoutAnswer.worse =>
      'Você não precisa continuar agora. Falar com alguém pode ajudar — '
      'e a ajuda urgente continua aqui, se você quiser.',
    _CheckoutAnswer.same =>
      'Tudo bem. Você pode escolher o próximo passo, sem pressa.',
    _CheckoutAnswer.aLittleBetter || _CheckoutAnswer.better =>
      'Que bom que você dedicou esse tempo a você. Pode concluir quando '
      'quiser.',
  };
}

/// Resumo fictício opcional, deixando explícito que nada foi salvo ou enviado.
class SupportSummaryView extends StatelessWidget {
  const SupportSummaryView({
    super.key,
    required this.session,
    required this.checkoutLabel,
    required this.onExit,
  });

  final SupportSession session;
  final String checkoutLabel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sessão concluída', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Você praticou “${session.exerciseTitle}” por cerca de '
            '${session.durationMinutes} min. Marcou que está '
            '“$checkoutLabel”. Nada foi enviado ao seu profissional.',
            key: const Key('summary-text'),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nada será salvo ou enviado. Esta sessão termina aqui.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('summary-finish'),
          onPressed: onExit,
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}