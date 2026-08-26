class PatientCarePlan {
  const PatientCarePlan({
    required this.id,
    required this.guidance,
    required this.crisisSteps,
    required this.goals,
    required this.medications,
    required this.updatedAt,
  });

  final String id;
  final String? guidance;
  final List<String> crisisSteps;
  final List<PatientCareGoal> goals;
  final List<PatientCareMedication> medications;
  final DateTime updatedAt;
}

class PatientCareGoal {
  const PatientCareGoal({
    required this.id,
    required this.description,
    required this.isCompleted,
  });

  final String id;
  final String description;
  final bool isCompleted;
}

class PatientCareMedication {
  const PatientCareMedication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    this.adherence = 1,
  });

  final String id;
  final String name;
  final String dose;
  final String frequency;
  final double adherence;
}
