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
}

class ProfessionalFrontendStore extends ChangeNotifier {
  ProfessionalFrontendStore.seeded()
    : _patients = [...ProfessionalMockData.patients],
      _appointments = [...ProfessionalMockData.appointments],
      _notes = [
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

  final List<ProfessionalPatient> _patients;
  final List<ProfessionalAppointment> _appointments;
  final List<ProfessionalClinicalNote> _notes;
  final Map<String, ProfessionalCarePlanDraft> _carePlans = {};
  ProfessionalSettingsDraft _settings = const ProfessionalSettingsDraft(
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

  List<ProfessionalPatient> get patients => List.unmodifiable(_patients);
  List<ProfessionalAppointment> get appointments =>
      List.unmodifiable(_appointments);
  List<ProfessionalClinicalNote> get notes => List.unmodifiable(_notes);
  ProfessionalSettingsDraft get settings => _settings;

  ProfessionalPatient patientById(String id) {
    return _patients.firstWhere((patient) => patient.id == id);
  }

  void addPatient(ProfessionalPatient patient) {
    _patients.insert(0, patient);
    notifyListeners();
  }

  void updatePatient(ProfessionalPatient patient) {
    final index = _patients.indexWhere((item) => item.id == patient.id);
    if (index == -1) return;
    _patients[index] = patient;
    for (
      var appointmentIndex = 0;
      appointmentIndex < _appointments.length;
      appointmentIndex++
    ) {
      final appointment = _appointments[appointmentIndex];
      if (appointment.patient.id != patient.id) continue;
      _appointments[appointmentIndex] = ProfessionalAppointment(
        time: appointment.time,
        patient: patient,
        type: appointment.type,
      );
    }
    notifyListeners();
  }

  void addAppointment(ProfessionalAppointment appointment) {
    _appointments.add(appointment);
    _appointments.sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  void removeAppointment(ProfessionalAppointment appointment) {
    _appointments.remove(appointment);
    notifyListeners();
  }

  void addNote(ProfessionalClinicalNote note) {
    _notes.insert(0, note);
    notifyListeners();
  }

  void updateNote(ProfessionalClinicalNote note) {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index == -1) return;
    _notes[index] = note;
    notifyListeners();
  }

  void removeNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  ProfessionalCarePlanDraft carePlanFor(String patientId) {
    return _carePlans.putIfAbsent(patientId, _seedCarePlan);
  }

  void updateCarePlan(String patientId, ProfessionalCarePlanDraft draft) {
    _carePlans[patientId] = draft;
    notifyListeners();
  }

  void updateSettings(ProfessionalSettingsDraft settings) {
    _settings = settings;
    notifyListeners();
  }

  ProfessionalCarePlanDraft _seedCarePlan() {
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
