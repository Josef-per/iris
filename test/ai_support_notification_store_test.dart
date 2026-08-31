import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_notification_policy.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/notifications/fake_support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/support_notification_gateway.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);

  MockAiSupportStore realStore(FakeSupportNotificationGateway gateway) {
    final store = MockAiSupportStore(
      clock: () => now,
      isDemonstration: false,
      notificationGateway: gateway,
      signalDataSource: _StaticSignalDataSource(<SupportSignal>[
        MoodTrendSignal(
          id: 'mood-trend-test',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
          direction: MoodTrendDirection.difficult,
          difficultCheckInCount: 3,
          sampleSize: 4,
          windowDays: 4,
        ),
      ]),
    );
    store.completeOnboarding(
      consent: const AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{
          SupportSignalSource.moodHistory,
          SupportSignalSource.notificationInteractions,
        },
      ),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: <SupportSuggestionCategory>{
          SupportSuggestionCategory.exercise,
          SupportSuggestionCategory.reflection,
        },
        notifications: NotificationPreferences(
          enabled: true,
          frequency: NotificationFrequency.oncePerWeek,
        ),
      ),
    );
    return store;
  }

  test('modo real registra candidato somente depois do agendamento', () async {
    final gateway = _BlockingFakeSupportNotificationGateway();
    final store = realStore(gateway);
    addTearDown(store.dispose);
    await store.initializeNotifications();

    final generation = store.generatePersonalizedSuggestion(now: now);
    await gateway.scheduleStarted.future;

    expect(store.notificationCandidates, isEmpty);
    expect(store.pendingNotificationCandidate, isNull);
    expect(gateway.permissionRequestCount, 0);

    gateway.allowScheduleToFinish.complete();
    expect(await generation, isNotNull);

    expect(gateway.scheduled, hasLength(1));
    final request = gateway.scheduled.single;
    expect(request.scheduledAt, now.add(const Duration(minutes: 1)));
    expect(isValidSupportNotificationCandidateId(request.candidateId), isTrue);
    expect(request.candidateId, isNot(contains('candidate')));
    expect(store.pendingNotificationCandidate?.id, request.candidateId);
    expect(store.lastNotificationDecision?.canDeliver, isTrue);
  });

  test('permissão é pedida apenas pelo método explícito', () async {
    final gateway = FakeSupportNotificationGateway(
      currentPermission: SupportNotificationPermissionStatus.notGranted,
    );
    final store = realStore(gateway);
    addTearDown(store.dispose);
    await store.initializeNotifications();

    await store.generatePersonalizedSuggestion(now: now);

    expect(gateway.permissionRequestCount, 0);
    expect(gateway.scheduled, isEmpty);
    expect(
      store.lastNotificationDecision?.blockReason,
      NotificationPolicyBlockReason.systemPermissionNotGranted,
    );

    expect(
      await store.requestNotificationPermission(),
      SupportNotificationPermissionStatus.granted,
    );
    expect(gateway.permissionRequestCount, 1);

    await store.schedulePendingNotification(now: now);
    expect(gateway.scheduled, hasLength(1));
  });

  test('falha nativa não cria candidato nem falsa entrega', () async {
    final gateway = _FailingFakeSupportNotificationGateway();
    final store = realStore(gateway);
    addTearDown(store.dispose);
    await store.initializeNotifications();

    await store.generatePersonalizedSuggestion(now: now);

    expect(store.notificationCandidates, isEmpty);
    expect(store.pendingNotificationCandidate, isNull);
    expect(store.lastNotificationError, isA<StateError>());
    expect(
      store.lastNotificationDecision?.blockReason,
      NotificationPolicyBlockReason.deliveryUnavailable,
    );
  });

  test(
    'abertura vira sinal estruturado e não duplica o mesmo evento',
    () async {
      final gateway = FakeSupportNotificationGateway(
        currentPermission: SupportNotificationPermissionStatus.granted,
      );
      final store = realStore(gateway);
      addTearDown(store.dispose);
      await store.initializeNotifications();
      await store.generatePersonalizedSuggestion(now: now);
      final candidateId = gateway.scheduled.single.candidateId;

      gateway.simulateOpen(candidateId);
      gateway.simulateOpen(candidateId);

      final interactions = store.activeSignals
          .whereType<NotificationInteractionSignal>()
          .toList(growable: false);
      expect(interactions, hasLength(1));
      expect(
        interactions.single.interaction,
        NotificationInteractionType.opened,
      );
      expect(interactions.single.templateId, isNotNull);
      expect(interactions.single.category, isNotNull);
    },
  );

  test(
    'abertura em cold start é registrada sem carregar texto sensível',
    () async {
      const candidateId = 'candidate_0123456789abcdef';
      final gateway = FakeSupportNotificationGateway(
        currentPermission: SupportNotificationPermissionStatus.granted,
        initialCandidateId: candidateId,
      );
      final store = realStore(gateway);
      addTearDown(store.dispose);

      await store.initializeNotifications();

      final interactions = store.activeSignals
          .whereType<NotificationInteractionSignal>()
          .toList(growable: false);
      expect(interactions, hasLength(1));
      expect(interactions.single.templateId, isNull);
      expect(interactions.single.category, isNull);
    },
  );

  test('modo de demonstração continua inteiramente síncrono', () {
    final gateway = FakeSupportNotificationGateway(
      currentPermission: SupportNotificationPermissionStatus.granted,
    );
    final store = MockAiSupportStore(
      clock: () => now,
      notificationGateway: gateway,
    );
    addTearDown(store.dispose);
    store.completeOnboarding(
      consent: const AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
      ),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: <SupportSuggestionCategory>{
          SupportSuggestionCategory.exercise,
          SupportSuggestionCategory.reflection,
        },
        notifications: NotificationPreferences(
          enabled: true,
          frequency: NotificationFrequency.oncePerWeek,
        ),
      ),
    );

    expect(store.generateSuggestion(now: now), isNotNull);
    expect(store.latestCandidate, isNotNull);
    expect(gateway.scheduled, isEmpty);
    expect(gateway.permissionRequestCount, 0);
  });
}

class _StaticSignalDataSource implements AiSupportSignalDataSource {
  const _StaticSignalDataSource(this.signals);

  final List<SupportSignal> signals;

  @override
  Future<List<SupportSignal>> loadRecentSignals() async {
    return List<SupportSignal>.of(signals);
  }
}

class _BlockingFakeSupportNotificationGateway
    extends FakeSupportNotificationGateway {
  _BlockingFakeSupportNotificationGateway()
    : super(currentPermission: SupportNotificationPermissionStatus.granted);

  final Completer<void> scheduleStarted = Completer<void>();
  final Completer<void> allowScheduleToFinish = Completer<void>();

  @override
  Future<void> schedule(SupportNotificationRequest request) async {
    scheduleStarted.complete();
    await allowScheduleToFinish.future;
    await super.schedule(request);
  }
}

class _FailingFakeSupportNotificationGateway
    extends FakeSupportNotificationGateway {
  _FailingFakeSupportNotificationGateway()
    : super(currentPermission: SupportNotificationPermissionStatus.granted);

  @override
  Future<void> schedule(SupportNotificationRequest request) async {
    throw StateError('falha de agendamento simulada');
  }
}
