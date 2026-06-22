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
    final pacienteId = await _users.getOrCreateCurrentPatientId();

    await _client.from(DatabaseTables.registrosEmocionais).insert({
      'paciente_id': pacienteId,
      'diario_emocional': content.trim(),
      'data_registro': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required int sintomasEmocionaisHoje,
    required int sintomasFisicosHoje,
    String? humor,
  }) async {
    final pacienteId = await _users.getOrCreateCurrentPatientId();

    await _client.from(DatabaseTables.registrosEmocionais).insert({
      'paciente_id': pacienteId,
      'humor': _emptyToNull(humor),
      'data_registro': DateTime.now().toIso8601String(),
      'como_sentiu': comoSentiu,
      'avaliacao_alimentacao': avaliacaoAlimentacao,
      'sintomas_emocionais_hoje': sintomasEmocionaisHoje,
      'sintomas_fisicos_hoje': sintomasFisicosHoje,
    });
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
