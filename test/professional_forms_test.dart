import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_care_plan_view.dart';
import 'package:iris/features/professional/presentation/professional_dashboard_view.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
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
    final store = await _createStore();
    addTearDown(store.dispose);
    final initialCount = store.appointments.length;

    await pumpScreen(
      tester,
      ProfessionalDashboardView(
        store: store,
        onOpenPatients: () {},
        onOpenPatient: (_) {},
        appointmentInitialDate: DateTime.now().add(const Duration(days: 1)),
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

  testWidgets('exige QR Code para vincular paciente', (tester) async {
    final store = await _createStore();
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

    expect(
      find.text('Use o QR Code para vincular um novo paciente.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('salva nova anotacao na lista', (tester) async {
    final store = await _createStore();
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
    final store = await _createStore();
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
    final store = await _createStore();
    addTearDown(store.dispose);

    await pumpScreen(tester, ProfessionalSettingsView(store: store));
    await tester.enterText(find.byType(TextFormField).first, 'Júlia Almeida');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(store.settings.name, 'Júlia Almeida');
  });
}

Future<ProfessionalFrontendStore> _createStore() async {
  final store = ProfessionalFrontendStore.connected(_FormBackend());
  await store.initialize();
  return store;
}

class _FormBackend implements ProfessionalWorkspaceBackend {
  static const patient = ProfessionalPatient(
    id: 'patient-id',
    linkId: 'link-id',
    name: 'Paciente Teste',
    age: 30,
    diagnosis: 'Diagnóstico inicial',
    lastActivity: 'Hoje',
    status: PatientStatus.active,
    mood: 'Bem',
    email: 'paciente@example.com',
    phone: '(11) 99999-9999',
    birthDate: '01/01/1996',
    nextAppointment: 'A definir',
  );

  @override
  Future<ProfessionalWorkspaceSnapshot> loadWorkspace() async {
    return const ProfessionalWorkspaceSnapshot(
      patients: [patient],
      appointments: [],
      notes: [],
      carePlans: {},
      records: {},
      settings: ProfessionalSettingsDraft(
        name: 'Profissional Teste',
        email: 'profissional@example.com',
        phone: '(11) 99999-0000',
        specialty: 'Psiquiatria',
        registration: 'CRM 123',
        biography: 'Biografia de teste',
        clinic: 'Clínica Teste',
        clinicAddress: 'Endereço de teste',
        avatarInitials: 'PT',
        appointmentNotifications: true,
        crisisAlerts: true,
        automaticReports: false,
      ),
      appointmentsThisMonth: 0,
      alerts: 0,
    );
  }

  @override
  Future<ProfessionalPatient> updatePatient(
    ProfessionalPatient patient,
  ) async => patient;

  @override
  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  ) async => appointment.copyWith(id: 'appointment-id');

  @override
  Future<void> removeAppointment(ProfessionalAppointment appointment) async {}

  @override
  Future<ProfessionalClinicalNote> addNote(
    ProfessionalClinicalNote note,
  ) async => note;

  @override
  Future<ProfessionalClinicalNote> updateNote(
    ProfessionalClinicalNote note,
  ) async => note;

  @override
  Future<void> removeNote(String noteId) async {}

  @override
  Future<ProfessionalCarePlanDraft> saveCarePlan(
    ProfessionalPatient patient,
    ProfessionalCarePlanDraft plan,
  ) async => plan;

  @override
  Future<ProfessionalSettingsDraft> updateSettings(
    ProfessionalSettingsDraft settings,
  ) async => settings;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}
