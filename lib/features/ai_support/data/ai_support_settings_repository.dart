import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/core/time/local_day.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedAiSupportSettings {
  const SavedAiSupportSettings({
    required this.consent,
    required this.preferences,
  });

  final AiSupportConsent consent;
  final AiSupportPreferences preferences;
}

abstract interface class AiSupportSettingsDataSource {
  Future<SavedAiSupportSettings?> load();

  Future<void> save({
    required AiSupportConsent consent,
    required AiSupportPreferences preferences,
  });

  /// Revoga o consentimento e remove os dados criados pela funcionalidade.
  /// O diário emocional e os check-ins clínicos originais são preservados.
  Future<void> clear();
}

/// Preferências persistidas por paciente, protegidas por RLS.
///
/// Somente escolhas e consentimentos estruturados são armazenados aqui. Sinais
/// derivados, texto de diário e respostas do modelo não fazem parte da linha.
class SupabaseAiSupportSettingsRepository
    implements AiSupportSettingsDataSource {
  SupabaseAiSupportSettingsRepository({
    SupabaseClient? client,
    UserRepository? users,
    DateTime Function()? clock,
    String Function()? timeZoneName,
  }) : _clientOverride = client,
       _users = users ?? UserRepository(client: client),
       _clock = clock ?? DateTime.now,
       _timeZoneName =
           timeZoneName ?? (() => LocalDay.timeZone((clock ?? DateTime.now)()));

  static const table = 'preferencias_ia_apoio';
  static const consentVersion = 'support-consent-v1';

  final SupabaseClient? _clientOverride;
  final UserRepository _users;
  final DateTime Function() _clock;
  final String Function() _timeZoneName;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<SavedAiSupportSettings?> load() async {
    final patientId = await _users.findCurrentPatientId();
    if (patientId == null) return null;
    final row = await _client
        .from(table)
        .select(_columns)
        .eq('paciente_id', patientId)
        .limit(1)
        .maybeSingle();
    return row == null ? null : decodeAiSupportSettings(row);
  }

  @override
  Future<void> save({
    required AiSupportConsent consent,
    required AiSupportPreferences preferences,
  }) async {
    final patientId = await _users.getOrCreateCurrentPatientId();
    await _client
        .from(table)
        .upsert(
          encodeAiSupportSettings(
            patientId: patientId,
            consent: consent,
            preferences: preferences,
            now: _clock(),
            timeZoneName: _timeZoneName(),
          ),
          onConflict: 'paciente_id',
        );
  }

  @override
  Future<void> clear() async {
    final patientId = await _users.findCurrentPatientId();
    if (patientId == null) return;
    await _client.rpc('iris_apagar_dados_ia_apoio');
  }

  static const _columns =
      'paciente_id, personalizacao_ativa, fontes_consentidas, '
      'categorias_permitidas, duracao_maxima_minutos, conteudos_excluidos, '
      'notificacoes_ativas, frequencia_semanal, janela_inicio, janela_fim, '
      'dias_semana, previa_bloqueio, som_ativo, vibracao_ativa, pausado_ate, '
      'versao_consentimento, consentido_em';
}

Map<String, Object?> encodeAiSupportSettings({
  required String patientId,
  required AiSupportConsent consent,
  required AiSupportPreferences preferences,
  required DateTime now,
  required String timeZoneName,
}) {
  final notifications = preferences.notifications;
  final consented = consent.personalizedSuggestionsGranted;
  return <String, Object?>{
    'paciente_id': patientId,
    'personalizacao_ativa':
        consented && preferences.personalizedSuggestionsEnabled,
    'fontes_consentidas': _sorted(consent.grantedSources.map(_sourceToWire)),
    'categorias_permitidas': _sorted(
      preferences.allowedCategories.map(_categoryToWire),
    ),
    'duracao_maxima_minutos': preferences.maximumExerciseMinutes,
    'conteudos_excluidos': _sorted(
      preferences.excludedContentTags.map(_contentTagToWire),
    ),
    'notificacoes_ativas': notifications.enabled,
    'frequencia_semanal': notifications.frequency.maxPerWeek,
    'janela_inicio': _timeToWire(notifications.window.start),
    'janela_fim': _timeToWire(notifications.window.end),
    'dias_semana': notifications.window.allowedWeekdays.toList()..sort(),
    'fuso_horario': timeZoneName.trim().isEmpty ? 'UTC' : timeZoneName.trim(),
    'previa_bloqueio':
        notifications.lockScreenPreview == LockScreenPreview.generic
        ? 'generica'
        : 'nenhuma',
    // Esta categoria permanece silenciosa independentemente de estado antigo.
    'som_ativo': false,
    'vibracao_ativa': false,
    'pausado_ate': notifications.pausedUntil?.toUtc().toIso8601String(),
    'versao_consentimento': consented
        ? SupabaseAiSupportSettingsRepository.consentVersion
        : null,
    'consentido_em': consented ? now.toUtc().toIso8601String() : null,
  };
}

SavedAiSupportSettings decodeAiSupportSettings(Map<String, dynamic> row) {
  final sources = _stringList(
    row['fontes_consentidas'],
  ).map(_sourceFromWire).whereType<SupportSignalSource>().toSet();
  final categories = _stringList(
    row['categorias_permitidas'],
  ).map(_categoryFromWire).whereType<SupportSuggestionCategory>().toSet();
  final excludedTags = _stringList(
    row['conteudos_excluidos'],
  ).map(_contentTagFromWire).whereType<SupportContentTag>().toSet();
  final hasConsent =
      _nonEmpty(row['versao_consentimento']) != null && sources.isNotEmpty;
  final start =
      _timeFromWire(row['janela_inicio']) ?? const SupportTimeOfDay(9);
  final end = _timeFromWire(row['janela_fim']) ?? const SupportTimeOfDay(21);
  final weekdays = _integerList(
    row['dias_semana'],
  ).where((day) => day >= DateTime.monday && day <= DateTime.sunday).toSet();
  final weekly = _integer(row['frequencia_semanal']) ?? 0;
  final notificationEnabled = row['notificacoes_ativas'] == true && weekly > 0;
  final maximumMinutes = _integer(row['duracao_maxima_minutos']) ?? 2;

  return SavedAiSupportSettings(
    consent: AiSupportConsent(
      personalizedSuggestionsGranted: hasConsent,
      // Fontes podem permanecer marcadas enquanto o controle principal está
      // desligado; só passam a ser utilizáveis após novo consentimento.
      grantedSources: sources,
    ),
    preferences: AiSupportPreferences(
      personalizedSuggestionsEnabled:
          hasConsent && row['personalizacao_ativa'] == true,
      allowedCategories: categories,
      maximumExerciseMinutes: maximumMinutes.clamp(1, 10),
      excludedContentTags: excludedTags,
      notifications: NotificationPreferences(
        enabled: notificationEnabled,
        frequency: _frequencyFromWeeklyMaximum(weekly),
        window: NotificationWindow(
          start: start,
          end: end,
          allowedWeekdays: weekdays.isEmpty
              ? const <int>{
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                  DateTime.sunday,
                }
              : weekdays,
        ),
        lockScreenPreview: row['previa_bloqueio'] == 'nenhuma'
            ? LockScreenPreview.none
            : LockScreenPreview.generic,
        soundEnabled: false,
        vibrationEnabled: false,
        pausedUntil: DateTime.tryParse(row['pausado_ate']?.toString() ?? ''),
      ),
    ),
  );
}

String _sourceToWire(SupportSignalSource source) => switch (source) {
  SupportSignalSource.moodHistory => 'mood_history',
  SupportSignalSource.diaryTags => 'diary_topics',
  SupportSignalSource.exerciseFeedback => 'exercise_feedback',
  SupportSignalSource.notificationInteractions => 'notification_interactions',
};

SupportSignalSource? _sourceFromWire(String value) => switch (value) {
  'mood_history' => SupportSignalSource.moodHistory,
  'diary_topics' => SupportSignalSource.diaryTags,
  'exercise_feedback' => SupportSignalSource.exerciseFeedback,
  'notification_interactions' => SupportSignalSource.notificationInteractions,
  _ => null,
};

String _categoryToWire(SupportSuggestionCategory category) =>
    switch (category) {
      SupportSuggestionCategory.reflection => 'reflection',
      SupportSuggestionCategory.exercise => 'exercise',
      SupportSuggestionCategory.video => 'video',
      SupportSuggestionCategory.humanConnection => 'human_connection',
      SupportSuggestionCategory.professionalConversation =>
        'professional_conversation',
    };

SupportSuggestionCategory? _categoryFromWire(String value) => switch (value) {
  'reflection' => SupportSuggestionCategory.reflection,
  'exercise' => SupportSuggestionCategory.exercise,
  'video' => SupportSuggestionCategory.video,
  'human_connection' => SupportSuggestionCategory.humanConnection,
  'professional_conversation' =>
    SupportSuggestionCategory.professionalConversation,
  _ => null,
};

String _contentTagToWire(SupportContentTag tag) => switch (tag) {
  SupportContentTag.breathingFocused => 'breathing_focused',
  SupportContentTag.audioRequired => 'audio_required',
  SupportContentTag.animation => 'animation',
  SupportContentTag.bodyTouch => 'body_touch',
};

SupportContentTag? _contentTagFromWire(String value) => switch (value) {
  'breathing_focused' => SupportContentTag.breathingFocused,
  'audio_required' => SupportContentTag.audioRequired,
  'animation' => SupportContentTag.animation,
  'body_touch' => SupportContentTag.bodyTouch,
  _ => null,
};

NotificationFrequency _frequencyFromWeeklyMaximum(int value) => switch (value) {
  1 => NotificationFrequency.oncePerWeek,
  2 => NotificationFrequency.twicePerWeek,
  >= 3 => NotificationFrequency.threeTimesPerWeek,
  _ => NotificationFrequency.never,
};

String _timeToWire(SupportTimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

SupportTimeOfDay? _timeFromWire(Object? value) {
  final parts = value?.toString().split(':') ?? const <String>[];
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return SupportTimeOfDay(hour, minute);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}

List<int> _integerList(Object? value) {
  if (value is! List) return const <int>[];
  return value.map(_integer).whereType<int>().toList(growable: false);
}

int? _integer(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

String? _nonEmpty(Object? value) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? null : parsed;
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();
