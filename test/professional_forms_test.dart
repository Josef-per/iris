import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_care_plan_view.dart';
import 'package:iris/features/professional/presentation/professional_dashboard_view.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_notes_view.dart';
import 'package:iris/features/professional/presentation/professional_settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('adiciona consulta pelo dashboard', (tester) async {
    final store = ProfessionalFrontendStore.seeded();
    addTearDown(store.dispose);
    final initialCount = store.appointments.length;

    await pumpScreen(
      tester,
      ProfessionalDashboardView(
        store: store,
        onOpenPatients: () {},
        onOpenPatient: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('professional-add-appointment')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('professional-appointment-time')),
      '09:30',
    );
    await tester.tap(find.byKey(const Key('professional-appointment-save')));
    await tester.pumpAndSettle();

    expect(store.appointments.length, initialCount + 1);
    expect(store.appointments.first.time, '09:30');
  });

  testWidgets('adiciona paciente com formulario completo', (tester) async {
    final store = ProfessionalFrontendStore.seeded();
    addTearDown(store.dispose);

    await pumpScreen(
      tester,
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => showProfessionalPatientForm(context, store),
          child: const Text('Abrir'),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Marina Lima');
    await tester.enterText(fields.at(1), '29');
    await tester.enterText(fields.at(2), 'Ansiedade');
    await tester.enterText(fields.at(3), 'marina@example.com');
    await tester.enterText(fields.at(4), '(11) 90000-0000');
    await tester.enterText(fields.at(5), '10/02/1997');
    await tester.enterText(fields.at(6), 'A definir');
    await tester.tap(find.byKey(const Key('professional-patient-save')));
    await tester.pumpAndSettle();

    expect(store.patients.first.name, 'Marina Lima');
  });

  testWidgets('salva nova anotacao na lista', (tester) async {
    final store = ProfessionalFrontendStore.seeded();
    addTearDown(store.dispose);
    final initialCount = store.notes.length;

    await pumpScreen(
      tester,
      ProfessionalNotesView(store: store, onOpenPatient: (_) {}),
    );
    await tester.tap(find.text('Nova anotação'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('professional-note-text')),
      'Paciente manteve boa adesão.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(store.notes.length, initialCount + 1);
    expect(store.notes.first.text, 'Paciente manteve boa adesão.');
  });

  testWidgets('adiciona meta ao plano de cuidado', (tester) async {
    final store = ProfessionalFrontendStore.seeded();
    addTearDown(store.dispose);

    await pumpScreen(
      tester,
      ProfessionalCarePlanView(
        store: store,
        initialPatient: store.patients.first,
        onOpenPatient: (_) {},
      ),
    );
    await tester.tap(find.byTooltip('Adicionar meta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('professional-text-item')),
      'Caminhar por 20 minutos',
    );
    await tester.tap(find.byKey(const Key('professional-text-item-save')));
    await tester.pumpAndSettle();

    expect(find.text('Caminhar por 20 minutos'), findsOneWidget);
  });

  testWidgets('salva dados do perfil profissional', (tester) async {
    final store = ProfessionalFrontendStore.seeded();
    addTearDown(store.dispose);

    await pumpScreen(tester, ProfessionalSettingsView(store: store));
    await tester.enterText(find.byType(TextFormField).first, 'Júlia Almeida');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(store.settings.name, 'Júlia Almeida');
  });
}
