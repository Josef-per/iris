import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/navigation/professional_destination.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_dashboard_view.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/screens/professional_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'agenda profissional é nativa, seleciona um dia e não estoura em 320 px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wednesday = DateTime(2026, 8, 12, 9);
      final thursday = DateTime(2026, 8, 13, 14, 30);
      final store = ProfessionalFrontendStore.connected(
        _AgendaBackend(
          appointments: [
            ProfessionalAppointment(
              id: 'quarta',
              startsAt: wednesday,
              time: '09:00',
              patient: _AgendaBackend.patientWednesday,
              type: 'Online',
            ),
            ProfessionalAppointment(
              id: 'quinta',
              startsAt: thursday,
              time: '14:30',
              patient: _AgendaBackend.patientThursday,
              type: 'Presencial',
            ),
          ],
        ),
      );
      addTearDown(store.dispose);
      await store.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProfessionalDashboardView(
              store: store,
              appointmentInitialDate: wednesday,
              onOpenPatients: () {},
              onOpenPatient: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Agenda semanal'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(RawImage), findsNothing);
      expect(find.text('Quarta, 12 de agosto'), findsOneWidget);
      expect(find.text('Paciente de quarta'), findsNWidgets(2));
      expect(find.text('Paciente de quinta'), findsOneWidget);

      final thursdayButton = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').startsWith('quinta, 13.'),
        description: 'botão semântico de quinta-feira, dia 13',
      );
      expect(thursdayButton, findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.tap(thursdayButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Quinta, 13 de agosto'), findsOneWidget);
      expect(find.text('Paciente de quarta'), findsOneWidget);
      expect(find.text('Paciente de quinta'), findsNWidgets(2));
    },
  );

  testWidgets('dias da agenda expõem seleção e quantidade semanticamente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selectedDay = DateTime(2026, 8, 12, 9);
    final store = ProfessionalFrontendStore.connected(
      _AgendaBackend(
        appointments: [
          ProfessionalAppointment(
            id: 'consulta',
            startsAt: selectedDay,
            time: '09:00',
            patient: _AgendaBackend.patientWednesday,
            type: 'Online',
          ),
        ],
      ),
    );
    addTearDown(store.dispose);
    await store.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfessionalDashboardView(
            store: store,
            appointmentInitialDate: selectedDay,
            onOpenPatients: () {},
            onOpenPatient: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label ?? '').startsWith('quarta, 12. 1 consulta'),
      description: 'dia selecionado com uma consulta',
    );
    final unselected = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label ?? '').startsWith('quinta, 13. 0 consultas'),
      description: 'dia não selecionado sem consultas',
    );

    expect(selected, findsOneWidget);
    expect(unselected, findsOneWidget);
    expect(tester.widget<Semantics>(selected).properties.selected, isTrue);
    expect(tester.widget<Semantics>(unselected).properties.selected, isFalse);
  });

  testWidgets('navegação profissional continua utilizável em 320 por 568', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfessionalNavigation(
            destination: ProfessionalDestination.dashboard,
            showingPatientDetail: false,
            onSelected: (_) {},
            onSignOut: () => signedOut = true,
            settings: const ProfessionalSettingsDraft(
              name: 'Profissional Teste',
              email: 'profissional@example.com',
              phone: '',
              specialty: 'Nutrição',
              registration: 'CRN 123',
              biography: '',
              clinic: '',
              clinicAddress: '',
              avatarInitials: 'PT',
              appointmentNotifications: true,
              crisisAlerts: true,
              automaticReports: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));

    expect(tester.takeException(), isNull);
    expect(signedOut, isTrue);
  });
}

class _AgendaBackend implements ProfessionalWorkspaceBackend {
  _AgendaBackend({required this.appointments});

  final List<ProfessionalAppointment> appointments;

  static const patientWednesday = ProfessionalPatient(
    id: 'paciente-quarta',
    linkId: 'link-quarta',
    name: 'Paciente de quarta',
    age: 28,
    diagnosis: 'Acompanhamento',
    lastActivity: 'Hoje',
    status: PatientStatus.active,
    mood: 'Bem',
    email: 'quarta@example.com',
    phone: '',
    birthDate: '01/01/1998',
    nextAppointment: '12/08 às 09:00',
  );

  static const patientThursday = ProfessionalPatient(
    id: 'paciente-quinta',
    linkId: 'link-quinta',
    name: 'Paciente de quinta',
    age: 32,
    diagnosis: 'Acompanhamento',
    lastActivity: 'Hoje',
    status: PatientStatus.active,
    mood: 'Regular',
    email: 'quinta@example.com',
    phone: '',
    birthDate: '01/01/1994',
    nextAppointment: '13/08 às 14:30',
  );

  @override
  Future<ProfessionalWorkspaceSnapshot> loadWorkspace() async {
    return ProfessionalWorkspaceSnapshot(
      patients: const [patientWednesday, patientThursday],
      appointments: appointments,
      notes: const [],
      carePlans: const {},
      records: const {},
      settings: const ProfessionalSettingsDraft(
        name: 'Profissional Teste',
        email: 'profissional@example.com',
        phone: '',
        specialty: 'Nutrição',
        registration: 'CRN 123',
        biography: '',
        clinic: '',
        clinicAddress: '',
        avatarInitials: 'PT',
        appointmentNotifications: true,
        crisisAlerts: true,
        automaticReports: false,
      ),
      appointmentsThisMonth: appointments.length,
      alerts: 0,
    );
  }

  @override
  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  ) async => appointment;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<ProfessionalClinicalNote> addNote(
    ProfessionalClinicalNote note,
  ) async => note;

  @override
  Future<void> removeAppointment(ProfessionalAppointment appointment) async {}

  @override
  Future<void> removeNote(String noteId) async {}

  @override
  Future<ProfessionalCarePlanDraft> saveCarePlan(
    ProfessionalPatient patient,
    ProfessionalCarePlanDraft plan,
  ) async => plan;

  @override
  Future<ProfessionalClinicalNote> updateNote(
    ProfessionalClinicalNote note,
  ) async => note;

  @override
  Future<ProfessionalPatient> updatePatient(
    ProfessionalPatient patient,
  ) async => patient;

  @override
  Future<ProfessionalSettingsDraft> updateSettings(
    ProfessionalSettingsDraft settings,
  ) async => settings;
}
