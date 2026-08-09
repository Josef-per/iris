import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpReminders(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LembretesScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lembrete é adicionado por campos reais e validados em 320 px', (
    tester,
  ) async {
    await pumpReminders(tester, size: const Size(320, 800));

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('apenas enquanto esta tela estiver aberta'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar lembrete'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-type-field')), findsOneWidget);
    expect(find.byKey(const Key('reminder-title-field')), findsOneWidget);
    expect(find.byKey(const Key('reminder-time-field')), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('reminder-submit')));
    await tester.pump();
    expect(find.text('Informe um título para o lembrete.'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('reminder-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medicamento').last);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('reminder-time-field')));
    await tester.pumpAndSettle();
    expect(find.text('Selecione o horário do lembrete'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('reminder-title-field')),
      'Medicação da noite',
    );
    await _tapVisible(tester, find.byKey(const Key('reminder-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Medicação da noite'), findsOneWidget);
    expect(find.text('Lembrete adicionado nesta sessão.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lembrete permite pausar, editar, excluir e desfazer', (
    tester,
  ) async {
    await pumpReminders(tester);

    final medicationCard = find.byKey(const ValueKey('reminder-2'));
    final medicationSwitch = find.descendant(
      of: medicationCard,
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(medicationSwitch).value, isTrue);

    await tester.tap(medicationSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(medicationSwitch).value, isFalse);
    expect(
      find.descendant(of: medicationCard, matching: find.text('Pausado')),
      findsOneWidget,
    );

    var mealCard = find.byKey(const ValueKey('reminder-1'));
    await _chooseReminderAction(
      tester,
      card: mealCard,
      action: AppReminderMenuAction.edit,
    );
    await tester.enterText(
      find.byKey(const Key('reminder-title-field')),
      'Desjejum',
    );
    await _tapVisible(tester, find.byKey(const Key('reminder-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Café da manhã'), findsNothing);
    expect(find.text('Desjejum'), findsOneWidget);
    expect(find.text('Lembrete atualizado nesta sessão.'), findsOneWidget);

    mealCard = find.byKey(const ValueKey('reminder-1'));
    await _chooseReminderAction(
      tester,
      card: mealCard,
      action: AppReminderMenuAction.delete,
    );
    expect(find.text('Excluir lembrete?'), findsOneWidget);
    expect(find.textContaining('“Desjejum”'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Desjejum'), findsNothing);
    expect(find.text('Lembrete excluído.'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(find.text('Desjejum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _chooseReminderAction(
  WidgetTester tester, {
  required Finder card,
  required AppReminderMenuAction action,
}) async {
  final menu = find.descendant(
    of: card,
    matching: find.byType(PopupMenuButton<AppReminderMenuAction>),
  );
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();

  final label = switch (action) {
    AppReminderMenuAction.edit => 'Editar',
    AppReminderMenuAction.delete => 'Excluir',
  };
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}
