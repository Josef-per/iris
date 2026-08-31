import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/presentation/ai_support_hub_screen.dart';
import 'package:iris/features/ai_support/presentation/notification_preview_screen.dart';
import 'package:iris/features/ai_support/presentation/support_suggestion_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 21, 12);

  MockAiSupportStore configuredStore() {
    final store = MockAiSupportStore(clock: () => now);
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
    return store;
  }

  Future<void> pumpApp(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
  }

  Future<void> scrollUntilVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding começa com fontes desligadas e explica limites', (
    tester,
  ) async {
    final store = MockAiSupportStore(clock: () => now);
    addTearDown(store.dispose);
    await pumpApp(tester, AiSupportHubScreen(store: store));

    expect(find.text('Apoio breve, sob seu controle'), findsOneWidget);
    expect(find.textContaining('Não é terapia'), findsOneWidget);

    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('ai-support-personalization-switch')),
    );
    expect(toggle.value, isFalse);
    expect(find.textContaining('texto livre do diário'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('ai-support-personalization-switch')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('ai-support-source-moodHistory')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sugestão aprovada abre exercício sem checagem e mantém ajuda urgente',
    (tester) async {
      final store = configuredStore();
      addTearDown(store.dispose);
      await pumpApp(tester, AiSupportHubScreen(store: store));

      await tester.tap(find.byKey(const Key('ai-support-generate')));
      await tester.pumpAndSettle();

      expect(find.text('Com base no que você registrou'), findsOneWidget);
      await scrollUntilVisible(
        tester,
        find.byKey(const Key('ai-support-detail-why')),
      );
      expect(find.byKey(const Key('ai-support-detail-why')), findsOneWidget);
      expect(find.byKey(const Key('safety-yes')), findsNothing);

      await tester.tap(
        find.byKey(const Key('ai-support-detail-primary-action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Etapa 1 de 5'), findsOneWidget);
      expect(find.byKey(const Key('support-urgent-help')), findsOneWidget);
      expect(find.byKey(const Key('safety-yes')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('preview é genérico e correção descarta somente o sinal local', (
    tester,
  ) async {
    final store = configuredStore();
    addTearDown(store.dispose);
    final suggestion = store.generateSuggestion(now: now)!;

    await pumpApp(
      tester,
      NotificationPreviewScreen(store: store, onOpenSuggestion: (_) {}),
    );

    expect(find.text('Uma pausa gentil, se fizer sentido.'), findsOneWidget);
    expect(find.textContaining('check-ins recentes'), findsNothing);
    expect(find.textContaining('diário'), findsNothing);

    await pumpApp(
      tester,
      SupportSuggestionScreen(store: store, suggestion: suggestion),
    );
    await scrollUntilVisible(
      tester,
      find.byKey(const Key('ai-support-detail-why')),
    );
    await tester.tap(find.byKey(const Key('ai-support-detail-why')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-support-does-not-match')));
    await tester.pumpAndSettle();

    expect(store.activeSignals, isEmpty);
    expect(store.pendingSuggestion, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'central permanece utilizável no tema escuro a 320 px e texto 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = configuredStore();
      addTearDown(store.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: AiSupportHubScreen(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sugestões de apoio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
