import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';

void main() {
  group('ProfessionalFrontendStore conectado', () {
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
  ) async => settings;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}
