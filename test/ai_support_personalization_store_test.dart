import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/ai_support_event_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_settings_repository.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/notifications/noop_support_notification_gateway.dart';

void main() {
  const consent = AiSupportConsent(
    personalizedSuggestionsGranted: true,
    grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
  );
  const preferences = AiSupportPreferences(
    personalizedSuggestionsEnabled: true,
    allowedCategories: <SupportSuggestionCategory>{
      SupportSuggestionCategory.reflection,
    },
  );

  test(
    'restaura escolhas e persiste mudanças sem bloquear a interface',
    () async {
      final settings = _FakeSettings(
        const SavedAiSupportSettings(
          consent: consent,
          preferences: preferences,
        ),
      );
      final store = MockAiSupportStore(
        isDemonstration: false,
        settingsDataSource: settings,
        notificationGateway: const NoopSupportNotificationGateway(),
      );
      addTearDown(store.dispose);

      await store.initialize();
      expect(store.isOnboarded, isTrue);
      expect(store.isPersonalizationEnabled, isTrue);

      store.setPersonalizationEnabled(false);
      await settings.saved.future;
      expect(settings.lastPreferences?.personalizedSuggestionsEnabled, isFalse);
    },
  );

  test(
    'preserva suggestionId do backend e registra feedback estruturado',
    () async {
      const suggestionId = '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46';
      final events = _FakeEvents();
      final store = MockAiSupportStore(
        isDemonstration: false,
        consent: consent,
        preferences: preferences,
        remoteRecommender: const _DeterministicRemote(suggestionId),
        eventDataSource: events,
        notificationGateway: const NoopSupportNotificationGateway(),
      );
      addTearDown(store.dispose);

      final suggestion = await store.generatePersonalizedSuggestion(
        refresh: false,
      );
      expect(suggestion?.id, suggestionId);

      store.recordFeedback(
        SuggestionFeedbackType.helpful,
        suggestion: suggestion!,
      );
      await events.recorded.future;
      expect(events.lastSuggestionId, suggestionId);
      expect(events.lastType, AiSupportEventType.helpful);
      expect(events.lastChannel, AiSupportEventChannel.app);
    },
  );

  test('cold start registra abertura usando somente UUID opaco', () async {
    const suggestionId = '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46';
    final events = _FakeEvents();
    final store = MockAiSupportStore(
      isDemonstration: false,
      eventDataSource: events,
      notificationGateway: const NoopSupportNotificationGateway(),
    );
    addTearDown(store.dispose);
    await store.initialize();

    store.recordNotificationOpened(suggestionId);
    await events.recorded.future;
    expect(events.lastType, AiSupportEventType.opened);
    expect(events.lastChannel, AiSupportEventChannel.localNotification);
  });

  test(
    'modo conectado não usa regra local quando o modelo fica em silêncio',
    () async {
      final now = DateTime.utc(2026, 9, 1, 12);
      final store = MockAiSupportStore(
        isDemonstration: false,
        consent: consent,
        preferences: preferences,
        signalDataSource: _FixedSignals(<SupportSignal>[
          DailyCheckInSignal(
            id: 'checkin-estruturado',
            createdAt: now,
            expiresAt: now.add(const Duration(days: 1)),
            moodScore: 1,
          ),
        ]),
        remoteRecommender: const _SilentModelRemote(),
        notificationGateway: const NoopSupportNotificationGateway(),
      );
      addTearDown(store.dispose);

      final suggestion = await store.generatePersonalizedSuggestion(now: now);

      expect(suggestion, isNull);
      expect(store.pendingSuggestion, isNull);
      expect(store.lastRecommendationReasonCode, 'model_abstained');
      expect(store.lastRecommendationOutcome, AiSupportRemoteOutcome.silent);
    },
  );

  test(
    'nova tentativa limpa falha anterior quando o backend responde',
    () async {
      final remote = _FailThenSilentRemote();
      final store = MockAiSupportStore(
        isDemonstration: false,
        consent: consent,
        preferences: preferences,
        remoteRecommender: remote,
        notificationGateway: const NoopSupportNotificationGateway(),
      );
      addTearDown(store.dispose);

      expect(
        await store.generatePersonalizedSuggestion(refresh: false),
        isNull,
      );
      expect(store.lastRefreshError, isNotNull);
      expect(store.lastRecommendationOutcome, AiSupportRemoteOutcome.error);

      expect(
        await store.generatePersonalizedSuggestion(refresh: false),
        isNull,
      );
      expect(store.lastRefreshError, isNull);
      expect(store.lastRecommendationOutcome, AiSupportRemoteOutcome.silent);
    },
  );
}

class _FakeSettings implements AiSupportSettingsDataSource {
  _FakeSettings(this.value);

  final SavedAiSupportSettings? value;
  final saved = Completer<void>();
  AiSupportPreferences? lastPreferences;

  @override
  Future<SavedAiSupportSettings?> load() async => value;

  @override
  Future<void> save({
    required AiSupportConsent consent,
    required AiSupportPreferences preferences,
  }) async {
    lastPreferences = preferences;
    if (!saved.isCompleted) saved.complete();
  }

  @override
  Future<void> clear() async {}
}

class _FakeEvents implements AiSupportEventDataSource {
  final recorded = Completer<void>();
  String? lastSuggestionId;
  AiSupportEventType? lastType;
  AiSupportEventChannel? lastChannel;

  @override
  Future<void> record({
    required String suggestionId,
    required AiSupportEventType type,
    required AiSupportEventChannel channel,
    DateTime? scheduledFor,
  }) async {
    lastSuggestionId = suggestionId;
    lastType = type;
    lastChannel = channel;
    if (!recorded.isCompleted) recorded.complete();
  }
}

class _DeterministicRemote implements AiSupportRemoteRecommender {
  const _DeterministicRemote(this.suggestionId);

  final String suggestionId;

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async {
    return RemoteAiSupportDecision(
      mode: AiSupportRolloutMode.limitedProduction,
      origin: 'openai',
      suggestionId: suggestionId,
      proposal: const <String, Object?>{
        'suggestionTemplateId': 'reflection_lighter_checkin_v1',
        'exerciseId': null,
        'reasonCodes': <String>['TODAY_LIGHTER_CHECKIN'],
        'confidenceBand': 'high',
      },
    );
  }
}

class _SilentModelRemote implements AiSupportRemoteRecommender {
  const _SilentModelRemote();

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async => const RemoteAiSupportDecision(
    mode: AiSupportRolloutMode.limitedProduction,
    outcome: AiSupportRemoteOutcome.silent,
    origin: 'openai',
    reasonCode: 'model_abstained',
  );
}

class _FailThenSilentRemote implements AiSupportRemoteRecommender {
  var calls = 0;

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async {
    calls += 1;
    if (calls == 1) throw StateError('Falha transitória simulada');
    return const RemoteAiSupportDecision(
      mode: AiSupportRolloutMode.limitedProduction,
      outcome: AiSupportRemoteOutcome.silent,
      origin: 'openai',
      reasonCode: 'model_abstained',
    );
  }
}

class _FixedSignals implements AiSupportSignalDataSource {
  const _FixedSignals(this.signals);

  final List<SupportSignal> signals;

  @override
  Future<List<SupportSignal>> loadRecentSignals() async => signals;
}
