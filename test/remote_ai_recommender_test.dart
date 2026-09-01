import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);

  test(
    'cliente envia somente idempotência e origem, nunca sinais clínicos',
    () async {
      final invoker = _FakeInvoker(<String, Object?>{'status': 'silent'});
      final recommender = SupabaseAiSupportRemoteRecommender(
        invoker: invoker,
        requestIdFactory: () => '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
      );

      await recommender.recommend(
        AiSupportRecommendationContext(
          consent: const AiSupportConsent(
            personalizedSuggestionsGranted: true,
            grantedSources: <SupportSignalSource>{
              SupportSignalSource.moodHistory,
            },
          ),
          preferences: const AiSupportPreferences(
            personalizedSuggestionsEnabled: true,
            allowedCategories: <SupportSuggestionCategory>{
              SupportSuggestionCategory.reflection,
            },
          ),
          signals: <SupportSignal>[
            DailyCheckInSignal(
              id: 'private-local-signal',
              createdAt: now,
              expiresAt: now.add(const Duration(days: 1)),
              moodScore: 1,
            ),
          ],
          now: now,
        ),
        trigger: AiSupportRecommendationTrigger.afterCheckIn,
      );

      expect(invoker.body, <String, Object?>{
        'requestId': '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
        'trigger': 'after_checkin',
      });
      final encoded = jsonEncode(invoker.body);
      expect(encoded, isNot(contains('private-local-signal')));
      expect(encoded, isNot(contains('signals')));
      expect(encoded, isNot(contains('preferences')));
      expect(encoded, isNot(contains('diario')));
    },
  );

  test('não deixa a escolha da IA em shadow influenciar o paciente', () async {
    final context = AiSupportRecommendationContext(
      consent: const AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
      ),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: <SupportSuggestionCategory>{
          SupportSuggestionCategory.reflection,
        },
      ),
      signals: const <SupportSignal>[],
      now: now,
    );
    Map<String, Object?> response(String mode) => <String, Object?>{
      'mode': mode,
      'status': 'suggested',
      'origin': 'openai',
      'suggestionId': '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
      'templateId': 'reflection_difficult_checkins_v1',
      'exerciseId': null,
      'reasonCodes': <String>['RECENT_DIFFICULT_CHECKINS'],
      'confidenceBand': 'medium',
    };

    final shadow = await SupabaseAiSupportRemoteRecommender(
      invoker: _FakeInvoker(response('shadow')),
      requestIdFactory: () => '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
    ).recommend(context);
    final pilot = await SupabaseAiSupportRemoteRecommender(
      invoker: _FakeInvoker(response('pilot')),
      requestIdFactory: () => '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
    ).recommend(context);

    expect(shadow.shouldUseProposal, isFalse);
    expect(pilot.shouldUseProposal, isTrue);
    expect(pilot.suggestionId, '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46');
    expect(
      pilot.proposal?['suggestionTemplateId'],
      'reflection_difficult_checkins_v1',
    );
  });

  test('rejeita proposta que não tenha sido selecionada pela OpenAI', () async {
    final context = AiSupportRecommendationContext(
      consent: const AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
      ),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: <SupportSuggestionCategory>{
          SupportSuggestionCategory.reflection,
        },
      ),
      signals: const <SupportSignal>[],
      now: now,
    );
    final future = SupabaseAiSupportRemoteRecommender(
      invoker: _FakeInvoker(<String, Object?>{
        'mode': 'limited',
        'status': 'suggested',
        'origin': 'regra_local',
        'suggestionId': '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
        'templateId': 'reflection_difficult_checkins_v1',
        'exerciseId': null,
        'reasonCodes': <String>['RECENT_DIFFICULT_CHECKINS'],
        'confidenceBand': 'medium',
      }),
      requestIdFactory: () => '0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46',
    ).recommend(context);

    await expectLater(future, throwsFormatException);
  });

  test('gera UUID v4 sem dados pessoais', () {
    final value = generateAiSupportRequestId();
    expect(
      value,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}

class _FakeInvoker implements AiSupportFunctionInvoker {
  _FakeInvoker(this.response);

  final Map<String, Object?> response;
  Map<String, Object?>? body;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> body) async {
    this.body = body;
    return response;
  }
}
