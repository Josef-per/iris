import 'package:flutter/foundation.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';

class ProfessionalClinicalNote {
  const ProfessionalClinicalNote({
    required this.id,
    required this.patientId,
    required this.text,
    required this.date,
    required this.tag,
  });

  final String id;
  final String patientId;
  final String text;
  final String date;
  final String tag;

  ProfessionalClinicalNote copyWith({String? text, String? date, String? tag}) {
    return ProfessionalClinicalNote(
      id: id,
      patientId: patientId,
      text: text ?? this.text,
      date: date ?? this.date,
      tag: tag ?? this.tag,
    );
  }
}

class ProfessionalGoal {
  const ProfessionalGoal({
    required this.id,
    required this.text,
    this.completed = false,
  });

  final String id;
  final String text;
  final bool completed;

  ProfessionalGoal copyWith({String? text, bool? completed}) {
    return ProfessionalGoal(
      id: id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }
}

class ProfessionalCarePlanDraft {
  const ProfessionalCarePlanDraft({
    required this.goals,
    required this.orientation,
    required this.medications,
    required this.crisisSteps,
    required this.shareWithPatient,
    required this.notifyMissedCheckIns,
  });

  final List<ProfessionalGoal> goals;
  final String orientation;
  final List<ProfessionalMedication> medications;
  final List<String> crisisSteps;
  final bool shareWithPatient;
  final bool notifyMissedCheckIns;

  ProfessionalCarePlanDraft copyWith({
    List<ProfessionalGoal>? goals,
    String? orientation,
    List<ProfessionalMedication>? medications,
    List<String>? crisisSteps,
    bool? shareWithPatient,
    bool? notifyMissedCheckIns,
  }) {
    return ProfessionalCarePlanDraft(
      goals: goals ?? this.goals,
      orientation: orientation ?? this.orientation,
      medications: medications ?? this.medications,
      crisisSteps: crisisSteps ?? this.crisisSteps,
      shareWithPatient: shareWithPatient ?? this.shareWithPatient,
      notifyMissedCheckIns: notifyMissedCheckIns ?? this.notifyMissedCheckIns,
    );
  }
}

class ProfessionalSettingsDraft {
  const ProfessionalSettingsDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.registration,
    required this.biography,
    required this.clinic,
    required this.clinicAddress,
    required this.avatarInitials,
    required this.appointmentNotifications,
    required this.crisisAlerts,
    required this.automaticReports,
    this.credentialStatus = 'ativo',
  });

  final String name;
  final String email;
  final String phone;
  final String specialty;
  final String registration;
  final String biography;
  final String clinic;
  final String clinicAddress;
  final String avatarInitials;
  final bool appointmentNotifications;
  final bool crisisAlerts;
  final bool automaticReports;
  final String credentialStatus;

  ProfessionalSettingsDraft copyWith({
    String? name,
    String? email,
    String? phone,
    String? specialty,
    String? registration,
    String? biography,
    String? clinic,
    String? clinicAddress,
    String? avatarInitials,
    bool? appointmentNotifications,
    bool? crisisAlerts,
    bool? automaticReports,
    String? credentialStatus,
  }) {
    return ProfessionalSettingsDraft(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      registration: registration ?? this.registration,
      biography: biography ?? this.biography,
      clinic: clinic ?? this.clinic,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      appointmentNotifications:
          appointmentNotifications ?? this.appointmentNotifications,
      crisisAlerts: crisisAlerts ?? this.crisisAlerts,
      automaticReports: automaticReports ?? this.automaticReports,
      credentialStatus: credentialStatus ?? this.credentialStatus,
    );
  }
}

class ProfessionalWorkspaceSnapshot {
  const ProfessionalWorkspaceSnapshot({
    required this.patients,
    required this.appointments,
    required this.notes,
    required this.carePlans,
    required this.records,
    required this.settings,
    required this.appointmentsThisMonth,
    required this.alerts,
  });

  final List<ProfessionalPatient> patients;
  final List<ProfessionalAppointment> appointments;
  final List<ProfessionalClinicalNote> notes;
  final Map<String, ProfessionalCarePlanDraft> carePlans;
  final Map<String, List<ProfessionalRecord>> records;
  final ProfessionalSettingsDraft settings;
  final int appointmentsThisMonth;
  final int alerts;
}

abstract interface class ProfessionalWorkspaceBackend {
  Future<ProfessionalWorkspaceSnapshot> loadWorkspace();

  Future<ProfessionalPatient> updatePatient(ProfessionalPatient patient);

  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  );

  Future<void> removeAppointment(ProfessionalAppointment appointment);

  Future<ProfessionalClinicalNote> addNote(ProfessionalClinicalNote note);

  Future<ProfessionalClinicalNote> updateNote(ProfessionalClinicalNote note);

  Future<void> removeNote(String noteId);

  Future<ProfessionalCarePlanDraft> saveCarePlan(
    ProfessionalPatient patient,
    ProfessionalCarePlanDraft plan,
  );

  Future<ProfessionalSettingsDraft> updateSettings(
    ProfessionalSettingsDraft settings,
  );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class ProfessionalFrontendStore extends ChangeNotifier {
  ProfessionalFrontendStore.seeded()
    : _backend = null,
      _patients = [...ProfessionalMockData.patients],
      _appointments = [...ProfessionalMockData.appointments],
      _notes = _seedNotes(),
      _settings = _seedSettings(),
      _isLoading = false,
      _appointmentsThisMonth = 42,
      _alerts = 0;

  ProfessionalFrontendStore.connected(ProfessionalWorkspaceBackend backend)
    : _backend = backend,
      _patients = [],
      _appointments = [],
      _notes = [],
      _settings = _emptySettings(),
      _isLoading = true,
      _appointmentsThisMonth = 0,
      _alerts = 0;

  ProfessionalFrontendStore.remote(ProfessionalWorkspaceBackend backend)
    : this.connected(backend);

  final ProfessionalWorkspaceBackend? _backend;
  final List<ProfessionalPatient> _patients;
  final List<ProfessionalAppointment> _appointments;
  final List<ProfessionalClinicalNote> _notes;
  final Map<String, ProfessionalCarePlanDraft> _carePlans = {};
  final Map<String, List<ProfessionalRecord>> _records = {};

  ProfessionalSettingsDraft _settings;
  bool _isLoading;
  int _pendingMutations = 0;
  int _loadGeneration = 0;
  Object? _loadError;
  int _appointmentsThisMonth;
  int _alerts;

  bool get isConnected => _backend != null;
  bool get isRemote => isConnected;
  bool get isLoading => _isLoading;
  bool get isSaving => _pendingMutations > 0;
  Object? get loadError => _loadError;
  int get appointmentsThisMonth => _appointmentsThisMonth;
  int get alerts => _alerts;
  List<ProfessionalPatient> get patients => List.unmodifiable(_patients);
  List<ProfessionalAppointment> get appointments =>
      List.unmodifiable(_appointments);
  List<ProfessionalClinicalNote> get notes => List.unmodifiable(_notes);
  ProfessionalSettingsDraft get settings => _settings;

  Future<void> initialize() async {
    final backend = _backend;
    if (backend == null) return;

    final generation = ++_loadGeneration;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final snapshot = await backend.loadWorkspace();
      if (generation != _loadGeneration) return;
      _patients
        ..clear()
        ..addAll(snapshot.patients);
      _appointments
        ..clear()
        ..addAll(snapshot.appointments);
      _notes
        ..clear()
        ..addAll(snapshot.notes);
      _carePlans
        ..clear()
        ..addAll(snapshot.carePlans);
      _records
        ..clear()
        ..addAll(snapshot.records);
      _settings = snapshot.settings;
      _appointmentsThisMonth = snapshot.appointmentsThisMonth;
      _alerts = snapshot.alerts;
    } catch (error) {
      if (generation == _loadGeneration) _loadError = error;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => initialize();

  ProfessionalPatient? patientByIdOrNull(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  ProfessionalPatient? findPatientById(String id) => patientByIdOrNull(id);

  ProfessionalPatient patientById(String id) {
    final patient = patientByIdOrNull(id);
    if (patient == null) {
      throw StateError('Paciente não encontrado.');
    }
    return patient;
  }

  List<ProfessionalRecord> recordsFor(String patientId) {
    if (!isConnected) return ProfessionalMockData.records;
    return List.unmodifiable(_records[patientId] ?? const []);
  }

  Future<void> addPatient(ProfessionalPatient patient) async {
    if (isConnected) {
      throw StateError('Use um convite QR para vincular o paciente.');
    }
    _patients.insert(0, patient);
    notifyListeners();
  }

  Future<void> updatePatient(ProfessionalPatient patient) async {
    final saved = await _mutate(
      () => _backend?.updatePatient(patient) ?? Future.value(patient),
    );
    final index = _patients.indexWhere((item) => item.id == saved.id);
    if (index == -1) return;
    _patients[index] = saved;
    for (
      var appointmentIndex = 0;
      appointmentIndex < _appointments.length;
      appointmentIndex++
    ) {
      final appointment = _appointments[appointmentIndex];
      if (appointment.patient.id != saved.id) continue;
      _appointments[appointmentIndex] = appointment.copyWith(patient: saved);
    }
    notifyListeners();
  }

  Future<void> addAppointment(ProfessionalAppointment appointment) async {
    final saved = await _mutate(
      () => _backend?.addAppointment(appointment) ?? Future.value(appointment),
    );
    _appointments.add(saved);
    if (_isInCurrentMonth(saved.startsAt)) {
      _appointmentsThisMonth++;
    }
    _sortAppointments();
    notifyListeners();
  }

  Future<void> removeAppointment(ProfessionalAppointment appointment) async {
    await _mutate(
      () => _backend?.removeAppointment(appointment) ?? Future.value(),
    );
    final existed = _appointments.any(
      (item) => item.id != null && appointment.id != null
          ? item.id == appointment.id
          : identical(item, appointment),
    );
    _appointments.removeWhere(
      (item) => item.id != null && appointment.id != null
          ? item.id == appointment.id
          : identical(item, appointment),
    );
    if (existed &&
        _appointmentsThisMonth > 0 &&
        _isInCurrentMonth(appointment.startsAt)) {
      _appointmentsThisMonth--;
    }
    notifyListeners();
  }

  Future<void> addNote(ProfessionalClinicalNote note) async {
    final saved = await _mutate(
      () => _backend?.addNote(note) ?? Future.value(note),
    );
    _notes.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateNote(ProfessionalClinicalNote note) async {
    final saved = await _mutate(
      () => _backend?.updateNote(note) ?? Future.value(note),
    );
    final index = _notes.indexWhere((item) => item.id == saved.id);
    if (index == -1) return;
    _notes[index] = saved;
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    await _mutate(() => _backend?.removeNote(id) ?? Future.value());
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  ProfessionalCarePlanDraft carePlanFor(String patientId) {
    return _carePlans.putIfAbsent(
      patientId,
      isConnected ? _emptyCarePlan : _seedCarePlan,
    );
  }

  Future<void> updateCarePlan(
    String patientId,
    ProfessionalCarePlanDraft draft,
  ) async {
    final patient = patientById(patientId);
    final saved = await _mutate(
      () => _backend?.saveCarePlan(patient, draft) ?? Future.value(draft),
    );
    _carePlans[patientId] = saved;
    notifyListeners();
  }

  Future<void> updateSettings(ProfessionalSettingsDraft settings) async {
    _settings = await _mutate(
      () => _backend?.updateSettings(settings) ?? Future.value(settings),
    );
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _mutate(
      () =>
          _backend?.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ) ??
          Future.value(),
    );
  }

  Future<T> _mutate<T>(Future<T> Function() operation) async {
    _pendingMutations++;
    notifyListeners();
    try {
      return await operation();
    } finally {
      _pendingMutations--;
      notifyListeners();
    }
  }

  void _sortAppointments() {
    _appointments.sort((a, b) {
      final aDate = a.startsAt;
      final bDate = b.startsAt;
      if (aDate != null && bDate != null) return aDate.compareTo(bDate);
      return a.time.compareTo(b.time);
    });
  }

  bool _isInCurrentMonth(DateTime? value) {
    if (value == null) return false;
    final local = value.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month;
  }

  static List<ProfessionalClinicalNote> _seedNotes() {
    return [
      ProfessionalClinicalNote(
        id: 'note-1',
        patientId: ProfessionalMockData.patients[0].id,
        text: 'Melhora na rotina do café da manhã. Revisar o sono.',
        date: 'Hoje, 11:40',
        tag: 'Evolução',
      ),
      ProfessionalClinicalNote(
        id: 'note-2',
        patientId: ProfessionalMockData.patients[2].id,
        text: 'Reavaliar episódios noturnos e a prevenção de recaída.',
        date: 'Ontem, 17:10',
        tag: 'Atenção',
      ),
      ProfessionalClinicalNote(
        id: 'note-3',
        patientId: ProfessionalMockData.patients[1].id,
        text: 'Boa adesão ao plano de cuidado no fim de semana.',
        date: '25 jul, 15:30',
        tag: 'Evolução',
      ),
    ];
  }

  static ProfessionalSettingsDraft _seedSettings() {
    return const ProfessionalSettingsDraft(
      name: 'Júlia Souza',
      email: 'julia.souza@exemplo.com',
      phone: '(11) 98765-4300',
      specialty: 'Psiquiatria · Transtornos alimentares',
      registration: 'CRM/SP 123456',
      biography:
          'Psiquiatra com foco em transtornos alimentares e cuidado integrado.',
      clinic: 'Clínica Horizonte',
      clinicAddress: 'Av. Paulista, 1000 · São Paulo, SP',
      avatarInitials: 'JS',
      appointmentNotifications: true,
      crisisAlerts: true,
      automaticReports: false,
    );
  }

  static ProfessionalSettingsDraft _emptySettings() {
    return const ProfessionalSettingsDraft(
      name: 'Profissional',
      email: '',
      phone: '',
      specialty: '',
      registration: '',
      biography: '',
      clinic: '',
      clinicAddress: '',
      avatarInitials: 'PR',
      appointmentNotifications: true,
      crisisAlerts: true,
      automaticReports: false,
      credentialStatus: 'pendente',
    );
  }

  static ProfessionalCarePlanDraft _emptyCarePlan() {
    return const ProfessionalCarePlanDraft(
      goals: [],
      orientation: '',
      medications: [],
      crisisSteps: [],
      shareWithPatient: true,
      notifyMissedCheckIns: true,
    );
  }

  static ProfessionalCarePlanDraft _seedCarePlan() {
    return ProfessionalCarePlanDraft(
      goals: const [
        ProfessionalGoal(
          id: 'goal-1',
          text: 'Realizar 3 refeições principais',
          completed: true,
        ),
        ProfessionalGoal(
          id: 'goal-2',
          text: 'Registrar o humor diariamente',
          completed: true,
        ),
        ProfessionalGoal(
          id: 'goal-3',
          text: 'Seguir os horários da medicação',
          completed: true,
        ),
        ProfessionalGoal(
          id: 'goal-4',
          text: 'Usar respiração guiada em crises',
        ),
      ],
      orientation:
          'Manter refeições estruturadas e registrar emoções nas refeições.',
      medications: [...ProfessionalMockData.medications],
      crisisSteps: const [
        'Acionar contato de confiança',
        'Usar respiração guiada',
        'Buscar urgência em caso de risco',
      ],
      shareWithPatient: true,
      notifyMissedCheckIns: true,
    );
  }
}
