import 'ai_support_consent.dart';
import 'ai_support_preferences.dart';

/// Situação de aprovação de um item do catálogo fechado.
enum SupportContentStatus { draft, approved, retired }

extension SupportContentStatusLabel on SupportContentStatus {
  String get label => switch (this) {
    SupportContentStatus.draft => 'Rascunho',
    SupportContentStatus.approved => 'Aprovado',
    SupportContentStatus.retired => 'Retirado',
  };
}

/// Códigos de motivo fechados, mostrados depois como explicações revisadas.
enum SupportReasonCode {
  todayDifficultCheckIn,
  todaySteadyCheckIn,
  todayLighterCheckIn,
  recentDifficultCheckIns,
  prefersShortPractice,
  confirmedOverload,
  confirmedLoneliness,
  confirmedSelfKindness,
  preferredFromPastInteractions,
  previousExerciseWasNotHelpful,
}

extension SupportReasonCodeWire on SupportReasonCode {
  String get wireName => switch (this) {
    SupportReasonCode.todayDifficultCheckIn => 'TODAY_DIFFICULT_CHECKIN',
    SupportReasonCode.todaySteadyCheckIn => 'TODAY_STEADY_CHECKIN',
    SupportReasonCode.todayLighterCheckIn => 'TODAY_LIGHTER_CHECKIN',
    SupportReasonCode.recentDifficultCheckIns => 'RECENT_DIFFICULT_CHECKINS',
    SupportReasonCode.prefersShortPractice => 'PREFERS_SHORT_PRACTICE',
    SupportReasonCode.confirmedOverload => 'CONFIRMED_OVERLOAD',
    SupportReasonCode.confirmedLoneliness => 'CONFIRMED_LONELINESS',
    SupportReasonCode.confirmedSelfKindness => 'CONFIRMED_SELF_KINDNESS',
    SupportReasonCode.preferredFromPastInteractions =>
      'PREFERRED_FROM_PAST_INTERACTIONS',
    SupportReasonCode.previousExerciseWasNotHelpful =>
      'PREVIOUS_EXERCISE_WAS_NOT_HELPFUL',
  };

  static SupportReasonCode? fromWireName(String value) {
    for (final code in SupportReasonCode.values) {
      if (code.wireName == value) return code;
    }
    return null;
  }
}

enum ConfidenceBand { low, medium, high }

extension ConfidenceBandLabel on ConfidenceBand {
  String get label => switch (this) {
    ConfidenceBand.low => 'Baixa',
    ConfidenceBand.medium => 'Média',
    ConfidenceBand.high => 'Alta',
  };
}

extension ConfidenceBandWire on ConfidenceBand {
  String get wireName => name;

  static ConfidenceBand? fromWireName(String value) {
    for (final band in ConfidenceBand.values) {
      if (band.wireName == value) return band;
    }
    return null;
  }
}

/// Template revisado e versionado, sem qualquer geração de texto em runtime.
class SupportSuggestionTemplate {
  const SupportSuggestionTemplate({
    required this.id,
    required this.category,
    required this.version,
    required this.status,
    required this.inAppTitle,
    required this.inAppBody,
    required this.genericNotificationTemplateId,
    required this.allowedReasonCodes,
    this.exerciseId,
    this.contentTags = const <SupportContentTag>{},
    required this.approvedBy,
  });

  final String id;
  final SupportSuggestionCategory category;
  final String version;
  final SupportContentStatus status;

  /// Texto fixo e revisado, para uso somente depois de abrir o aplicativo.
  final String inAppTitle;
  final String inAppBody;

  /// ID de um texto genérico para tela bloqueada, nunca personalizado.
  final String genericNotificationTemplateId;
  final Set<SupportReasonCode> allowedReasonCodes;
  final String? exerciseId;
  final Set<SupportContentTag> contentTags;
  final String approvedBy;
}

/// Referência mínima a um exercício aprovado de outro catálogo local.
class SupportExerciseReference {
  const SupportExerciseReference({
    required this.id,
    required this.status,
    required this.durationMinutes,
    this.contentTags = const <SupportContentTag>{},
  });

  final String id;
  final SupportContentStatus status;
  final int durationMinutes;
  final Set<SupportContentTag> contentTags;
}

/// Saída estruturada permitida para um recomendador.
///
/// Ela não possui campos de texto, contato, diagnóstico, horário ou comando
/// de entrega.
class AiSupportRecommendationProposal {
  const AiSupportRecommendationProposal({
    required this.suggestionTemplateId,
    required this.reasonCodes,
    required this.confidenceBand,
    this.exerciseId,
  });

  final String suggestionTemplateId;
  final String? exerciseId;
  final Set<SupportReasonCode> reasonCodes;
  final ConfidenceBand confidenceBand;
}

/// Sugestão aceita pelo validador e pronta para ser mostrada dentro do app.
class SupportSuggestion {
  const SupportSuggestion({
    required this.id,
    required this.templateId,
    required this.category,
    required this.reasonCodes,
    required this.confidenceBand,
    required this.usedSources,
    required this.createdAt,
    required this.expiresAt,
    this.exerciseId,
  });

  /// Identificador opaco local, seguro para um deep link futuro.
  final String id;
  final String templateId;
  final SupportSuggestionCategory category;
  final String? exerciseId;
  final Set<SupportReasonCode> reasonCodes;
  final ConfidenceBand confidenceBand;
  final Set<SupportSignalSource> usedSources;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

enum RecommendationRejectionReason {
  invalidSchema,
  unknownTemplate,
  templateNotApproved,
  categoryNotAllowed,
  confidenceTooLow,
  missingReasonCode,
  unsupportedReasonCode,
  unknownExercise,
  exerciseNotApproved,
  exerciseDoesNotMatchTemplate,
  contentExcluded,
  exerciseTooLong,
}

/// Resultado auditável de uma validação; uma rejeição produz silêncio.
class RecommendationValidationResult {
  const RecommendationValidationResult.accepted(this.suggestion)
    : rejectionReason = null;

  const RecommendationValidationResult.rejected(this.rejectionReason)
    : suggestion = null;

  final SupportSuggestion? suggestion;
  final RecommendationRejectionReason? rejectionReason;

  bool get isAccepted => suggestion != null;
}
