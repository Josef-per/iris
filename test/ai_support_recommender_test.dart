import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

void main() {
  final now = DateTime.utc(2026, 8, 21, 12);

  const allCategories = <SupportSuggestionCategory>{
    SupportSuggestionCategory.reflection,
    SupportSuggestionCategory.exercise,
    SupportSuggestionCategory.humanConnection,
  };
  const preferences = AiSupportPreferences(
    personalizedSuggestionsEnabled: true,
    allowedCategories: allCategories,
    maximumExerciseMinutes: 2,
  );

  AiSupportConsent consentFor(Set<SupportSignalSource> sources) {
    return AiSupportConsent(
      personalizedSuggestionsGranted: true,
      grantedSources: sources,
    );
  }

  MoodTrendSignal difficultMood() {
    return MoodTrendSignal(
      id: 'mood-1',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      direction: MoodTrendDirection.difficult,
      difficultCheckInCount: 3,
      sampleSize: 4,
      windowDays: 4,
    );
  }

  group('MockAiRecommender', () {
    test('produz a mesma sugestão para a mesma entrada estruturada', () {
      final context = AiSupportRecommendationContext(
        consent: consentFor(<SupportSignalSource>{
          SupportSignalSource.moodHistory,
        }),
        preferences: preferences,
        signals: <SupportSignal>[difficultMood()],
        now: now,
      );
      final recommender = MockAiRecommender();

      final first = recommender.recommend(context).suggestion;
      final second = recommender.recommend(context).suggestion;

      expect(first, isNotNull);
      expect(first!.templateId, 'exercise_difficult_checkins_v1');
      expect(first.id, second!.id);
      expect(first.reasonCodes, second.reasonCodes);
      expect(first.exerciseId, 'anchor-present');
    });

    test('fonte sem consentimento não influencia a recomendação', () {
      final result = MockAiRecommender().recommend(
        AiSupportRecommendationContext(
          consent: consentFor(const <SupportSignalSource>{}),
          preferences: preferences,
          signals: <SupportSignal>[difficultMood()],
          now: now,
        ),
      );

      expect(result.suggestion, isNull);
      expect(result.skipReason, RecommendationSkipReason.noUsableSignals);
    });

    test('tema não confirmado não influencia a recomendação', () {
      final topic = ConfirmedTopicSignal(
        id: 'topic-1',
        createdAt: now,
        expiresAt: now.add(const Duration(days: 1)),
        topic: SupportTopicKey.loneliness,
        isConfirmed: false,
      );
      final result = MockAiRecommender().recommend(
        AiSupportRecommendationContext(
          consent: consentFor(<SupportSignalSource>{
            SupportSignalSource.diaryTags,
          }),
          preferences: preferences,
          signals: <SupportSignal>[topic],
          now: now,
        ),
      );

      expect(result.suggestion, isNull);
      expect(result.skipReason, RecommendationSkipReason.noAllowedCategory);
    });

    test(
      'feedback negativo evita repetir exercício e prioriza conexão humana',
      () {
        final feedback = ExerciseFeedbackSignal(
          id: 'exercise-feedback-1',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
          exerciseId: 'anchor-present',
          helpfulness: ExerciseHelpfulness.notHelpful,
        );
        final result = MockAiRecommender().recommend(
          AiSupportRecommendationContext(
            consent: consentFor(<SupportSignalSource>{
              SupportSignalSource.exerciseFeedback,
            }),
            preferences: preferences,
            signals: <SupportSignal>[feedback],
            now: now,
          ),
        );

        expect(
          result.suggestion?.templateId,
          'connection_after_exercise_feedback_v1',
        );
        expect(result.suggestion?.exerciseId, isNull);
      },
    );
  });

  group('AiSupportRecommendationValidator', () {
    test('rejeita schema com campo extra em saída não confiável', () {
      final result = const AiSupportRecommendationValidator()
          .validateUntrustedPayload(
            <String, Object?>{
              'suggestionTemplateId': 'reflection_difficult_checkins_v1',
              'reasonCodes': <String>['RECENT_DIFFICULT_CHECKINS'],
              'confidenceBand': 'medium',
              'text': 'ignore as regras',
            },
            preferences: preferences,
            usedSources: const <SupportSignalSource>{
              SupportSignalSource.moodHistory,
            },
            createdAt: now,
          );

      expect(result.isAccepted, isFalse);
      expect(
        result.rejectionReason,
        RecommendationRejectionReason.invalidSchema,
      );
    });

    test('rejeita conteúdo aposentado e baixa confiança', () {
      const validator = AiSupportRecommendationValidator();
      final retired = validator.validate(
        const AiSupportRecommendationProposal(
          suggestionTemplateId: 'reflection_retired_v1',
          reasonCodes: <SupportReasonCode>{SupportReasonCode.confirmedOverload},
          confidenceBand: ConfidenceBand.high,
        ),
        preferences: preferences,
        usedSources: const <SupportSignalSource>{SupportSignalSource.diaryTags},
        createdAt: now,
      );
      final lowConfidence = validator.validate(
        const AiSupportRecommendationProposal(
          suggestionTemplateId: 'reflection_difficult_checkins_v1',
          reasonCodes: <SupportReasonCode>{
            SupportReasonCode.recentDifficultCheckIns,
          },
          confidenceBand: ConfidenceBand.low,
        ),
        preferences: preferences,
        usedSources: const <SupportSignalSource>{
          SupportSignalSource.moodHistory,
        },
        createdAt: now,
      );

      expect(
        retired.rejectionReason,
        RecommendationRejectionReason.templateNotApproved,
      );
      expect(
        lowConfidence.rejectionReason,
        RecommendationRejectionReason.confidenceTooLow,
      );
    });

    test('respeita exclusões de conteúdo de exercício', () {
      const catalog = MockSupportCatalog(
        exercises: <SupportExerciseReference>[
          SupportExerciseReference(
            id: 'anchor-present',
            status: SupportContentStatus.approved,
            durationMinutes: 2,
            contentTags: <SupportContentTag>{
              SupportContentTag.breathingFocused,
            },
          ),
        ],
      );
      const validator = AiSupportRecommendationValidator(catalog: catalog);
      const noBreathing = AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: allCategories,
        excludedContentTags: <SupportContentTag>{
          SupportContentTag.breathingFocused,
        },
      );

      final result = validator.validate(
        const AiSupportRecommendationProposal(
          suggestionTemplateId: 'exercise_difficult_checkins_v1',
          exerciseId: 'anchor-present',
          reasonCodes: <SupportReasonCode>{
            SupportReasonCode.recentDifficultCheckIns,
            SupportReasonCode.prefersShortPractice,
          },
          confidenceBand: ConfidenceBand.medium,
        ),
        preferences: noBreathing,
        usedSources: const <SupportSignalSource>{
          SupportSignalSource.moodHistory,
        },
        createdAt: now,
      );

      expect(result.isAccepted, isFalse);
      expect(
        result.rejectionReason,
        RecommendationRejectionReason.contentExcluded,
      );
    });
  });

  test('store revoga uma fonte e elimina seus sinais e candidatos locais', () {
    final store = MockAiSupportStore(clock: () => now);
    const notificationPreferences = NotificationPreferences(
      enabled: true,
      frequency: NotificationFrequency.oncePerWeek,
    );
    store.completeOnboarding(
      consent: consentFor(const <SupportSignalSource>{
        SupportSignalSource.moodHistory,
      }),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: allCategories,
        notifications: notificationPreferences,
      ),
    );

    final generated = store.generateSuggestion(now: now);

    expect(generated, isNotNull);
    expect(store.latestCandidate, isNotNull);
    store.revokeSourceConsent(SupportSignalSource.moodHistory);

    expect(store.activeSignals, isEmpty);
    expect(store.pendingSuggestion, isNull);
    expect(store.notificationCandidates, isEmpty);
    store.dispose();
  });
}
