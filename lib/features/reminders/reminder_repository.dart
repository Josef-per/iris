import 'package:flutter/material.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PatientReminderType {
  refeicao('refeicao', 'Refeição'),
  medicamento('medicamento', 'Medicamento');

  const PatientReminderType(this.code, this.label);

  final String code;
  final String label;
}

class PatientReminder {
  const PatientReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.time,
    required this.isActive,
  });

  final String id;
  final PatientReminderType type;
  final String title;
  final TimeOfDay time;
  final bool isActive;

  factory PatientReminder.fromMap(Map<String, dynamic> map) {
    final type =
        PatientReminderType.values
            .where((item) => item.code == map['tipo'])
            .firstOrNull ??
        PatientReminderType.refeicao;
    final time =
        _parseTime(map['horario']) ?? const TimeOfDay(hour: 8, minute: 0);

    return PatientReminder(
      id: map['id'] as String,
      type: type,
      title: (map['titulo'] ?? '').toString(),
      time: time,
      isActive: map['ativo'] == true,
    );
  }

  static TimeOfDay? _parseTime(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}

abstract interface class ReminderDataSource {
  Future<List<PatientReminder>> listCurrentUserReminders();

  Future<PatientReminder> createReminder({
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
    bool isActive = true,
  });

  Future<void> updateReminder({
    required String id,
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
  });

  Future<void> setReminderActive({required String id, required bool isActive});

  Future<void> deleteReminder(String id);
}

class ReminderRepository implements ReminderDataSource {
  ReminderRepository({SupabaseClient? client, UserRepository? users})
    : _clientOverride = client,
      _users = users ?? UserRepository(client: client);

  final SupabaseClient? _clientOverride;
  final UserRepository _users;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<List<PatientReminder>> listCurrentUserReminders() async {
    final pacienteId = await _users.findCurrentPatientId();
    if (pacienteId == null) {
      return [];
    }

    final rows = await _client
        .from(DatabaseTables.lembretes)
        .select('id, tipo, titulo, horario, ativo')
        .eq('paciente_id', pacienteId)
        .order('horario', ascending: true);

    return rows
        .map((row) => PatientReminder.fromMap(row))
        .toList(growable: false);
  }

  @override
  Future<PatientReminder> createReminder({
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
    bool isActive = true,
  }) async {
    final pacienteId = await _users.getOrCreateCurrentPatientId();
    final cleanTitle = _validatedTitle(title);

    final row = await _client
        .from(DatabaseTables.lembretes)
        .insert({
          'paciente_id': pacienteId,
          'tipo': type.code,
          'titulo': cleanTitle,
          'horario': _timeToDb(time),
          'ativo': isActive,
        })
        .select('id, tipo, titulo, horario, ativo')
        .single();

    return PatientReminder.fromMap(row);
  }

  @override
  Future<void> updateReminder({
    required String id,
    required PatientReminderType type,
    required String title,
    required TimeOfDay time,
  }) async {
    final cleanTitle = _validatedTitle(title);

    await _client
        .from(DatabaseTables.lembretes)
        .update({
          'tipo': type.code,
          'titulo': cleanTitle,
          'horario': _timeToDb(time),
        })
        .eq('id', id);
  }

  @override
  Future<void> setReminderActive({
    required String id,
    required bool isActive,
  }) async {
    await _client
        .from(DatabaseTables.lembretes)
        .update({'ativo': isActive})
        .eq('id', id);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _client.from(DatabaseTables.lembretes).delete().eq('id', id);
  }

  String _validatedTitle(String title) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const FormatException('Informe um título para o lembrete.');
    }
    return cleanTitle;
  }

  static String _timeToDb(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
