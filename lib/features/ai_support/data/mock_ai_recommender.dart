import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

/// Contexto estruturado aceito pelo recomendador local.
///
/// Não há texto de diário, contatos, diagnóstico ou qualquer instrução livre.
class AiSupportRecommendationContext {
  const AiSupportRecommendationContext({
    required this.consent,
    required this.preferences,
    required this.signals,
    required this.now,
    this.isRiskDemonstration = false,
  });

  final AiSupportConsent consent;
  final AiSupportPreferences preferences;
  final Iterable<SupportSignal> signals;
  final DateTime now;

  /// Cenários de demonstração de risco não participam de recomendações.
  final bool isRiskDemonstration;
}

enum RecommendationSkipReason {
  consentNotGranted,
  personalizationDisabled,
  riskDemonstration,
  noUsableSignals,
  noAllowedCategory,
  allCandidatesRejected,
}

/// Resultado do recomendador. [suggestion] nula significa silêncio seguro.
class AiSupportRecommendationResult {
  const AiSupportRecommendationResult.suggested({
    required this.suggestion,
    required this.validation,
  }) : skipReason = null;

  const AiSupportRecommendationResult.skipped(this.skipReason)
    : suggestion = null,
      validation = null;

  final SupportSuggestion? suggestion;
  final RecommendationValidationResult? validation;
  final RecommendationSkipReason? skipReason;

  bool get hasSuggestion => suggestion != null;
}

abstract interface class AiSupportRecommender {
  AiSupportRecommendationResult recommend(AiSupportRecommendationContext input);
}

/// Validador estrito entre uma proposta estruturada e o catálogo fechado.
class AiSupportRecommendationValidator {
  const AiSupportRecommendationValidator({
    this.catalog = MockSupportTemplateCatalog.catalog,
    this.minimumConfidence = ConfidenceBand.medium,
    this.defaultLifetime = const Duration(hours: 24),
  });

  final SupportCatalog catalog;
  final ConfidenceBand minimumConfidence;
  final Duration defaultLifetime;

  RecommendationValidationResult validate(
    AiSupportRecommendationProposal proposal, {
    required AiSupportPreferences preferences,
    required Set<SupportSignalSource> usedSources,
    required DateTime createdAt,
    DateTime? expiresAt,
    String? suggestionId,
  }) {
    final template = catalog.templateById(proposal.suggestionTemplateId);
    if (template == null) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.unknownTemplate,
      );
    }
    if (template.status != SupportContentStatus.approved ||
        catalog.genericNotificationById(
              template.genericNotificationTemplateId,
            ) ==
            null) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.templateNotApproved,
      );
    }
    if (!preferences.allowsCategory(template.category)) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.categoryNotAllowed,
      );
    }
    if (proposal.confidenceBand.index < minimumConfidence.index) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.confidenceTooLow,
      );
    }
    if (proposal.reasonCodes.isEmpty) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.missingReasonCode,
      );
    }
    if (!template.allowedReasonCodes.containsAll(proposal.reasonCodes)) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.unsupportedReasonCode,
      );
    }
    if (!preferences.allowsContentTags(template.contentTags)) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.contentExcluded,
      );
    }

    final expectedExerciseId = template.exerciseId;
    if (expectedExerciseId != proposal.exerciseId) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.exerciseDoesNotMatchTemplate,
      );
    }
    if (proposal.exerciseId != null) {
      final exercise = catalog.exerciseById(proposal.exerciseId!);
      if (exercise == null) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.unknownExercise,
        );
      }
      if (exercise.status != SupportContentStatus.approved) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.exerciseNotApproved,
        );
      }
      if (exercise.durationMinutes > preferences.maximumExerciseMinutes) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.exerciseTooLong,
        );
      }
      if (!preferences.allowsContentTags(exercise.contentTags)) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.contentExcluded,
        );
      }
    }

    final expiry = expiresAt ?? createdAt.add(defaultLifetime);
    if (!expiry.isAfter(createdAt)) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.invalidSchema,
      );
    }
    return RecommendationValidationResult.accepted(
      SupportSuggestion(
        id:
            suggestionId ??
            _opaqueSuggestionId(proposal.suggestionTemplateId, createdAt),
        templateId: template.id,
        category: template.category,
        exerciseId: proposal.exerciseId,
        reasonCodes: proposal.reasonCodes,
        confidenceBand: proposal.confidenceBand,
        usedSources: usedSources,
        createdAt: createdAt,
        expiresAt: expiry,
      ),
    );
  }

  /// Valida a fronteira com uma saída não confiável e rejeita campos extras.
  RecommendationValidationResult validateUntrustedPayload(
    Map<String, Object?> payload, {
    required AiSupportPreferences preferences,
    required Set<SupportSignalSource> usedSources,
    required DateTime createdAt,
    DateTime? expiresAt,
    String? suggestionId,
  }) {
    const allowedFields = <String>{
      'suggestionTemplateId',
      'exerciseId',
      'reasonCodes',
      'confidenceBand',
    };
    const requiredFields = <String>{
      'suggestionTemplateId',
      'reasonCodes',
      'confidenceBand',
    };
    if (!payload.keys.every(allowedFields.contains) ||
        !payload.keys.toSet().containsAll(requiredFields)) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.invalidSchema,
      );
    }

    final templateId = payload['suggestionTemplateId'];
    final exerciseId = payload['exerciseId'];
    final rawReasons = payload['reasonCodes'];
    final rawConfidence = payload['confidenceBand'];
    if (templateId is! String ||
        templateId.isEmpty ||
        (exerciseId != null && exerciseId is! String) ||
        rawReasons is! List ||
        rawConfidence is! String) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.invalidSchema,
      );
    }
    final reasons = <SupportReasonCode>{};
    for (final rawReason in rawReasons) {
      if (rawReason is! String) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.invalidSchema,
        );
      }
      final reason = SupportReasonCodeWire.fromWireName(rawReason);
      if (reason == null) {
        return const RecommendationValidationResult.rejected(
          RecommendationRejectionReason.invalidSchema,
        );
      }
      reasons.add(reason);
    }
    if (reasons.length != rawReasons.length) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.invalidSchema,
      );
    }
    final confidence = ConfidenceBandWire.fromWireName(rawConfidence);
    if (confidence == null) {
      return const RecommendationValidationResult.rejected(
        RecommendationRejectionReason.invalidSchema,
      );
    }

    return validate(
      AiSupportRecommendationProposal(
        suggestionTemplateId: templateId,
        exerciseId: exerciseId as String?,
        reasonCodes: reasons,
        confidenceBand: confidence,
      ),
      preferences: preferences,
      usedSources: usedSources,
      createdAt: createdAt,
      expiresAt: expiresAt,
      suggestionId: suggestionId,
    );
  }

  String _opaqueSuggestionId(String templateId, DateTime createdAt) {
    var hash = 5381;
    for (final unit in templateId.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    final timestamp = createdAt.toUtc().millisecondsSinceEpoch.toRadixString(
      36,
    );
    return 'support-$timestamp-${hash.abs().toRadixString(36)}';
  }
}

/// Recomendador de regras locais, reproduzível e restrito ao catálogo.
class MockAiRecommender implements AiSupportRecommender {
  MockAiRecommender({AiSupportRecommendationValidator? validator})
    : _validator = validator ?? const AiSupportRecommendationValidator();

  final AiSupportRecommendationValidator _validator;

  @override
  AiSupportRecommendationResult recommend(
    AiSupportRecommendationContext input,
  ) {
    if (!input.consent.personalizedSuggestionsGranted) {
      return const AiSupportRecommendationResult.skipped(
        RecommendationSkipReason.consentNotGranted,
      );
    }
    if (!input.preferences.personalizedSuggestionsEnabled) {
      return const AiSupportRecommendationResult.skipped(
        RecommendationSkipReason.personalizationDisabled,
      );
    }
    if (input.isRiskDemonstration) {
      return const AiSupportRecommendationResult.skipped(
        RecommendationSkipReason.riskDemonstration,
      );
    }

    final usable = input.signals
        .where((signal) => signal.isUsableAt(input.now))
        .where((signal) => input.consent.allowsSource(signal.source))
        .toList(growable: false);
    if (usable.isEmpty) {
      return const AiSupportRecommendationResult.skipped(
        RecommendationSkipReason.noUsableSignals,
      );
    }

    final seeds = _seedsFor(usable, input.preferences);
    if (seeds.isEmpty) {
      return const AiSupportRecommendationResult.skipped(
        RecommendationSkipReason.noAllowedCategory,
      );
    }

    RecommendationValidationResult? lastValidation;
    for (final seed in seeds) {
      final validation = _validator.validate(
        seed.proposal,
        preferences: input.preferences,
        usedSources: seed.usedSources,
        createdAt: input.now,
      );
      if (validation.isAccepted) {
        return AiSupportRecommendationResult.suggested(
          suggestion: validation.suggestion!,
          validation: validation,
        );
      }
      lastValidation = validation;
    }
    return AiSupportRecommendationResult.skipped(
      lastValidation == null
          ? RecommendationSkipReason.noAllowedCategory
          : RecommendationSkipReason.allCandidatesRejected,
    );
  }

  /// Conveniência para consumidores que só precisam da sugestão ou silêncio.
  SupportSuggestion? recommendSuggestion(AiSupportRecommendationContext input) {
    return recommend(input).suggestion;
  }

  List<_ProposalSeed> _seedsFor(
    List<SupportSignal> signals,
    AiSupportPreferences preferences,
  ) {
    final result = <_ProposalSeed>[];
    final negativeExercise = _latestNegativeExercise(signals);
    final loneliness = _latestConfirmedTopic(
      signals,
      SupportTopicKey.loneliness,
    );
    final difficultMood = _latestDifficultMood(signals);
    final overload = _latestConfirmedTopic(signals, SupportTopicKey.overload);

    if (negativeExercise != null &&
        preferences.allowsCategory(SupportSuggestionCategory.humanConnection)) {
      result.add(
        const _ProposalSeed(
          proposal: AiSupportRecommendationProposal(
            suggestionTemplateId: 'connection_after_exercise_feedback_v1',
            reasonCodes: <SupportReasonCode>{
              SupportReasonCode.previousExerciseWasNotHelpful,
            },
            confidenceBand: ConfidenceBand.high,
          ),
          usedSources: <SupportSignalSource>{
            SupportSignalSource.exerciseFeedback,
          },
        ),
      );
    }
    if (loneliness != null &&
        preferences.allowsCategory(SupportSuggestionCategory.humanConnection)) {
      result.add(
        const _ProposalSeed(
          proposal: AiSupportRecommendationProposal(
            suggestionTemplateId: 'connection_loneliness_v1',
            reasonCodes: <SupportReasonCode>{
              SupportReasonCode.confirmedLoneliness,
            },
            confidenceBand: ConfidenceBand.high,
          ),
          usedSources: <SupportSignalSource>{SupportSignalSource.diaryTags},
        ),
      );
    }
    if (difficultMood != null && negativeExercise == null) {
      if (preferences.allowsCategory(SupportSuggestionCategory.exercise)) {
        result.add(
          const _ProposalSeed(
            proposal: AiSupportRecommendationProposal(
              suggestionTemplateId: 'exercise_difficult_checkins_v1',
              exerciseId: 'anchor-present',
              reasonCodes: <SupportReasonCode>{
                SupportReasonCode.recentDifficultCheckIns,
                SupportReasonCode.prefersShortPractice,
              },
              confidenceBand: ConfidenceBand.medium,
            ),
            usedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
          ),
        );
      }
    }
    if (difficultMood != null &&
        preferences.allowsCategory(SupportSuggestionCategory.reflection)) {
      result.add(
        const _ProposalSeed(
          proposal: AiSupportRecommendationProposal(
            suggestionTemplateId: 'reflection_difficult_checkins_v1',
            reasonCodes: <SupportReasonCode>{
              SupportReasonCode.recentDifficultCheckIns,
            },
            confidenceBand: ConfidenceBand.medium,
          ),
          usedSources: <SupportSignalSource>{SupportSignalSource.moodHistory},
        ),
      );
    }
    if (overload != null &&
        preferences.allowsCategory(SupportSuggestionCategory.reflection)) {
      result.add(
        const _ProposalSeed(
          proposal: AiSupportRecommendationProposal(
            suggestionTemplateId: 'reflection_overload_v1',
            reasonCodes: <SupportReasonCode>{
              SupportReasonCode.confirmedOverload,
            },
            confidenceBand: ConfidenceBand.high,
          ),
          usedSources: <SupportSignalSource>{SupportSignalSource.diaryTags},
        ),
      );
    }
    return result;
  }

  ExerciseFeedbackSignal? _latestNegativeExercise(List<SupportSignal> signals) {
    return _latest<ExerciseFeedbackSignal>(
      signals.whereType<ExerciseFeedbackSignal>().where(
        (signal) => signal.isNegative,
      ),
    );
  }

  ConfirmedTopicSignal? _latestConfirmedTopic(
    List<SupportSignal> signals,
    SupportTopicKey topic,
  ) {
    return _latest<ConfirmedTopicSignal>(
      signals.whereType<ConfirmedTopicSignal>().where(
        (signal) => signal.isConfirmed && signal.topic == topic,
      ),
    );
  }

  MoodTrendSignal? _latestDifficultMood(List<SupportSignal> signals) {
    return _latest<MoodTrendSignal>(
      signals.whereType<MoodTrendSignal>().where(
        (signal) => signal.hasRecentDifficultPattern,
      ),
    );
  }

  T? _latest<T extends SupportSignal>(Iterable<T> signals) {
    T? selected;
    for (final signal in signals) {
      if (selected == null || signal.createdAt.isAfter(selected.createdAt)) {
        selected = signal;
      }
    }
    return selected;
  }
}

class _ProposalSeed {
  const _ProposalSeed({required this.proposal, required this.usedSources});

  final AiSupportRecommendationProposal proposal;
  final Set<SupportSignalSource> usedSources;
}
