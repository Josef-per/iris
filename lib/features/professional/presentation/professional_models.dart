import 'package:flutter/material.dart';

enum ProfessionalDestination { dashboard, patients, notes, carePlan, settings }

enum PatientStatus { active, inactive }

class ProfessionalPatient {
  const ProfessionalPatient({
    required this.id,
    this.linkId,
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.lastActivity,
    required this.status,
    required this.mood,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.nextAppointment,
  });

  final String id;
  final String? linkId;
  final String name;
  final int age;
  final String diagnosis;
  final String lastActivity;
  final PatientStatus status;
  final String mood;
  final String email;
  final String phone;
  final String birthDate;
  final String nextAppointment;

  ProfessionalPatient copyWith({
    String? id,
    String? linkId,
    String? name,
    int? age,
    String? diagnosis,
    String? lastActivity,
    PatientStatus? status,
    String? mood,
    String? email,
    String? phone,
    String? birthDate,
    String? nextAppointment,
  }) {
    return ProfessionalPatient(
      id: id ?? this.id,
      linkId: linkId ?? this.linkId,
      name: name ?? this.name,
      age: age ?? this.age,
      diagnosis: diagnosis ?? this.diagnosis,
      lastActivity: lastActivity ?? this.lastActivity,
      status: status ?? this.status,
      mood: mood ?? this.mood,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      nextAppointment: nextAppointment ?? this.nextAppointment,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class ProfessionalAppointment {
  const ProfessionalAppointment({
    this.id,
    this.startsAt,
    required this.time,
    required this.patient,
    required this.type,
  });

  final String? id;
  final DateTime? startsAt;
  final String time;
  final ProfessionalPatient patient;
  final String type;

  ProfessionalAppointment copyWith({
    String? id,
    DateTime? startsAt,
    String? time,
    ProfessionalPatient? patient,
    String? type,
  }) {
    return ProfessionalAppointment(
      id: id ?? this.id,
      startsAt: startsAt ?? this.startsAt,
      time: time ?? this.time,
      patient: patient ?? this.patient,
      type: type ?? this.type,
    );
  }
}

class ProfessionalMedication {
  const ProfessionalMedication({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.adherence,
  });

  final String name;
  final String dose;
  final String frequency;
  final double adherence;

  ProfessionalMedication copyWith({
    String? name,
    String? dose,
    String? frequency,
    double? adherence,
  }) {
    return ProfessionalMedication(
      name: name ?? this.name,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      adherence: adherence ?? this.adherence,
    );
  }
}

class ProfessionalRecord {
  const ProfessionalRecord({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
}
