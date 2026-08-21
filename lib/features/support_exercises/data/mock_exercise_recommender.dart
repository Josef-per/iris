import 'package:iris/features/support_exercises/data/mock_exercise_catalog.dart';
import 'package:iris/features/support_exercises/data/mock_video_catalog.dart';
import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';

/// Recomendador por regras locais e determinísticas.
///
/// Esta não é IA: é uma tabela de regras explicável que usa apenas a
/// necessidade, o tempo, o formato e as preferências de acessibilidade
/// declarados. A rota de urgência nunca passa por este recomendador.
abstract interface class ExerciseRecommender {
  ExerciseRecommendation recommend(RecommendationContext context);
}

/// Fallback estático usado quando o catálogo filtrado fica vazio: a primeira
/// prática segura do catálogo completo, ignorando filtros de tempo/formato,
/// mas respeitando a exclusão de respiração.
class MockExerciseRecommender implements ExerciseRecommender {
  MockExerciseRecommender({
    List<Exercise>? exercises,
    List<SupportVideo>? videos,
  }) : _exercises = exercises ?? MockExerciseCatalog.exercises,
       _videos = videos ?? MockVideoCatalog.videos;

  final List<Exercise> _exercises;
  final List<SupportVideo> _videos;

  @override
  ExerciseRecommendation recommend(RecommendationContext context) {
    if (context.format == SupportFormat.video) {
      return _recommendVideo(context);
    }
    return _recommendExercise(context);
  }

  ExerciseRecommendation _recommendExercise(RecommendationContext context) {
    final compatible = _exercises
        .where((exercise) => exercise.supportsFormat(context.format))
        .where(
          (exercise) =>
              exercise.durationMinutes <= context.time.maxMinutes,
        )
        .where(
          (exercise) =>
              !context.preferences.avoidBreathing || !exercise.focusesOnBreathing,
        )
        .toList(growable: false);

    final safeFallback = context.preferences.avoidBreathing
        ? _exercises.where((exercise) => !exercise.focusesOnBreathing).toList()
        : _exercises;

    if (compatible.isEmpty) {
      if (safeFallback.isEmpty) {
        throw StateError('Catálogo de exercícios indisponível.');
      }
      final fallback = _firstByNeed(safeFallback, context.need);
      return ExerciseRecommendation(
        contentId: fallback.id,
        explanation:
            '${_explanationPrefix(context)}. Nenhuma opção se encaixava no '
            'tempo e no formato pedidos, então sugerimos uma prática segura '
            'do catálogo.',
      );
    }

    final selected = _firstByNeed(compatible, context.need);
    final needNote = compatible.any(
      (exercise) => exercise.needs.contains(context.need),
    )
        ? ' Compatível com “${context.need.label}”.'
        : '';
    return ExerciseRecommendation(
      contentId: selected.id,
      explanation: '${_explanationPrefix(context)}.$needNote',
    );
  }

  ExerciseRecommendation _recommendVideo(RecommendationContext context) {
    final compatible = _videos
        .where((video) => video.durationMinutes <= context.time.maxMinutes)
        .toList(growable: false);

    if (compatible.isEmpty) {
      if (_videos.isEmpty) {
        throw StateError('Biblioteca de vídeos indisponível.');
      }
      return ExerciseRecommendation(
        contentId: _videos.first.id,
        explanation:
            '${_explanationPrefix(context)}. Nenhum vídeo se encaixava no '
            'tempo pedido, então sugerimos um vídeo curto do catálogo.',
      );
    }
    return ExerciseRecommendation(
      contentId: compatible.first.id,
      explanation: '${_explanationPrefix(context)}.',
    );
  }

  /// Ordenação determinística: necessidade escolhida primeiro, depois a
  /// prática mais curta e, por fim, a ordem do catálogo.
  Exercise _firstByNeed(List<Exercise> pool, SupportNeed need) {
    final indexed = pool.indexed.toList(growable: false);
    indexed.sort((a, b) {
      final needA = a.$2.needs.contains(need) ? 0 : 1;
      final needB = b.$2.needs.contains(need) ? 0 : 1;
      if (needA != needB) return needA - needB;
      final duration = a.$2.durationMinutes.compareTo(b.$2.durationMinutes);
      if (duration != 0) return duration;
      return a.$1 - b.$1;
    });
    return indexed.first.$2;
  }

  String _explanationPrefix(RecommendationContext context) {
    final parts = <String>[
      'Você pediu algo ${context.format.spokenLabel}',
      'para cerca de ${context.time.spokenLabel}',
      ...context.preferences.explanationNotes,
    ];
    return parts.join(', ');
  }
}