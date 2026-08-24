import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/presentation/after_journal_support_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => AfterJournalSupportSheet.show(context),
                child: const Text('abrir apoio'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir apoio'));
    await tester.pumpAndSettle();
  }

  testWidgets('acesso após registro é estático e não infere uma crise', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('Quer apoio agora?'), findsOneWidget);
    expect(find.byKey(const Key('after-journal-exercises')), findsOneWidget);
    expect(find.byKey(const Key('after-journal-not-ok')), findsOneWidget);
    expect(find.byKey(const Key('after-journal-urgent-help')), findsOneWidget);
    expect(find.textContaining('Você corre risco'), findsNothing);
    expect(
      find.textContaining('não interpreta o texto nem monitora'),
      findsOneWidget,
    );
  });

  testWidgets('somente tocar em ajuda urgente abre a checagem', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('after-journal-urgent-help')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Você corre risco'), findsOneWidget);
    expect(find.byKey(const Key('safety-yes')), findsOneWidget);
  });
}
