import 'package:iris/core/time/local_day.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class EmotionalDiaryDataSource {
  Future<void> createDiaryEntry({required String content});

  Future<void> clearDiaryEntry();

  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<String> sintomasEmocionaisHoje,
    required List<String> sintomasFisicosHoje,
    String? humor,
  });

  Future<Map<String, dynamic>?> getTodayRecord();

  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries();
}

class EmotionalDiaryRepository implements EmotionalDiaryDataSource {
  EmotionalDiaryRepository({
    SupabaseClient? client,
    UserRepository? users,
    DateTime Function()? clock,
  }) : _clientOverride = client,
       _users = users ?? UserRepository(client: client),
       _clock = clock ?? DateTime.now;

  final SupabaseClient? _clientOverride;
  final UserRepository _users;
  final DateTime Function() _clock;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  Future<void> createEntry({required String content}) async {
    await createDiaryEntry(content: content);
  }

  @override
  Future<void> createDiaryEntry({required String content}) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      throw const FormatException('Escreva como você está se sentindo.');
    }

    await _upsertTodayRecord({'p_diario_emocional': cleanContent});
  }

  @override
  Future<void> clearDiaryEntry() async {
    await _upsertTodayRecord({'p_limpar_diario': true});
  }

  @override
  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<String> sintomasEmocionaisHoje,
    required List<String> sintomasFisicosHoje,
    String? humor,
  }) async {
    if (comoSentiu < 1 || comoSentiu > 5) {
      throw ArgumentError.value(comoSentiu, 'comoSentiu');
    }
    if (avaliacaoAlimentacao < 1 || avaliacaoAlimentacao > 5) {
      throw ArgumentError.value(avaliacaoAlimentacao, 'avaliacaoAlimentacao');
    }

    await _upsertTodayRecord({
      'p_humor': _emptyToNull(humor),
      'p_como_sentiu': comoSentiu,
      'p_avaliacao_alimentacao': avaliacaoAlimentacao,
      'p_sintomas_emocionais_hoje': sintomasEmocionaisHoje,
      'p_sintomas_fisicos_hoje': sintomasFisicosHoje,
    });
  }

  @override
  Future<Map<String, dynamic>?> getTodayRecord() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return null;
    }

    return _findTodayRecord(pacienteId, now: _clock());
  }

  Future<void> _upsertTodayRecord(Map<String, dynamic> values) async {
    await _users.getOrCreateCurrentPatientId();
    final now = _clock();
    await _client.rpc(
      'iris_upsert_daily_emotional_record',
      params: {
        'p_data_local': LocalDay.key(now),
        'p_fuso_horario': LocalDay.timeZone(now),
        ...values,
      },
    );
  }

  Future<Map<String, dynamic>?> _findTodayRecord(
    String pacienteId, {
    required DateTime now,
  }) {
    return _client
        .from(DatabaseTables.registrosEmocionais)
        .select(_todayColumns)
        .eq('paciente_id', pacienteId)
        .eq('data_local', LocalDay.key(now))
        .order('data_registro', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  static const _todayColumns =
      'id, data_local, diario_emocional, humor, como_sentiu, '
      'avaliacao_alimentacao, sintomas_emocionais_hoje, sintomas_fisicos_hoje';

  @override
  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return [];
    }

    final data = await _client
        .from(DatabaseTables.registrosEmocionais)
        .select('id, diario_emocional, data_registro, pacientes(user_id)')
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
