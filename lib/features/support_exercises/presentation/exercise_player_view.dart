import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/exercise_step.dart';
import 'package:iris/features/support_exercises/domain/support_session.dart';
import 'package:iris/features/support_exercises/presentation/widgets/exercise_progress.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

/// Player genérico por schema: uma instrução por tela, uma decisão principal,
/// “Pular esta etapa” sempre disponível e feedback neutro.
///
/// Toda interação é voluntária; sair não exige confirmação culpabilizante.
class ExercisePlayerView extends StatefulWidget {
  const ExercisePlayerView({
    super.key,
    required this.exercise,
    required this.session,
    required this.onComplete,
  });

  final Exercise exercise;
  final SupportSession session;
  final VoidCallback onComplete;

  @override
  State<ExercisePlayerView> createState() => _ExercisePlayerViewState();
}

class _ExercisePlayerViewState extends State<ExercisePlayerView> {
  final Map<int, TextEditingController> _textControllers =
      <int, TextEditingController>{};

  Exercise get _exercise => widget.exercise;
  SupportSession get _session => widget.session;

  ExerciseStep get _step => _exercise.steps[_session.currentStepIndex];

  int get _stepIndex => _session.currentStepIndex;

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int index) {
    return _textControllers.putIfAbsent(
      index,
      () => TextEditingController(
        text: _session.answers[index]?.first ?? '',
      ),
    );
  }

  void _answer(List<String> values) {
    setState(() {
      _session.answers[_stepIndex] = values;
    });
  }

  void _goTo(int index) {
    setState(() {
      _session.currentStepIndex = index;
    });
  }

  void _skipStep() {
    if (_stepIndex + 1 >= _exercise.steps.length) {
      widget.onComplete();
      return;
    }
    _goTo(_stepIndex + 1);
  }

  void _continue() {
    if (_stepIndex + 1 >= _exercise.steps.length) {
      widget.onComplete();
      return;
    }
    _goTo(_stepIndex + 1);
  }

  bool get _hasAnswer {
    final values = _session.answers[_stepIndex];
    if (values == null) return false;
    return switch (_step.type) {
      ExerciseStepType.textReflection =>
        values.any((value) => value.trim().isNotEmpty),
      _ => values.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseProgress(
          key: const Key('exercise-progress'),
          current: _stepIndex + 1,
          total: _exercise.steps.length,
        ),
        const SizedBox(height: 20),
        Text(
          _step.prompt,
          key: const Key('exercise-prompt'),
          style: theme.textTheme.titleLarge,
        ),
        if (_step.semanticsHint case final hint?) ...[
          const SizedBox(height: 6),
          Text(hint, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 20),
        ..._stepContent,
        if (_hasAnswer && _step.type != ExerciseStepType.closing) ...[
          const SizedBox(height: 14),
          Text(
            _step.feedback ?? 'Etapa concluída.',
            key: const Key('exercise-feedback'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('exercise-continue'),
          onPressed: _step.type == ExerciseStepType.closing
              ? _continue
              : _hasAnswer
              ? _continue
              : null,
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('exercise-skip'),
          onPressed: _step.allowSkip ? _skipStep : null,
          child: const Text('Pular esta etapa'),
        ),
        if (_stepIndex > 0) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('exercise-back'),
            onPressed: () => _goTo(_stepIndex - 1),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar'),
          ),
        ],
      ],
    );
  }

  List<Widget> get _stepContent => switch (_step.type) {
    ExerciseStepType.singleChoice => [
      for (final option in _step.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            key: Key('exercise-option-$option'),
            label: option,
            selected: _session.answers[_stepIndex]?.first == option,
            onTap: () => _answer([option]),
          ),
        ),
    ],
    ExerciseStepType.multiChoice => [
      for (final option in _step.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            key: Key('exercise-option-$option'),
            label: option,
            selected: _session.answers[_stepIndex]?.contains(option) ?? false,
            onTap: () {
              final selected =
                  List<String>.of(
                    _session.answers[_stepIndex] ?? const <String>[],
                  );
              if (selected.contains(option)) {
                selected.remove(option);
              } else {
                selected.add(option);
              }
              _answer(selected);
            },
          ),
        ),
    ],
    ExerciseStepType.textReflection => [
      TextField(
        key: const Key('exercise-text'),
        controller: _controllerFor(_stepIndex),
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (value) => _answer([value]),
        decoration: const InputDecoration(
          hintText: 'Escreva no seu ritmo…',
        ),
      ),
    ],
    ExerciseStepType.closing => [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          _step.feedback ?? 'Etapa concluída.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ],
  };
}