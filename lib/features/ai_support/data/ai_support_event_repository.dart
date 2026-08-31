import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AiSupportEventType {
  scheduled('agendada'),
  opened('aberta'),
  dismissed('dispensada'),
  actionStarted('acao_iniciada'),
  actionCompleted('acao_concluida'),
  matchesPerception('combina_percepcao'),
  doesNotMatch('nao_combina'),
  preferNotToAnswer('prefere_nao_responder'),
  helpful('util'),
  neutral('neutra'),
  notHelpful('nao_ajudou'),
  harmful('prejudicial');

  const AiSupportEventType(this.wireName);

  final String wireName;
}

enum AiSupportEventChannel {
  app('app'),
  localNotification('local_notification');

  const AiSupportEventChannel(this.wireName);

  final String wireName;
}

abstract interface class AiSupportEventDataSource {
  Future<void> record({
    required String suggestionId,
    required AiSupportEventType type,
    required AiSupportEventChannel channel,
    DateTime? scheduledFor,
  });
}

class AiSupportStoredEvent {
  const AiSupportStoredEvent({
    required this.id,
    required this.suggestionId,
    required this.templateId,
    required this.category,
    required this.type,
    required this.channel,
    required this.occurredAt,
    this.exerciseId,
    this.scheduledFor,
  });

  final String id;
  final String suggestionId;
  final String templateId;
  final String category;
  final String? exerciseId;
  final AiSupportEventType type;
  final AiSupportEventChannel channel;
  final DateTime occurredAt;
  final DateTime? scheduledFor;
}

abstract interface class AiSupportEventHistoryDataSource {
  Future<List<AiSupportStoredEvent>> loadRecentEvents({int days = 30});
}

/// Persiste apenas IDs e escolhas fechadas; não aceita comentário ou texto.
class SupabaseAiSupportEventRepository
    implements AiSupportEventDataSource, AiSupportEventHistoryDataSource {
  SupabaseAiSupportEventRepository({
    SupabaseClient? client,
    String Function()? eventIdFactory,
  }) : _clientOverride = client,
       _eventIdFactory = eventIdFactory ?? generateAiSupportRequestId;

  final SupabaseClient? _clientOverride;
  final String Function() _eventIdFactory;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<void> record({
    required String suggestionId,
    required AiSupportEventType type,
    required AiSupportEventChannel channel,
    DateTime? scheduledFor,
  }) async {
    if (!isAiSupportUuid(suggestionId)) return;
    await _client.rpc(
      'iris_registrar_evento_ia_apoio',
      params: <String, Object?>{
        'p_sugestao_id': suggestionId,
        'p_tipo': type.wireName,
        'p_canal': channel.wireName,
        'p_client_event_id': _eventIdFactory(),
        'p_agendado_para': scheduledFor?.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<List<AiSupportStoredEvent>> loadRecentEvents({int days = 30}) async {
    if (days < 1 || days > 30) {
      throw ArgumentError.value(days, 'days', 'Informe de 1 a 30 dias.');
    }
    final result = await _client.rpc(
      'iris_listar_eventos_ia_apoio',
      params: <String, Object?>{'p_dias': days},
    );
    if (result is! List) return const <AiSupportStoredEvent>[];
    return result
        .whereType<Map>()
        .map((row) => _decodeStoredEvent(row.cast<String, dynamic>()))
        .whereType<AiSupportStoredEvent>()
        .toList(growable: false);
  }
}

AiSupportStoredEvent? _decodeStoredEvent(Map<String, dynamic> row) {
  final id = row['evento_id']?.toString() ?? '';
  final suggestionId = row['sugestao_id']?.toString() ?? '';
  final templateId = row['template_id']?.toString() ?? '';
  final category = row['categoria']?.toString() ?? '';
  final occurredAt = DateTime.tryParse(row['ocorrido_em']?.toString() ?? '');
  final scheduledFor = DateTime.tryParse(
    row['agendado_para']?.toString() ?? '',
  );
  final type = _eventTypeFromWire(row['tipo']?.toString());
  final channel = _eventChannelFromWire(row['canal']?.toString());
  if (!isAiSupportUuid(id) ||
      !isAiSupportUuid(suggestionId) ||
      templateId.isEmpty ||
      category.isEmpty ||
      occurredAt == null ||
      type == null ||
      channel == null) {
    return null;
  }
  final exercise = row['exercicio_id']?.toString().trim();
  return AiSupportStoredEvent(
    id: id,
    suggestionId: suggestionId,
    templateId: templateId,
    category: category,
    exerciseId: exercise == null || exercise.isEmpty ? null : exercise,
    type: type,
    channel: channel,
    occurredAt: occurredAt,
    scheduledFor: scheduledFor,
  );
}

AiSupportEventType? _eventTypeFromWire(String? value) {
  for (final type in AiSupportEventType.values) {
    if (type.wireName == value) return type;
  }
  return null;
}

AiSupportEventChannel? _eventChannelFromWire(String? value) {
  for (final channel in AiSupportEventChannel.values) {
    if (channel.wireName == value) return channel;
  }
  return null;
}
