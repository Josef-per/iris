import 'package:flutter/material.dart';

enum ProfessionalDestination { dashboard, patients, notes, carePlan, settings }

enum PatientStatus { active, inactive }

class ProfessionalPatient {
  const ProfessionalPatient({
    required this.id,
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

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class ProfessionalAppointment {
  const ProfessionalAppointment({
    required this.time,
    required this.patient,
    required this.type,
  });

  final String time;
  final ProfessionalPatient patient;
  final String type;
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

abstract final class ProfessionalMockData {
  static const patients = <ProfessionalPatient>[
    ProfessionalPatient(
      id: 'patient-ana',
      name: 'Ana Paula Ribeiro',
      age: 28,
      diagnosis: 'Anorexia nervosa',
      lastActivity: 'Há 2 horas',
      status: PatientStatus.active,
      mood: 'Bem',
      email: 'ana.ribeiro@example.com',
      phone: '(11) 98765-4321',
      birthDate: '14/09/1997',
      nextAppointment: 'Hoje, 14:00',
    ),
    ProfessionalPatient(
      id: 'patient-luiza',
      name: 'Luiza Silva',
      age: 24,
      diagnosis: 'Compulsão alimentar',
      lastActivity: 'Há 4 horas',
      status: PatientStatus.active,
      mood: 'Muito bem',
      email: 'luiza.silva@example.com',
      phone: '(11) 97654-3321',
      birthDate: '02/03/2002',
      nextAppointment: 'Hoje, 15:00',
    ),
    ProfessionalPatient(
      id: 'patient-carlos',
      name: 'Carlos Santos',
      age: 31,
      diagnosis: 'Bulimia nervosa',
      lastActivity: 'Ontem, 20:14',
      status: PatientStatus.active,
      mood: 'Mais ou menos',
      email: 'carlos.santos@example.com',
      phone: '(11) 96543-2210',
      birthDate: '27/11/1994',
      nextAppointment: 'Hoje, 16:00',
    ),
    ProfessionalPatient(
      id: 'patient-isabella',
      name: 'Isabella Souza',
      age: 22,
      diagnosis: 'TARE',
      lastActivity: 'Ontem, 18:40',
      status: PatientStatus.active,
      mood: 'Bem',
      email: 'isabella.souza@example.com',
      phone: '(11) 95432-1109',
      birthDate: '08/07/2004',
      nextAppointment: 'Hoje, 17:00',
    ),
    ProfessionalPatient(
      id: 'patient-julio',
      name: 'Júlio Nascimento',
      age: 36,
      diagnosis: 'Compulsão alimentar',
      lastActivity: 'Há 3 dias',
      status: PatientStatus.inactive,
      mood: 'Mal',
      email: 'julio.nascimento@example.com',
      phone: '(11) 94321-0098',
      birthDate: '19/01/1990',
      nextAppointment: 'Hoje, 18:00',
    ),
    ProfessionalPatient(
      id: 'patient-fernanda',
      name: 'Fernanda Andrade',
      age: 27,
      diagnosis: 'Anorexia nervosa',
      lastActivity: 'Há 5 dias',
      status: PatientStatus.inactive,
      mood: 'Mais ou menos',
      email: 'fernanda.andrade@example.com',
      phone: '(11) 93210-9987',
      birthDate: '30/05/1999',
      nextAppointment: 'Sexta, 10:30',
    ),
  ];

  static List<ProfessionalAppointment> get appointments => [
    ProfessionalAppointment(
      time: '14:00',
      patient: patients[0],
      type: 'Online',
    ),
    ProfessionalAppointment(
      time: '15:00',
      patient: patients[1],
      type: 'Presencial',
    ),
    ProfessionalAppointment(
      time: '16:00',
      patient: patients[2],
      type: 'Online',
    ),
    ProfessionalAppointment(
      time: '17:00',
      patient: patients[3],
      type: 'Online',
    ),
    ProfessionalAppointment(
      time: '18:00',
      patient: patients[4],
      type: 'Presencial',
    ),
  ];

  static const medications = <ProfessionalMedication>[
    ProfessionalMedication(
      name: 'Sertralina',
      dose: '50 mg',
      frequency: '1 vez ao dia',
      adherence: .92,
    ),
    ProfessionalMedication(
      name: 'Quetiapina',
      dose: '25 mg',
      frequency: 'À noite',
      adherence: .78,
    ),
  ];

  static const records = <ProfessionalRecord>[
    ProfessionalRecord(
      title: 'Check-in diário',
      description: 'Humor: bem · sono regular · ansiedade leve',
      time: 'Hoje, 09:20',
      icon: Icons.favorite_outline_rounded,
      color: Color(0xFF7D6AC6),
    ),
    ProfessionalRecord(
      title: 'Registro alimentar',
      description: 'Café da manhã registrado com foto',
      time: 'Hoje, 08:10',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF3D7A55),
    ),
    ProfessionalRecord(
      title: 'Medicação',
      description: 'Sertralina 50 mg marcada como tomada',
      time: 'Hoje, 07:45',
      icon: Icons.medication_outlined,
      color: Color(0xFF466BC7),
    ),
    ProfessionalRecord(
      title: 'Diário emocional',
      description: '“Consegui almoçar com a minha família.”',
      time: 'Ontem, 20:15',
      icon: Icons.auto_stories_outlined,
      color: Color(0xFFC98A34),
    ),
  ];
}
