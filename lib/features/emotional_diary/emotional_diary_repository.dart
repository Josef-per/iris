import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionalDiaryRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  Future<void> createEntry({required String content}) async {
    await createDiaryEntry(content: content);
  }

  Future<void> createDiaryEntry({required String content}) async {
    await _upsertTodayRecord({'diario_emocional': content.trim()});
  }

  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<int> sintomasEmocionaisHoje,
    required List<int> sintomasFisicosHoje,
    String? humor,
  }) async {
    await _upsertTodayRecord({
      'humor': _emptyToNull(humor),
      'como_sentiu': comoSentiu,
      'avaliacao_alimentacao': avaliacaoAlimentacao,
      'sintomas_emocionais_hoje': sintomasEmocionaisHoje,
      'sintomas_fisicos_hoje': sintomasFisicosHoje,
    });
  }

  Future<Map<String, dynamic>?> getTodayRecord() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return null;
    }

    return _findTodayRecord(pacienteId, columns: '*');
  }

  Future<void> _upsertTodayRecord(Map<String, dynamic> values) async {
    final pacienteId = await _users.getOrCreateCurrentPatientId();
    final existing = await _findTodayRecord(pacienteId, columns: 'id');

    if (existing != null) {
      await _client
          .from(DatabaseTables.registrosEmocionais)
          .update(values)
          .eq('id', existing['id'] as String);

      return;
    }

    await _client.from(DatabaseTables.registrosEmocionais).insert({
      'paciente_id': pacienteId,
      'data_registro': DateTime.now().toIso8601String(),
      ...values,
    });
  }

  Future<Map<String, dynamic>?> _findTodayRecord(
    String pacienteId, {
    required String columns,
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return _client
        .from(DatabaseTables.registrosEmocionais)
        .select(columns)
        .eq('paciente_id', pacienteId)
        .gte('data_registro', startOfDay.toIso8601String())
        .lt('data_registro', startOfNextDay.toIso8601String())
        .order('data_registro', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return [];
    }

    final data = await _client
        .from(DatabaseTables.registrosEmocionais)
        .select(
          'id, diario_emocional, data_registro, paciente_id, pacientes(user_id)',
        )
        .eq('paciente_id', pacienteId)
        .order('data_registro', ascending: false);

    return data
        .map((row) => EmotionalDiaryEntry.fromMap(row))
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();
  }

  String? _emptyToNull(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}
