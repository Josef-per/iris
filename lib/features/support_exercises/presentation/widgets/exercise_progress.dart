import 'package:flutter/material.dart';

/// Progresso do player: “Etapa X de Y” legível por leitor de tela e barra
/// discreta, sem cronômetro, pontuação ou pressão.
class ExerciseProgress extends StatelessWidget {
  const ExerciseProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Etapa $current de $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              'Etapa $current de $total',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}