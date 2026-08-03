import 'package:flutter/foundation.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Signals that the profile/settings transaction was persisted, but the
/// separate Supabase Auth update (for example, changing the login e-mail)
/// failed or is still awaiting confirmation.
class ProfessionalSettingsPartialUpdateException implements Exception {
  const ProfessionalSettingsPartialUpdateException({
    required this.persistedSettings,
    required this.message,
  });

  final ProfessionalSettingsDraft persistedSettings;
  final String message;

  @override
  String toString() => message;
}

class ProfessionalClinicalAlert {
  const ProfessionalClinicalAlert({
    required this.id,
    required this.patientId,
    required this.occurredAt,
    required this.reasons,
  });

  final String id;
  final String patientId;
  final DateTime occurredAt;
  final List<String> reasons;

  String get summary => reasons.join(' · ');
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
    this.clinicalAlerts = const [],
  });

  final List<ProfessionalPatient> patients;
  final List<ProfessionalAppointment> appointments;
  final List<ProfessionalClinicalNote> notes;
  final Map<String, ProfessionalCarePlanDraft> carePlans;
  final Map<String, List<ProfessionalRecord>> records;
  final ProfessionalSettingsDraft settings;
  final int appointmentsThisMonth;
  final int alerts;
  final List<ProfessionalClinicalAlert> clinicalAlerts;
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

  final ProfessionalWorkspaceBackend _backend;
  final List<ProfessionalPatient> _patients;
  final List<ProfessionalAppointment> _appointments;
  final List<ProfessionalClinicalNote> _notes;
  final Map<String, ProfessionalCarePlanDraft> _carePlans = {};
  final Map<String, List<ProfessionalRecord>> _records = {};
  final List<ProfessionalClinicalAlert> _clinicalAlerts = [];

  ProfessionalSettingsDraft _settings;
  bool _isLoading;
  int _pendingMutations = 0;
  int _loadGeneration = 0;
  Object? _loadError;
  int _appointmentsThisMonth;
  int _alerts;

  bool get isConnected => true;
  bool get isRemote => true;
  bool get isLoading => _isLoading;
  bool get isSaving => _pendingMutations > 0;
  Object? get loadError => _loadError;
  int get appointmentsThisMonth => _appointmentsThisMonth;
  int get alerts => _alerts;
  List<ProfessionalClinicalAlert> get clinicalAlerts =>
      List.unmodifiable(_clinicalAlerts);
  List<ProfessionalPatient> get patients => List.unmodifiable(_patients);
  List<ProfessionalAppointment> get appointments =>
      List.unmodifiable(_appointments);
  List<ProfessionalClinicalNote> get notes => List.unmodifiable(_notes);
  ProfessionalSettingsDraft get settings => _settings;

  Future<void> initialize() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final snapshot = await _backend.loadWorkspace();
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
      _clinicalAlerts
        ..clear()
        ..addAll(snapshot.clinicalAlerts);
      _settings = snapshot.settings;
      _appointmentsThisMonth = snapshot.appointmentsThisMonth;
      _alerts = snapshot.alerts;
    } catch (error) {
      if (generation == _loadGeneration) {
        _loadError = error;
        if (_isAuthorizationError(error)) _clearWorkspaceData();
      }
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
    return List.unmodifiable(_records[patientId] ?? const []);
  }

  Future<void> addPatient(ProfessionalPatient patient) async {
    throw StateError('Use um convite QR para vincular o paciente.');
  }

  Future<void> updatePatient(ProfessionalPatient patient) async {
    final previous = patientByIdOrNull(patient.id);
    final saved = await _mutate(() => _backend.updatePatient(patient));
    _replacePatient(saved);
    if (previous?.status == PatientStatus.active &&
        saved.status == PatientStatus.inactive) {
      _purgeClinicalDataFor(saved.id);
    }
    notifyListeners();
    if (previous != null && previous.status != saved.status) {
      await initialize();
    }
  }

  Future<void> addAppointment(ProfessionalAppointment appointment) async {
    final saved = await _mutate(() => _backend.addAppointment(appointment));
    _appointments.add(saved);
    if (_isInCurrentMonth(saved.startsAt)) {
      _appointmentsThisMonth++;
    }
    _sortAppointments();
    _refreshNextAppointment(saved.patient.id);
    notifyListeners();
  }

  Future<void> removeAppointment(ProfessionalAppointment appointment) async {
    await _mutate(() => _backend.removeAppointment(appointment));
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
    _refreshNextAppointment(appointment.patient.id);
    notifyListeners();
  }

  Future<void> addNote(ProfessionalClinicalNote note) async {
    final saved = await _mutate(() => _backend.addNote(note));
    _notes.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateNote(ProfessionalClinicalNote note) async {
    final saved = await _mutate(() => _backend.updateNote(note));
    final index = _notes.indexWhere((item) => item.id == saved.id);
    if (index == -1) return;
    _notes[index] = saved;
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    await _mutate(() => _backend.removeNote(id));
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  ProfessionalCarePlanDraft carePlanFor(String patientId) {
    return _carePlans.putIfAbsent(patientId, _emptyCarePlan);
  }

  Future<void> updateCarePlan(
    String patientId,
    ProfessionalCarePlanDraft draft,
  ) async {
    final patient = patientById(patientId);
    final saved = await _mutate(() => _backend.saveCarePlan(patient, draft));
    _carePlans[patientId] = saved;
    notifyListeners();
  }

  Future<void> updateSettings(ProfessionalSettingsDraft settings) async {
    try {
      _settings = await _mutate(() => _backend.updateSettings(settings));
      notifyListeners();
    } on ProfessionalSettingsPartialUpdateException catch (error) {
      _settings = error.persistedSettings;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _mutate(
      () => _backend.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  Future<T> _mutate<T>(Future<T> Function() operation) async {
    _pendingMutations++;
    notifyListeners();
    try {
      return await operation();
    } catch (error) {
      if (_isAuthorizationError(error)) {
        _clearWorkspaceData();
      }
      rethrow;
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

  void _replacePatient(ProfessionalPatient patient) {
    final index = _patients.indexWhere((item) => item.id == patient.id);
    if (index == -1) return;
    _patients[index] = patient;
    for (var index = 0; index < _appointments.length; index++) {
      final appointment = _appointments[index];
      if (appointment.patient.id != patient.id) continue;
      _appointments[index] = appointment.copyWith(patient: patient);
    }
  }

  void _refreshNextAppointment(String patientId) {
    final patient = patientByIdOrNull(patientId);
    if (patient == null) return;
    final upcoming =
        _appointments
            .where(
              (item) =>
                  item.patient.id == patientId &&
                  item.startsAt != null &&
                  item.startsAt!.isAfter(DateTime.now()),
            )
            .toList(growable: false)
          ..sort((left, right) => left.startsAt!.compareTo(right.startsAt!));
    final next = upcoming.isEmpty ? null : upcoming.first.startsAt!.toLocal();
    _replacePatient(
      patient.copyWith(
        nextAppointment: next == null
            ? 'Sem consulta'
            : _formatAppointment(next),
      ),
    );
  }

  void _purgeClinicalDataFor(String patientId) {
    _notes.removeWhere((note) => note.patientId == patientId);
    _carePlans.remove(patientId);
    _records.remove(patientId);
    _clinicalAlerts.removeWhere((alert) => alert.patientId == patientId);
    final removedAppointments = _appointments
        .where((appointment) => appointment.patient.id == patientId)
        .toList(growable: false);
    _appointments.removeWhere(
      (appointment) => appointment.patient.id == patientId,
    );
    for (final appointment in removedAppointments) {
      if (_appointmentsThisMonth > 0 &&
          _isInCurrentMonth(appointment.startsAt)) {
        _appointmentsThisMonth--;
      }
    }
    _alerts = _clinicalAlerts.length;
    final patient = patientByIdOrNull(patientId);
    if (patient != null) {
      _replacePatient(patient.copyWith(nextAppointment: 'Sem consulta'));
    }
  }

  void _clearWorkspaceData() {
    _patients.clear();
    _appointments.clear();
    _notes.clear();
    _carePlans.clear();
    _records.clear();
    _clinicalAlerts.clear();
    _appointmentsThisMonth = 0;
    _alerts = 0;
  }

  bool _isInCurrentMonth(DateTime? value) {
    if (value == null) return false;
    final local = value.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month;
  }

  bool _isAuthorizationError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      return error is AuthSessionMissingException ||
          error.statusCode == '401' ||
          error.statusCode == '403' ||
          error.code == 'refresh_token_not_found' ||
          message.contains('jwt') ||
          message.contains('session missing');
    }
    if (error is PostgrestException) {
      return error.code == '42501' ||
          error.code == 'PGRST301' ||
          error.message.toLowerCase().contains('jwt') ||
          error.message.toLowerCase().contains('row-level security') ||
          error.message.toLowerCase().contains('link_access_denied');
    }
    final message = error.toString().toLowerCase();
    return message.contains('link_access_denied') ||
        message.contains('permission denied');
  }

  String _formatAppointment(DateTime date) {
    final now = DateTime.now();
    final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    if (_sameDay(date, now)) return 'Hoje, $time';
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (_sameDay(date, tomorrow)) return 'Amanhã, $time';
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}, $time';
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

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
}
