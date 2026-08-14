import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/reminders/reminder_repository.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpReminders(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ReminderDataSource? dataSource,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LembretesScreen(dataSource: dataSource ?? _ReminderDataSource()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lembrete é adicionado por campos reais e validados em 320 px', (
    tester,
  ) async {
    final dataSource = _ReminderDataSource();
    await pumpReminders(
      tester,
      size: const Size(320, 800),
      dataSource: dataSource,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('reminders-loading')), findsNothing);

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
    expect(find.text('Lembrete adicionado.'), findsOneWidget);
    expect(dataSource.reminders, hasLength(1));
    expect(dataSource.reminders.last.type, PatientReminderType.medicamento);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lembrete permite pausar, editar, excluir e desfazer', (
    tester,
  ) async {
    final dataSource = _ReminderDataSource()
      ..reminders.addAll([
        const PatientReminder(
          id: 'meal-1',
          type: PatientReminderType.refeicao,
          title: 'Café da manhã',
          time: TimeOfDay(hour: 8, minute: 0),
          isActive: true,
        ),
        const PatientReminder(
          id: 'med-2',
          type: PatientReminderType.medicamento,
          title: 'Vitamina D',
          time: TimeOfDay(hour: 9, minute: 0),
          isActive: true,
        ),
      ]);
    await pumpReminders(tester, dataSource: dataSource);

    final medicationCard = find.byKey(const ValueKey('reminder-med-2'));
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
    expect(
      dataSource.reminders.firstWhere((r) => r.id == 'med-2').isActive,
      isFalse,
    );

    var mealCard = find.byKey(const ValueKey('reminder-meal-1'));
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
    expect(find.text('Lembrete atualizado.'), findsOneWidget);
    expect(
      dataSource.reminders.firstWhere((r) => r.id == 'meal-1').title,
      'Desjejum',
    );

    mealCard = find.byKey(const ValueKey('reminder-meal-1'));
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
    expect(dataSource.reminders, hasLength(1));

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(find.text('Desjejum'), findsOneWidget);
    expect(dataSource.reminders, hasLength(2));
    expect(dataSource.reminders.last.title, 'Desjejum');
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha ao carregar lembretes oferece nova tentativa', (
    tester,
  ) async {
    final dataSource = _ReminderDataSource(loadError: Exception('falha'));
    await pumpReminders(tester, dataSource: dataSource);

    expect(find.byKey(const Key('reminders-error')), findsOneWidget);
    dataSource.loadError = null;
    await tester.tap(find.byKey(const Key('reminders-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminders-error')), findsNothing);
    expect(find.text('Nenhum lembrete de refeições.'), findsOneWidget);
  });

  testWidgets('falha ao salvar lembrete informa o erro sem fechar a tela', (
    tester,
  ) async {
    final dataSource = _ReminderDataSource(saveError: Exception('falha'));
    await pumpReminders(tester, dataSource: dataSource);

    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar lembrete'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-title-field')),
      'Almoço',
    );
    await _tapVisible(tester, find.byKey(const Key('reminder-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
    expect(find.byKey(const Key('reminder-title-field')), findsOneWidget);
    expect(dataSource.reminders, isEmpty);
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

class _ReminderDataSource implements ReminderDataSource {
  _ReminderDataSource({this.loadError, this.saveError});

  final List<PatientReminder> reminders = [];
  Object? loadError;
  Object? saveError;

  @override
  Future<List<PatientReminder>> listCurrentUserReminders() async {
    if (loadError != null) {
      throw loadError!;
    }
    return List.of(reminders);
  }

  @override
  Future<PatientReminder> createReminder({
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
    bool isActive = true,
  }) async {
    if (saveError != null) {
      throw saveError!;
    }
    final reminder = PatientReminder(
      id: 'generated-${reminders.length}',
      type: type,
      title: title,
      time: time,
      isActive: isActive,
    );
    reminders.add(reminder);
    return reminder;
  }

  @override
  Future<void> updateReminder({
    required String id,
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
  }) async {
    if (saveError != null) {
      throw saveError!;
    }
    final index = reminders.indexWhere((item) => item.id == id);
    reminders[index] = PatientReminder(
      id: id,
      type: type,
      title: title,
      time: time,
      isActive: reminders[index].isActive,
    );
  }

  @override
  Future<void> setReminderActive({
    required String id,
    required bool isActive,
  }) async {
    final index = reminders.indexWhere((item) => item.id == id);
    final current = reminders[index];
    reminders[index] = PatientReminder(
      id: current.id,
      type: current.type,
      title: current.title,
      time: current.time,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((item) => item.id == id);
  }
}
