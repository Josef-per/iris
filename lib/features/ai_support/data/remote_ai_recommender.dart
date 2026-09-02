import 'dart:math';

import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AiSupportRolloutMode { local, shadow, pilot, limitedProduction }

extension AiSupportRolloutModeWire on AiSupportRolloutMode {
  static AiSupportRolloutMode fromWire(String? value) => switch (value) {
    'shadow' => AiSupportRolloutMode.shadow,
    'pilot' => AiSupportRolloutMode.pilot,
    'limited' || 'limited_production' => AiSupportRolloutMode.limitedProduction,
    _ => AiSupportRolloutMode.local,
  };

  bool get mayInfluencePatient =>
      this == AiSupportRolloutMode.pilot ||
      this == AiSupportRolloutMode.limitedProduction;
}

enum AiSupportRemoteOutcome { suggested, silent, rejected, error, unknown }

extension AiSupportRemoteOutcomeWire on AiSupportRemoteOutcome {
  static AiSupportRemoteOutcome fromWire({
    required String? status,
    required String? outcome,
  }) {
    if (status == 'suggested') return AiSupportRemoteOutcome.suggested;
    return switch (outcome) {
      'silent' => AiSupportRemoteOutcome.silent,
      'rejected' => AiSupportRemoteOutcome.rejected,
      'error' => AiSupportRemoteOutcome.error,
      _ when status == 'silent' => AiSupportRemoteOutcome.silent,
      _ => AiSupportRemoteOutcome.unknown,
    };
  }
}

enum AiSupportRecommendationTrigger {
  manual('manual'),
  afterCheckIn('after_checkin'),
  afterDiary('after_diary'),
  notificationOpen('notification_open');

  const AiSupportRecommendationTrigger(this.wireName);

  final String wireName;
}

class RemoteAiSupportDecision {
  const RemoteAiSupportDecision({
    required this.mode,
    this.outcome = AiSupportRemoteOutcome.unknown,
    this.proposal,
    this.requestId,
    this.suggestionId,
    this.origin,
    this.reasonCode,
  });

  final AiSupportRolloutMode mode;
  final AiSupportRemoteOutcome outcome;
  final Map<String, Object?>? proposal;
  final String? requestId;
  final String? suggestionId;
  final String? origin;
  final String? reasonCode;

  bool get shouldUseProposal =>
      proposal != null && origin == 'openai' && mode.mayInfluencePatient;
}

abstract interface class AiSupportRemoteRecommender {
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  });
}

abstract interface class AiSupportFunctionInvoker {
  Future<Map<String, Object?>> invoke(Map<String, Object?> body);
}

class SupabaseAiSupportFunctionInvoker implements AiSupportFunctionInvoker {
  SupabaseAiSupportFunctionInvoker({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  @override
  Future<Map<String, Object?>> invoke(Map<String, Object?> body) async {
    final response = await _client.functions
        .invoke('ai-support-recommend', body: body)
        .timeout(const Duration(seconds: 12));
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Resposta de personalização inválida.');
    }
    return data.map((key, value) => MapEntry(key.toString(), value as Object?));
  }
}

/// Fronteira mínima com o backend autenticado.
///
/// O aplicativo envia apenas um UUID de idempotência e a origem da ação. O
/// backend resolve paciente, consentimentos e sinais estruturados pelo JWT. Com
/// isso, diário, sintomas e alimentação nem sequer fazem parte deste contrato.
class SupabaseAiSupportRemoteRecommender implements AiSupportRemoteRecommender {
  SupabaseAiSupportRemoteRecommender({
    AiSupportFunctionInvoker? invoker,
    String Function()? requestIdFactory,
  }) : _invoker = invoker ?? SupabaseAiSupportFunctionInvoker(),
       _requestIdFactory = requestIdFactory ?? generateAiSupportRequestId;

  final AiSupportFunctionInvoker _invoker;
  final String Function() _requestIdFactory;

  @override
  Future<RemoteAiSupportDecision> recommend(
    AiSupportRecommendationContext context, {
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) async {
    // Consentimento também é validado no backend; esta checagem evita uma
    // chamada desnecessária quando o estado local já a proíbe.
    if (!context.consent.personalizedSuggestionsGranted ||
        !context.preferences.personalizedSuggestionsEnabled) {
      return const RemoteAiSupportDecision(mode: AiSupportRolloutMode.local);
    }

    final requestId = _requestIdFactory();
    final response = await _invoker.invoke(<String, Object?>{
      'requestId': requestId,
      'trigger': trigger.wireName,
    });
    final mode = AiSupportRolloutModeWire.fromWire(
      response['mode']?.toString(),
    );
    final outcome = AiSupportRemoteOutcomeWire.fromWire(
      status: response['status']?.toString(),
      outcome: response['outcome']?.toString(),
    );
    if (response['status'] != 'suggested') {
      return RemoteAiSupportDecision(
        mode: mode,
        outcome: outcome,
        requestId: requestId,
        reasonCode: _safeReasonCode(response['reasonCode']),
      );
    }

    final templateId = response['templateId'];
    final reasonCodes = response['reasonCodes'];
    final confidenceBand = response['confidenceBand'];
    if (templateId is! String ||
        reasonCodes is! List ||
        confidenceBand is! String) {
      throw const FormatException('Sugestão remota incompleta.');
    }
    final exerciseId = response['exerciseId'];
    if (exerciseId != null && exerciseId is! String) {
      throw const FormatException('Exercício remoto inválido.');
    }
    final suggestionId = response['suggestionId']?.toString() ?? '';
    final origin = response['origin']?.toString() ?? '';
    final echoedRequestId = response['requestId']?.toString();
    if (!isAiSupportUuid(suggestionId) ||
        origin != 'openai' ||
        (echoedRequestId != null && echoedRequestId != requestId)) {
      throw const FormatException('Identidade da sugestão remota inválida.');
    }

    return RemoteAiSupportDecision(
      mode: mode,
      outcome: AiSupportRemoteOutcome.suggested,
      requestId: requestId,
      suggestionId: suggestionId,
      origin: origin,
      proposal: <String, Object?>{
        'suggestionTemplateId': templateId,
        'exerciseId': exerciseId,
        'reasonCodes': reasonCodes,
        'confidenceBand': confidenceBand,
      },
    );
  }
}

String? _safeReasonCode(Object? value) {
  final code = value?.toString() ?? '';
  if (code.isEmpty || !RegExp(r'^[a-z0-9_]{1,80}$').hasMatch(code)) {
    return null;
  }
  return code;
}

bool isAiSupportUuid(String value) => RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(value);

String generateAiSupportRequestId({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final encoded = bytes.map(hex).join();
  return '${encoded.substring(0, 8)}-'
      '${encoded.substring(8, 12)}-'
      '${encoded.substring(12, 16)}-'
      '${encoded.substring(16, 20)}-'
      '${encoded.substring(20)}';
}
