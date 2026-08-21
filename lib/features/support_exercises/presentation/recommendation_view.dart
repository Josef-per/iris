import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_catalog.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_recommender.dart';
import 'package:iris/features/support_exercises/data/mock_video_catalog.dart';
import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';

/// Catálogo e “Sugestão para você”.
///
/// Sem [context], mostra o catálogo completo (entrada “Exercícios” da Home).
/// Com contexto, mostra a sugestão determinística e explica quais sinais a
/// geraram; “Escolher outra” abre o catálogo ou a biblioteca de vídeos.
class RecommendationView extends StatelessWidget {
  const RecommendationView({
    super.key,
    required this.context,
    required this.recommender,
    required this.onStartExercise,
    required this.onStartVideo,
    required this.onOpenVideoLibrary,
  });

  final RecommendationContext? context;
  final ExerciseRecommender recommender;
  final ValueChanged<Exercise> onStartExercise;
  final ValueChanged<SupportVideo> onStartVideo;
  final VoidCallback onOpenVideoLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendationContext = this.context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recommendationContext == null)
          Text('Catálogo de exercícios', style: theme.textTheme.titleLarge)
        else
          Text('Sugestão para você', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          recommendationContext == null
              ? 'Práticas curtas para diferentes momentos. Escolha uma '
                    'para começar.'
              : 'Baseada no que você indicou. Esta sugestão usa regras '
                    'locais — não é IA.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (recommendationContext != null)
          _Suggestion(
            recommendationContext: recommendationContext,
            recommender: recommender,
            onStartExercise: onStartExercise,
            onStartVideo: onStartVideo,
            onOpenVideoLibrary: onOpenVideoLibrary,
          ),
        const SizedBox(height: 24),
        Text('Todas as opções', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final exercise in MockExerciseCatalog.exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExerciseCard(
              key: Key('exercise-card-${exercise.id}'),
              exercise: exercise,
              onTap: () => onStartExercise(exercise),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Conteúdo fictício de demonstração: autoria, revisão clínica e '
          'datas são fictícias. Nada será salvo ou enviado.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.recommendationContext,
    required this.recommender,
    required this.onStartExercise,
    required this.onStartVideo,
    required this.onOpenVideoLibrary,
  });

  final RecommendationContext recommendationContext;
  final ExerciseRecommender recommender;
  final ValueChanged<Exercise> onStartExercise;
  final ValueChanged<SupportVideo> onStartVideo;
  final VoidCallback onOpenVideoLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendation = _safeRecommend();

    return Container(
      key: const Key('recommendation-suggestion'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recommendation case final recommendation?) ...[
            Text(
              recommendation.contentTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              recommendation.explanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('recommendation-start'),
              onPressed: recommendation.onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                recommendationContext.format == SupportFormat.video
                    ? 'Começar vídeo'
                    : 'Começar exercício',
              ),
            ),
          ] else
            Text(
              'Não foi possível gerar uma sugestão agora. Você pode '
              'escolher uma opção abaixo.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('recommendation-choose-another'),
            onPressed: recommendationContext.format == SupportFormat.video
                ? onOpenVideoLibrary
                : () => _showAllOptions(context),
            child: Text(
              recommendationContext.format == SupportFormat.video
                  ? 'Escolher outro vídeo'
                  : 'Escolher outra',
            ),
          ),
        ],
      ),
    );
  }

  _SuggestionContent? _safeRecommend() {
    try {
      final recommendation = recommender.recommend(recommendationContext);
      final exercise = MockExerciseCatalog.byId(recommendation.contentId);
      final video = MockVideoCatalog.byId(recommendation.contentId);
      if (recommendationContext.format == SupportFormat.video) {
        if (video == null) return null;
        return _SuggestionContent(
          contentTitle: video.title,
          explanation: recommendation.explanation,
          onStart: () => onStartVideo(video),
        );
      }
      if (exercise == null) return null;
      return _SuggestionContent(
        contentTitle: exercise.title,
        explanation: recommendation.explanation,
        onStart: () => onStartExercise(exercise),
      );
    } catch (_) {
      // Catálogo vazio ou erro: a tela mantém as opções abaixo, sem travar.
      return null;
    }
  }

  void _showAllOptions(BuildContext context) {
    // O catálogo já está renderizado abaixo da sugestão; rola até ele.
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
    );
  }
}

class _SuggestionContent {
  const _SuggestionContent({
    required this.contentTitle,
    required this.explanation,
    required this.onStart,
  });

  final String contentTitle;
  final String explanation;
  final VoidCallback onStart;
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({super.key, required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatLabels = exercise.supportedFormats
        .map((format) => format.label)
        .join(' · ');
    return Semantics(
      button: true,
      label:
          '${exercise.title}. ${exercise.goal} '
          '${exercise.durationMinutes} minutos. $formatLabels',
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
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.self_improvement_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              exercise.title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (exercise.isPreview) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Prévia',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.durationMinutes} min · $formatLabels',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}