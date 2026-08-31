import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AiSupportSuggestionDataSource {
  Future<SupportSuggestion?> loadVisibleSuggestion(String suggestionId);
}

/// Recupera pelo ID opaco somente uma sugestão efetiva ainda visível por RLS.
/// Isso faz o toque da notificação abrir exatamente o conteúdo que a originou.
class SupabaseAiSupportSuggestionRepository
    implements AiSupportSuggestionDataSource {
  SupabaseAiSupportSuggestionRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<SupportSuggestion?> loadVisibleSuggestion(String suggestionId) async {
    if (!isAiSupportUuid(suggestionId)) return null;
    final row = await _client
        .from('sugestoes_ia_apoio')
        .select(
          'id, template_id, categoria, exercicio_id, reason_codes, '
          'fontes_usadas, confidence_band, criado_em, expira_em',
        )
        .eq('id', suggestionId)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return decodeVisibleAiSupportSuggestion(row);
  }
}

SupportSuggestion? decodeVisibleAiSupportSuggestion(Map<String, dynamic> row) {
  final id = row['id']?.toString() ?? '';
  final templateId = row['template_id']?.toString() ?? '';
  final category = _categoryFromWire(row['categoria']?.toString());
  final confidence = ConfidenceBandWire.fromWireName(
    row['confidence_band']?.toString() ?? '',
  );
  final createdAt = DateTime.tryParse(row['criado_em']?.toString() ?? '');
  final expiresAt = DateTime.tryParse(row['expira_em']?.toString() ?? '');
  if (!isAiSupportUuid(id) ||
      templateId.isEmpty ||
      category == null ||
      confidence == null ||
      confidence == ConfidenceBand.low ||
      createdAt == null ||
      expiresAt == null ||
      !expiresAt.isAfter(createdAt)) {
    return null;
  }

  final reasons = _stringList(row['reason_codes'])
      .map(SupportReasonCodeWire.fromWireName)
      .whereType<SupportReasonCode>()
      .toSet();
  final sources = _stringList(
    row['fontes_usadas'],
  ).map(_sourceFromWire).whereType<SupportSignalSource>().toSet();
  if (reasons.isEmpty || sources.isEmpty) return null;

  final exercise = row['exercicio_id']?.toString().trim();
  return SupportSuggestion(
    id: id,
    templateId: templateId,
    category: category,
    exerciseId: exercise == null || exercise.isEmpty ? null : exercise,
    reasonCodes: reasons,
    confidenceBand: confidence,
    usedSources: sources,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}

SupportSuggestionCategory? _categoryFromWire(String? value) => switch (value) {
  'reflection' => SupportSuggestionCategory.reflection,
  'exercise' => SupportSuggestionCategory.exercise,
  'video' => SupportSuggestionCategory.video,
  'human_connection' => SupportSuggestionCategory.humanConnection,
  'professional_conversation' =>
    SupportSuggestionCategory.professionalConversation,
  _ => null,
};

SupportSignalSource? _sourceFromWire(String value) => switch (value) {
  'mood_history' => SupportSignalSource.moodHistory,
  'diary_topics' => SupportSignalSource.diaryTags,
  'exercise_feedback' => SupportSignalSource.exerciseFeedback,
  'notification_interactions' => SupportSignalSource.notificationInteractions,
  _ => null,
};
