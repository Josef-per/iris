import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/presentation/ai_support_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockAiSupportStore connectedStore(AiSupportRemoteRecommender remote) {
    return MockAiSupportStore(
      isDemonstration: false,
      consent: const AiSupportConsent(
        personalizedSuggestionsGranted: true,
        grantedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
      ),
      preferences: const AiSupportPreferences(
        personalizedSuggestionsEnabled: true,
        allowedCategories: <SupportSuggestionCategory>{
          SupportSuggestionCategory.reflection,
          SupportSuggestionCategory.exercise,
        },
      ),
      signalDataSource: const _EmptySignals(),
      remoteRecommender: remote,
    );
  }

  Future<void> pumpHub(WidgetTester tester, MockAiSupportStore store) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AiSupportHubScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'abstenção segura é explicada e oferece prática sem personalização',
    (tester) async {
      final store = connectedStore(const _SilentRemote());
      addTearDown(store.dispose);

      await pumpHub(tester, store);

      expect(
        find.text('Não encontramos um apoio personalizado agora'),
        findsOneWidget,
      );
      expect(find.textContaining('dados que você autorizou'), findsOneWidget);
      expect(find.text('Não conseguimos buscar um apoio agora'), findsNothing);

      await tester.tap(
        find.byKey(const Key('ai-support-practice-after-empty')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exercícios'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falha técnica é diferenciada e permite tentar novamente', (
    tester,
  ) async {
    final store = connectedStore(const _FailingRemote());
    addTearDown(store.dispose);

    await pumpHub(tester, store);

    expect(find.text('Não conseguimos buscar um apoio agora'), findsOneWidget);
    expect(
      find.text('Não encontramos um apoio personalizado agora'),
      findsNothing,
    );
    expect(
      find.byKey(const Key('ai-support-retry-personalized')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ai-support-practice-after-error')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ai-support-retry-personalized')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não conseguimos buscar um apoio agora. As práticas do app continuam disponíveis.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ver práticas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'resposta rejeitada pelas verificações não parece uma abstenção',
    (tester) async {
      final store = connectedStore(const _RejectedRemote());
      addTearDown(store.dispose);

      await pumpHub(tester, store);

      expect(
        find.text('A sugestão não passou pelas verificações'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ai-support-retry-after-rejection')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ai-support-practice-after-rejection')),
        findsOneWidget,
      );
      expect(
        find.text('Não encontramos um apoio personalizado agora'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _SilentRemote implements AiSupportRemoteRecommender {
  const _SilentRemote();

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async {
    return const RemoteAiSupportDecision(
      mode: AiSupportRolloutMode.limitedProduction,
      origin: 'openai',
      outcome: AiSupportRemoteOutcome.silent,
      reasonCode: 'no_consent_evidence',
    );
  }
}

class _RejectedRemote implements AiSupportRemoteRecommender {
  const _RejectedRemote();

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async {
    return const RemoteAiSupportDecision(
      mode: AiSupportRolloutMode.limitedProduction,
      origin: 'openai',
      outcome: AiSupportRemoteOutcome.rejected,
      reasonCode: 'reason_without_consented_evidence',
    );
  }
}

class _FailingRemote implements AiSupportRemoteRecommender {
  const _FailingRemote();

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) {
    throw StateError('Falha remota simulada');
  }
}

class _EmptySignals implements AiSupportSignalDataSource {
  const _EmptySignals();

  @override
  Future<List<SupportSignal>> loadRecentSignals() async => <SupportSignal>[];
}
