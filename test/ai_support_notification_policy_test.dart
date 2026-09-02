import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/mock_notification_policy.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_candidate.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

void main() {
  final now = DateTime(2026, 8, 21, 12);
  const consent = AiSupportConsent(
    personalizedSuggestionsGranted: true,
    grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
  );
  const preferences = AiSupportPreferences(
    personalizedSuggestionsEnabled: true,
    allowedCategories: <SupportSuggestionCategory>{
      SupportSuggestionCategory.reflection,
    },
    notifications: NotificationPreferences(
      enabled: true,
      frequency: NotificationFrequency.threeTimesPerWeek,
      window: NotificationWindow(
        start: SupportTimeOfDay(9),
        end: SupportTimeOfDay(21),
      ),
    ),
  );

  SupportSuggestion suggestion({
    DateTime? createdAt,
    DateTime? expiresAt,
    String id = 'suggestion-1',
  }) {
    return SupportSuggestion(
      id: id,
      templateId: 'reflection_difficult_checkins_v1',
      category: SupportSuggestionCategory.reflection,
      reasonCodes: const <SupportReasonCode>{
        SupportReasonCode.recentDifficultCheckIns,
      },
      confidenceBand: ConfidenceBand.medium,
      usedSources: const <SupportSignalSource>{SupportSignalSource.moodHistory},
      createdAt: createdAt ?? now,
      expiresAt: expiresAt ?? now.add(const Duration(hours: 12)),
    );
  }

  NotificationCandidate candidateFor(
    SupportSuggestion value, {
    DateTime? expiresAt,
  }) {
    return NotificationCandidate(
      id: 'candidate-${value.id}',
      suggestionId: value.id,
      templateId: value.templateId,
      genericNotificationTemplateId: 'notification_pause_gentle_v1',
      createdAt: value.createdAt,
      expiresAt: expiresAt ?? value.expiresAt,
    );
  }

  NotificationPolicyInput input({
    AiSupportConsent consentValue = consent,
    AiSupportPreferences preferencesValue = preferences,
    SupportSuggestion? suggestionValue,
    NotificationCandidate? candidateValue,
    Iterable<NotificationDeliveryRecord> deliveries =
        const <NotificationDeliveryRecord>[],
    Iterable<SuggestionFeedback> feedback = const <SuggestionFeedback>[],
    DateTime? at,
  }) {
    final selectedSuggestion = suggestionValue ?? suggestion();
    return NotificationPolicyInput(
      consent: consentValue,
      preferences: preferencesValue,
      suggestion: selectedSuggestion,
      candidate: candidateValue ?? candidateFor(selectedSuggestion),
      deliveries: deliveries,
      feedback: feedback,
      now: at ?? now,
    );
  }

  NotificationDeliveryRecord delivery(
    DateTime deliveredAt, {
    String id = 'old',
  }) {
    return NotificationDeliveryRecord(
      candidateId: 'candidate-$id',
      suggestionId: 'suggestion-$id',
      templateId: 'reflection_difficult_checkins_v1',
      deliveredAt: deliveredAt,
    );
  }

  SuggestionFeedback dismissal(DateTime createdAt, {String id = 'old'}) {
    return SuggestionFeedback(
      id: 'feedback-$id',
      suggestionId: 'suggestion-$id',
      templateId: 'reflection_difficult_checkins_v1',
      type: SuggestionFeedbackType.dismissed,
      createdAt: createdAt,
    );
  }

  group('MockNotificationPolicy', () {
    test('permite somente candidato válido dentro da janela escolhida', () {
      final result = const MockNotificationPolicy().evaluate(input());

      expect(result.canDeliver, isTrue);
      expect(
        result.candidate?.genericNotificationTemplateId,
        'notification_pause_gentle_v1',
      );
    });

    test('não entrega depois da janela e não agenda rajada atrasada', () {
      final result = const MockNotificationPolicy().evaluate(
        input(at: DateTime(2026, 8, 21, 22)),
      );

      expect(result.canDeliver, isFalse);
      expect(result.blockReason, NotificationPolicyBlockReason.outsideWindow);
    });

    test('respeita o limite de uma entrega por dia', () {
      final result = const MockNotificationPolicy().evaluate(
        input(deliveries: <NotificationDeliveryRecord>[delivery(now)]),
      );

      expect(result.canDeliver, isFalse);
      expect(
        result.blockReason,
        NotificationPolicyBlockReason.dailyLimitReached,
      );
    });

    test('respeita o limite semanal', () {
      final result = const MockNotificationPolicy().evaluate(
        input(
          deliveries: <NotificationDeliveryRecord>[
            delivery(DateTime(2026, 8, 18), id: 'a'),
            delivery(DateTime(2026, 8, 19), id: 'b'),
            delivery(DateTime(2026, 8, 20), id: 'c'),
          ],
        ),
      );

      expect(result.canDeliver, isFalse);
      expect(
        result.blockReason,
        NotificationPolicyBlockReason.weeklyLimitReached,
      );
    });

    test('aplica cooldown após dispensa', () {
      final result = const MockNotificationPolicy().evaluate(
        input(
          feedback: <SuggestionFeedback>[
            dismissal(now.subtract(const Duration(hours: 2))),
          ],
        ),
      );

      expect(result.canDeliver, isFalse);
      expect(result.blockReason, NotificationPolicyBlockReason.cooldownActive);
    });

    test('três dispensas consecutivas pausam por sete dias', () {
      final result = const MockNotificationPolicy().evaluate(
        input(
          feedback: <SuggestionFeedback>[
            dismissal(now.subtract(const Duration(hours: 3)), id: 'a'),
            dismissal(now.subtract(const Duration(hours: 2)), id: 'b'),
            dismissal(now.subtract(const Duration(hours: 1)), id: 'c'),
          ],
        ),
      );

      expect(result.canDeliver, isFalse);
      expect(result.blockReason, NotificationPolicyBlockReason.automaticPause);
      expect(
        result.automaticPauseUntil,
        now.add(const Duration(days: 7, hours: -1)),
      );
    });

    test('candidato expirado é removido da entrega', () {
      final selectedSuggestion = suggestion(
        expiresAt: now.add(const Duration(days: 1)),
      );
      final result = const MockNotificationPolicy().evaluate(
        input(
          suggestionValue: selectedSuggestion,
          candidateValue: candidateFor(selectedSuggestion, expiresAt: now),
        ),
      );

      expect(result.canDeliver, isFalse);
      expect(result.blockReason, NotificationPolicyBlockReason.expired);
    });

    test('revogação da fonte invalida um candidato pendente', () {
      const revoked = AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{},
      );
      final result = const MockNotificationPolicy().evaluate(
        input(consentValue: revoked),
      );

      expect(result.canDeliver, isFalse);
      expect(
        result.blockReason,
        NotificationPolicyBlockReason.sourceNotGranted,
      );
    });
  });
}
