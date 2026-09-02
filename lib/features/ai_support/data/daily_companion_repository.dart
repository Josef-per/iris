import 'package:iris/features/ai_support/domain/daily_companion_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class DailyCompanionDataSource {
  Future<DailyCompanionMessage> loadToday();
}

class DisabledDailyCompanionRepository implements DailyCompanionDataSource {
  const DisabledDailyCompanionRepository();

  @override
  Future<DailyCompanionMessage> loadToday() async =>
      const DailyCompanionMessage(status: DailyCompanionStatus.notAvailable);
}

/// A tela inicial nao envia diario, perfil ou sinais clinicos. A Edge Function
/// autenticada resolve esses dados apenas depois de checar o consentimento.
class SupabaseDailyCompanionRepository implements DailyCompanionDataSource {
  SupabaseDailyCompanionRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  @override
  Future<DailyCompanionMessage> loadToday() async {
    final response = await _client.functions
        .invoke('ai-daily-companion', body: const <String, Object?>{})
        .timeout(const Duration(seconds: 12));
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Resposta da reflexao diaria invalida.');
    }
    final data = raw.map(
      (key, value) => MapEntry(key.toString(), value as Object?),
    );
    return decodeDailyCompanionMessage(data);
  }
}

DailyCompanionMessage decodeDailyCompanionMessage(Map<String, Object?> data) {
  final status = switch (data['status']?.toString()) {
    'ready' => DailyCompanionStatus.ready,
    'waiting_for_context' => DailyCompanionStatus.waitingForContext,
    'not_enabled' => DailyCompanionStatus.notEnabled,
    'not_available' => DailyCompanionStatus.notAvailable,
    'needs_human_support' => DailyCompanionStatus.needsHumanSupport,
    _ => throw const FormatException('Estado da reflexao diaria invalido.'),
  };
  if (status != DailyCompanionStatus.ready &&
      status != DailyCompanionStatus.needsHumanSupport) {
    return DailyCompanionMessage(status: status);
  }
  final title = _cleanText(data['title'], minimum: 3, maximum: 80);
  final message = status == DailyCompanionStatus.ready
      ? _cleanMarkdownText(data['message'], minimum: 20, maximum: 480)
      : _cleanText(data['message'], minimum: 20, maximum: 480);
  final question = data['reflectionQuestion'] == null
      ? null
      : _cleanText(data['reflectionQuestion'], minimum: 8, maximum: 240);
  if (title == null ||
      message == null ||
      (data['reflectionQuestion'] != null && question == null)) {
    throw const FormatException('Conteudo da reflexao diaria invalido.');
  }
  return DailyCompanionMessage(
    status: status,
    title: title,
    message: message,
    reflectionQuestion: question,
  );
}

String? _cleanText(
  Object? value, {
  required int minimum,
  required int maximum,
}) {
  if (value is! String) return null;
  final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length >= minimum && text.length <= maximum ? text : null;
}

String? _cleanMarkdownText(
  Object? value, {
  required int minimum,
  required int maximum,
}) {
  if (value is! String) return null;
  final text = value
      .replaceAll(RegExp(r'\r\n?'), '\n')
      .split('\n')
      .map((line) => line.trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  if (text.length < minimum || text.length > maximum) return null;
  final unsupported = RegExp(
    r'(!?\[[^\]]*\]\(|`|<\/?[a-z][^>]*>|^#{1,6}\s|^>\s|^\d+[.)]\s)',
    caseSensitive: false,
    multiLine: true,
  );
  return unsupported.hasMatch(text) ? null : text;
}
