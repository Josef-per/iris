import 'package:iris/core/time/local_day.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emotional_diary/daily_emotional_record.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/emotional_diary/emotional_diary_support_topics.dart';
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

/// Leitura estruturada separada para preservar consumidores e fakes do diário.
///
/// Essa fronteira nunca carrega o texto livre de `diario_emocional`.
abstract interface class StructuredEmotionalDiaryDataSource {
  Future<List<DailyEmotionalRecord>> listRecentStructuredRecords({
    int days = 7,
  });
}

class EmotionalDiaryRepository
    implements
        EmotionalDiaryDataSource,
        StructuredEmotionalDiaryDataSource,
        EmotionalDiarySupportTopicDataSource {
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

  static const _structuredColumns =
      'id, data_local, data_registro, atualizado_em, como_sentiu';

  @override
  Future<List<DailyEmotionalRecord>> listRecentStructuredRecords({
    int days = 7,
  }) async {
    if (days <= 0) {
      throw ArgumentError.value(days, 'days', 'Informe ao menos um dia.');
    }

    final pacienteId = await _users.findCurrentPatientId();
    if (pacienteId == null) return const <DailyEmotionalRecord>[];

    final firstLocalDay = _clock().subtract(Duration(days: days - 1));
    final data = await _client
        .from(DatabaseTables.registrosEmocionais)
        .select(_structuredColumns)
        .eq('paciente_id', pacienteId)
        .gte('data_local', LocalDay.key(firstLocalDay))
        .order('data_local', ascending: false)
        .order('data_registro', ascending: false)
        .limit(days);

    if (data.isEmpty) return const <DailyEmotionalRecord>[];

    final now = _clock();
    final recordIds = data
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final topicRows = recordIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from(DatabaseTables.topicosApoio)
              .select(
                'registro_emocional_id, topico, estado, expira_em, invalidado_em',
              )
              .inFilter('registro_emocional_id', recordIds)
              .eq('estado', 'confirmado')
              .gt('expira_em', now.toUtc().toIso8601String())
              .isFilter('invalidado_em', null);

    final topicsByRecord = <String, List<Map<String, dynamic>>>{};
    for (final row in topicRows) {
      final recordId = row['registro_emocional_id']?.toString() ?? '';
      if (recordId.isEmpty) continue;
      topicsByRecord.putIfAbsent(recordId, () => []).add(row);
    }

    return data
        .map(
          (row) => DailyEmotionalRecord.fromMap(<String, dynamic>{
            ...row,
            'topicos_apoio': EmotionalDiarySupportTopic.confirmedCodesFromRows(
              topicsByRecord[row['id']?.toString()] ?? const [],
              now: now,
            ).toList(growable: false),
          }),
        )
        .toList(growable: false);
  }

  @override
  Future<Set<String>> listConfirmedSupportTopics({
    required String emotionalRecordId,
  }) async {
    final cleanRecordId = emotionalRecordId.trim();
    if (cleanRecordId.isEmpty) {
      throw ArgumentError.value(
        emotionalRecordId,
        'emotionalRecordId',
        'Informe o registro emocional.',
      );
    }

    final now = _clock();
    final rows = await _client
        .from(DatabaseTables.topicosApoio)
        .select('topico, estado, expira_em, invalidado_em')
        .eq('registro_emocional_id', cleanRecordId)
        .eq('estado', 'confirmado')
        .gt('expira_em', now.toUtc().toIso8601String())
        .isFilter('invalidado_em', null);

    return EmotionalDiarySupportTopic.confirmedCodesFromRows(rows, now: now);
  }

  @override
  Future<void> replaceConfirmedSupportTopics({
    required String emotionalRecordId,
    required Set<String> topicCodes,
  }) async {
    final cleanRecordId = emotionalRecordId.trim();
    if (cleanRecordId.isEmpty) {
      throw ArgumentError.value(
        emotionalRecordId,
        'emotionalRecordId',
        'Informe o registro emocional.',
      );
    }
    if (topicCodes.length > 2) {
      throw ArgumentError.value(
        topicCodes,
        'topicCodes',
        'Escolha no máximo dois tópicos.',
      );
    }
    final unknownCodes = topicCodes
        .where((code) => !EmotionalDiarySupportTopic.isKnown(code))
        .toList(growable: false);
    if (unknownCodes.isNotEmpty) {
      throw ArgumentError.value(
        unknownCodes,
        'topicCodes',
        'Tópico de apoio inválido.',
      );
    }

    final currentCodes = await listConfirmedSupportTopics(
      emotionalRecordId: cleanRecordId,
    );
    final toConfirm = topicCodes.difference(currentCodes).toList()..sort();
    final toRefuse = currentCodes.difference(topicCodes).toList()..sort();

    for (final code in toConfirm) {
      await _setSupportTopic(
        emotionalRecordId: cleanRecordId,
        topicCode: code,
        confirm: true,
      );
    }
    for (final code in toRefuse) {
      await _setSupportTopic(
        emotionalRecordId: cleanRecordId,
        topicCode: code,
        confirm: false,
      );
    }
  }

  Future<void> _setSupportTopic({
    required String emotionalRecordId,
    required String topicCode,
    required bool confirm,
  }) async {
    await _client.rpc(
      'iris_set_topico_apoio',
      params: {
        'p_registro_emocional_id': emotionalRecordId,
        'p_topico': topicCode,
        'p_confirmar': confirm,
      },
    );
  }

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
