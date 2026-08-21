import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_catalog.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_recommender.dart';
import 'package:iris/features/support_exercises/data/mock_video_catalog.dart';
import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/exercise_step.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';

void main() {
  Exercise catalogExercise({
    required String id,
    int minutes = 3,
    List<SupportNeed> needs = const [SupportNeed.present],
    Set<SupportFormat> formats = const {
      SupportFormat.interactive,
      SupportFormat.audio,
    },
    Set<ExerciseSafetyTag> tags = const {},
  }) {
    return Exercise(
      id: id,
      title: id,
      goal: 'objetivo',
      durationMinutes: minutes,
      supportedFormats: formats,
      needs: needs,
      steps: const [
        ExerciseStep(type: ExerciseStepType.closing, prompt: 'fim'),
      ],
      safetyTags: tags,
      author: 'a',
      conceptualSource: 'fonte',
      clinicalReviewer: 'revisora',
      version: '1.0',
      nextReviewDate: '2027-01-01',
    );
  }

  group('MockExerciseRecommender', () {
    test('mesma entrada produz sempre a mesma recomendação', () {
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes3,
        format: SupportFormat.interactive,
      );
      final recommender = MockExerciseRecommender();

      final first = recommender.recommend(context);
      final second = recommender.recommend(context);

      expect(first.contentId, second.contentId);
      expect(first.explanation, second.explanation);
    });

    test('prefere a necessidade escolhida e respeita o tempo', () {
      final recommender = MockExerciseRecommender(
        exercises: [
          catalogExercise(
            id: 'nao-compativel',
            minutes: 5,
            needs: [SupportNeed.selfKindness],
          ),
          catalogExercise(
            id: 'compativel-curta',
            minutes: 2,
            needs: [SupportNeed.present],
          ),
          catalogExercise(
            id: 'compativel-media',
            minutes: 3,
            needs: [SupportNeed.present],
          ),
        ],
      );
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes3,
        format: SupportFormat.interactive,
      );

      final recommendation = recommender.recommend(context);

      expect(recommendation.contentId, 'compativel-curta');
      expect(recommendation.explanation, contains('interativo'));
      expect(recommendation.explanation, contains('3 minutos'));
      expect(recommendation.explanation, contains('Voltar para o presente'));
    });

    test('formato de áudio filtra práticas somente interativas', () {
      final recommender = MockExerciseRecommender(
        exercises: [
          catalogExercise(
            id: 'so-interativo',
            formats: const {SupportFormat.interactive},
          ),
          catalogExercise(
            id: 'com-audio',
            formats: const {SupportFormat.interactive, SupportFormat.audio},
          ),
        ],
      );
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes5,
        format: SupportFormat.audio,
      );

      expect(recommender.recommend(context).contentId, 'com-audio');
    });

    test('preferência sem respiração exclui conteúdo incompatível', () {
      final recommender = MockExerciseRecommender(
        exercises: [
          catalogExercise(
            id: 'respiratorio',
            tags: const {ExerciseSafetyTag.breathingFocus},
          ),
          catalogExercise(id: 'seguro', minutes: 1),
        ],
      );
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes5,
        format: SupportFormat.interactive,
        preferences: AccessibilityPreferences(avoidBreathing: true),
      );

      final recommendation = recommender.recommend(context);

      expect(recommendation.contentId, 'seguro');
      expect(recommendation.explanation, contains('sem foco na respiração'));
    });

    test('formato de vídeo recomenda a biblioteca de vídeos', () {
      final recommender = MockExerciseRecommender();
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes5,
        format: SupportFormat.video,
      );

      final recommendation = recommender.recommend(context);

      expect(MockVideoCatalog.byId(recommendation.contentId), isNotNull);
      expect(recommendation.explanation, contains('para assistir'));
    });

    test('catálogo filtrado vazio usa fallback estático seguro', () {
      final recommender = MockExerciseRecommender(
        exercises: [catalogExercise(id: 'unica', minutes: 10)],
      );
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes1_2,
        format: SupportFormat.interactive,
      );

      final recommendation = recommender.recommend(context);

      expect(recommendation.contentId, 'unica');
      expect(recommendation.explanation, contains('prática segura'));
    });

    test('catálogo totalmente vazio lança erro controlado', () {
      final recommender = MockExerciseRecommender(exercises: const []);
      const context = RecommendationContext(
        need: SupportNeed.present,
        time: SupportTime.minutes3,
        format: SupportFormat.interactive,
      );

      expect(() => recommender.recommend(context), throwsA(isA<StateError>()));
    });

    test('catálogo real conduz práticas guiadas, sem respostas certas', () {
      final exercises = MockExerciseCatalog.exercises;

      expect(exercises.length, greaterThanOrEqualTo(5));
      final guidedSteps = exercises
          .expand((exercise) => exercise.steps)
          .where((step) => step.type == ExerciseStepType.guidedPractice);
      expect(guidedSteps.length, greaterThanOrEqualTo(15));

      final ids = exercises.map((exercise) => exercise.id).toSet();
      expect(ids.length, exercises.length, reason: 'ids únicos');
      for (final exercise in exercises) {
        expect(exercise.steps.length, inInclusiveRange(3, 6));
        expect(exercise.steps.first.type, ExerciseStepType.guidedPractice);
        expect(exercise.author, isNotEmpty);
        expect(exercise.clinicalReviewer, isNotEmpty);
        expect(exercise.nextReviewDate, isNotEmpty);
      }
    });
  });
}
