import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/data/supabase_professional_workspace_backend.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/screens/professional_home_screen.dart';

void main() {
  group('ProfessionalFrontendStore conectado', () {
    test('mantem mutavel a lista vazia de dados relacionados', () async {
      var loaderCalls = 0;
      final rows = await loadProfessionalWorkspaceRowsByChunks(const [], (
        _,
        _,
        _,
      ) async {
        loaderCalls++;
        throw StateError('O loader não deve ser chamado sem IDs.');
      });

      rows.sort((_, _) => 0);

      expect(rows, isEmpty);
      expect(loaderCalls, 0);
    });

    test('carrega workspace vazio sem recorrer aos mocks', () async {
      final backend = _FakeProfessionalBackend();
      final store = ProfessionalFrontendStore.connected(backend);

      expect(store.isLoading, isTrue);
      expect(store.patients, isEmpty);

      await store.initialize();

      expect(store.isLoading, isFalse);
      expect(store.loadError, isNull);
      expect(store.patients, isEmpty);
      expect(store.appointments, isEmpty);
    });

    test('expoe erro e permite tentar carregar novamente', () async {
      final backend = _FakeProfessionalBackend()
        ..loadError = StateError('offline');
      final store = ProfessionalFrontendStore.connected(backend);

      await store.initialize();
      expect(store.loadError, isA<StateError>());

      backend.loadError = null;
      await store.refresh();

      expect(store.loadError, isNull);
      expect(backend.loadCalls, 2);
    });

    test('mantem patientId e linkId distintos na mutacao', () async {
      final patient = _patient();
      final backend = _FakeProfessionalBackend(
        snapshot: _snapshot(patients: [patient]),
      );
      final store = ProfessionalFrontendStore.connected(backend);
      await store.initialize();

      await store.updatePatient(
        patient.copyWith(diagnosis: 'Diagnóstico atualizado'),
      );

      expect(backend.updatedPatient?.id, 'patient-id');
      expect(backend.updatedPatient?.linkId, 'link-id');
      expect(store.patients.single.diagnosis, 'Diagnóstico atualizado');
    });

    test('falha de mutacao nao corrompe o estado local', () async {
      final patient = _patient();
      final backend = _FakeProfessionalBackend(
        snapshot: _snapshot(patients: [patient]),
      )..updateError = StateError('sem permissao');
      final store = ProfessionalFrontendStore.connected(backend);
      await store.initialize();

      await expectLater(
        store.updatePatient(patient.copyWith(diagnosis: 'Não salvar')),
        throwsStateError,
      );

      expect(store.patients.single.diagnosis, patient.diagnosis);
      expect(store.isSaving, isFalse);
    });

    test('preserva id e data da consulta ao atualizar o paciente', () async {
      final patient = _patient();
      final startsAt = DateTime(2026, 8, 2, 14, 30);
      final appointment = ProfessionalAppointment(
        id: 'appointment-id',
        startsAt: startsAt,
        time: '14:30',
        patient: patient,
        type: 'Online',
      );
      final backend = _FakeProfessionalBackend(
        snapshot: _snapshot(patients: [patient], appointments: [appointment]),
      );
      final store = ProfessionalFrontendStore.connected(backend);
      await store.initialize();

      await store.updatePatient(patient.copyWith(mood: 'Bem'));

      expect(store.appointments.single.id, 'appointment-id');
      expect(store.appointments.single.startsAt, startsAt);
      expect(store.appointments.single.patient.mood, 'Bem');
    });

    test('recalcula a proxima consulta apos criar e remover', () async {
      final patient = _patient();
      final backend = _FakeProfessionalBackend(
        snapshot: _snapshot(patients: [patient]),
      );
      final store = ProfessionalFrontendStore.connected(backend);
      await store.initialize();
      final appointment = ProfessionalAppointment(
        startsAt: DateTime.now().add(const Duration(days: 2)),
        time: '14:30',
        patient: patient,
        type: 'Online',
      );

      await store.addAppointment(appointment);
      expect(store.patients.single.nextAppointment, isNot('A definir'));

      await store.removeAppointment(store.appointments.single);
      expect(store.patients.single.nextAppointment, 'Sem consulta');
    });

    test(
      'reconcilia configuracoes quando o auth falha apos o perfil',
      () async {
        final persisted = _snapshot().settings.copyWith(
          name: 'Nome persistido',
          email: 'email-atual@example.com',
        );
        final backend = _FakeProfessionalBackend()
          ..settingsError = ProfessionalSettingsPartialUpdateException(
            persistedSettings: persisted,
            message: 'Confirme o novo e-mail.',
          );
        final store = ProfessionalFrontendStore.connected(backend);
        await store.initialize();

        await expectLater(
          store.updateSettings(
            store.settings.copyWith(email: 'novo@example.com'),
          ),
          throwsA(isA<ProfessionalSettingsPartialUpdateException>()),
        );

        expect(store.settings.name, 'Nome persistido');
        expect(store.settings.email, 'email-atual@example.com');
      },
    );

    testWidgets('nao mostra credenciamento pendente quando a carga falha', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = _FakeProfessionalBackend()
        ..loadError = StateError('offline');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProfessionalHomeScreen(backend: backend),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar seus dados'), findsOneWidget);
      expect(
        find.textContaining('Seu cadastro profissional está em análise'),
        findsNothing,
      );
    });
  });
}

ProfessionalPatient _patient() {
  return const ProfessionalPatient(
    id: 'patient-id',
    linkId: 'link-id',
    name: 'Paciente Teste',
    age: 30,
    diagnosis: 'Diagnóstico inicial',
    lastActivity: 'Hoje',
    status: PatientStatus.active,
    mood: 'Regular',
    email: 'paciente@example.com',
    phone: '(11) 99999-9999',
    birthDate: '01/01/1996',
    nextAppointment: 'A definir',
  );
}

ProfessionalWorkspaceSnapshot _snapshot({
  List<ProfessionalPatient> patients = const [],
  List<ProfessionalAppointment> appointments = const [],
}) {
  return ProfessionalWorkspaceSnapshot(
    patients: patients,
    appointments: appointments,
    notes: const [],
    carePlans: const {},
    records: const {},
    settings: const ProfessionalSettingsDraft(
      name: 'Profissional Teste',
      email: 'profissional@example.com',
      phone: '',
      specialty: 'Psiquiatria',
      registration: 'CRM 123',
      biography: '',
      clinic: '',
      clinicAddress: '',
      avatarInitials: 'PT',
      appointmentNotifications: true,
      crisisAlerts: true,
      automaticReports: false,
    ),
    appointmentsThisMonth: 0,
    alerts: 0,
  );
}

class _FakeProfessionalBackend implements ProfessionalWorkspaceBackend {
  _FakeProfessionalBackend({ProfessionalWorkspaceSnapshot? snapshot})
    : snapshot = snapshot ?? _snapshot();

  ProfessionalWorkspaceSnapshot snapshot;
  Object? loadError;
  Object? updateError;
  Object? settingsError;
  int loadCalls = 0;
  ProfessionalPatient? updatedPatient;

  @override
  Future<ProfessionalWorkspaceSnapshot> loadWorkspace() async {
    loadCalls++;
    if (loadError case final error?) throw error;
    return snapshot;
  }

  @override
  Future<ProfessionalPatient> updatePatient(ProfessionalPatient patient) async {
    if (updateError case final error?) throw error;
    updatedPatient = patient;
    return patient;
  }

  @override
  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  ) async => appointment;

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
  ) async {
    if (settingsError case final error?) throw error;
    return settings;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}
