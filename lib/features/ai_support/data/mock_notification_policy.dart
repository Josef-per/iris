import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_candidate.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

/// Limites conservadores do simulador. Não representam recomendação clínica.
class NotificationPolicyConfiguration {
  const NotificationPolicyConfiguration({
    this.dailyLimit = 1,
    this.maximumWeeklyLimit = 3,
    this.dismissalCooldown = const Duration(days: 1),
    this.negativeFeedbackCooldown = const Duration(days: 3),
    this.duplicateContentCooldown = const Duration(days: 7),
    this.automaticPauseDuration = const Duration(days: 7),
    this.dismissalsBeforeAutomaticPause = 3,
  }) : assert(dailyLimit > 0),
       assert(maximumWeeklyLimit > 0),
       assert(dismissalsBeforeAutomaticPause > 0);

  final int dailyLimit;
  final int maximumWeeklyLimit;
  final Duration dismissalCooldown;
  final Duration negativeFeedbackCooldown;
  final Duration duplicateContentCooldown;
  final Duration automaticPauseDuration;
  final int dismissalsBeforeAutomaticPause;
}

/// Entrada integral da política, mantida localmente no protótipo.
class NotificationPolicyInput {
  const NotificationPolicyInput({
    required this.consent,
    required this.preferences,
    required this.suggestion,
    required this.candidate,
    required this.deliveries,
    required this.feedback,
    required this.now,
    this.isRiskDemonstration = false,
  });

  final AiSupportConsent consent;
  final AiSupportPreferences preferences;
  final SupportSuggestion suggestion;
  final NotificationCandidate candidate;
  final Iterable<NotificationDeliveryRecord> deliveries;
  final Iterable<SuggestionFeedback> feedback;
  final DateTime now;
  final bool isRiskDemonstration;
}

enum NotificationPolicyBlockReason {
  consentNotGranted,
  sourceNotGranted,
  riskDemonstration,
  templateNotApproved,
  invalidCandidate,
  categoryNotAllowed,
  notificationsDisabled,
  paused,
  outsideWindow,
  dailyLimitReached,
  weeklyLimitReached,
  cooldownActive,
  automaticPause,
  duplicateContent,
  expired,
}

/// Decisão pura: o chamador pode colocar o candidato no simulador ou silenciar.
class NotificationPolicyResult {
  const NotificationPolicyResult.allowed(this.candidate)
    : blockReason = null,
      automaticPauseUntil = null;

  const NotificationPolicyResult.blocked(
    this.blockReason, {
    this.automaticPauseUntil,
  }) : candidate = null;

  final NotificationCandidate? candidate;
  final NotificationPolicyBlockReason? blockReason;

  /// Quando presente, o estado chamador deve salvar uma pausa local.
  final DateTime? automaticPauseUntil;

  bool get canDeliver => candidate != null;
}

abstract interface class AiSupportNotificationPolicy {
  NotificationPolicyResult evaluate(NotificationPolicyInput input);
}

/// Regras locais que decidem se um candidato já seguro pode ser simulado.
class MockNotificationPolicy implements AiSupportNotificationPolicy {
  const MockNotificationPolicy({
    this.catalog = MockSupportTemplateCatalog.catalog,
    this.configuration = const NotificationPolicyConfiguration(),
  });

  final SupportCatalog catalog;
  final NotificationPolicyConfiguration configuration;

  @override
  NotificationPolicyResult evaluate(NotificationPolicyInput input) {
    if (!input.consent.personalizedSuggestionsGranted) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.consentNotGranted,
      );
    }
    for (final source in input.suggestion.usedSources) {
      if (!input.consent.allowsSource(source)) {
        return const NotificationPolicyResult.blocked(
          NotificationPolicyBlockReason.sourceNotGranted,
        );
      }
    }
    if (input.isRiskDemonstration) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.riskDemonstration,
      );
    }
    if (!_hasApprovedCatalogEntry(input)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.templateNotApproved,
      );
    }
    if (input.candidate.suggestionId != input.suggestion.id ||
        input.candidate.templateId != input.suggestion.templateId) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.invalidCandidate,
      );
    }
    if (input.candidate.isExpiredAt(input.now) ||
        input.suggestion.isExpiredAt(input.now)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.expired,
      );
    }
    if (!input.preferences.allowsCategory(input.suggestion.category)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.categoryNotAllowed,
      );
    }

    final notificationPreferences = input.preferences.notifications;
    if (!notificationPreferences.allowsDelivery) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.notificationsDisabled,
      );
    }
    if (notificationPreferences.isPausedAt(input.now)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.paused,
      );
    }

    final automaticPause = automaticPauseUntil(input.feedback, input.now);
    if (automaticPause != null) {
      return NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.automaticPause,
        automaticPauseUntil: automaticPause,
      );
    }
    if (!notificationPreferences.window.contains(input.now)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.outsideWindow,
      );
    }

    final pastDeliveries = input.deliveries
        .where((delivery) => !delivery.deliveredAt.isAfter(input.now))
        .toList(growable: false);
    final dailyCount = pastDeliveries.where(
      (delivery) => _sameLocalDay(delivery.deliveredAt, input.now),
    );
    if (dailyCount.length >= configuration.dailyLimit) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.dailyLimitReached,
      );
    }

    final weeklyLimit =
        notificationPreferences.frequency.maxPerWeek <
            configuration.maximumWeeklyLimit
        ? notificationPreferences.frequency.maxPerWeek
        : configuration.maximumWeeklyLimit;
    final weeklyCount = pastDeliveries.where(
      (delivery) => _sameLocalWeek(delivery.deliveredAt, input.now),
    );
    if (weeklyCount.length >= weeklyLimit) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.weeklyLimitReached,
      );
    }

    if (_hasActiveCooldown(input.feedback, input.now)) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.cooldownActive,
      );
    }
    final duplicate = pastDeliveries.any(
      (delivery) =>
          delivery.templateId == input.candidate.templateId &&
          input.now.difference(delivery.deliveredAt) <
              configuration.duplicateContentCooldown,
    );
    if (duplicate) {
      return const NotificationPolicyResult.blocked(
        NotificationPolicyBlockReason.duplicateContent,
      );
    }
    return NotificationPolicyResult.allowed(input.candidate);
  }

  /// Pausa sugerida quando os últimos eventos relevantes são dispensas.
  DateTime? automaticPauseUntil(
    Iterable<SuggestionFeedback> feedback,
    DateTime now,
  ) {
    final events =
        feedback
            .where((event) => !event.createdAt.isAfter(now))
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (events.length < configuration.dismissalsBeforeAutomaticPause ||
        !events
            .take(configuration.dismissalsBeforeAutomaticPause)
            .every((event) => event.isDismissal)) {
      return null;
    }
    final latestDismissal = events.first.createdAt;
    final until = latestDismissal.add(configuration.automaticPauseDuration);
    return now.isBefore(until) ? until : null;
  }

  bool _hasApprovedCatalogEntry(NotificationPolicyInput input) {
    final template = catalog.templateById(input.candidate.templateId);
    final generic = catalog.genericNotificationById(
      input.candidate.genericNotificationTemplateId,
    );
    return template != null &&
        template.status == SupportContentStatus.approved &&
        generic != null &&
        template.genericNotificationTemplateId ==
            input.candidate.genericNotificationTemplateId;
  }

  bool _hasActiveCooldown(Iterable<SuggestionFeedback> feedback, DateTime now) {
    for (final event in feedback) {
      if (!event.triggersCooldown || event.createdAt.isAfter(now)) continue;
      final cooldown = event.isDismissal
          ? configuration.dismissalCooldown
          : configuration.negativeFeedbackCooldown;
      if (now.isBefore(event.createdAt.add(cooldown))) return true;
    }
    return false;
  }

  bool _sameLocalDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _sameLocalWeek(DateTime first, DateTime second) {
    return _mondayFor(first) == _mondayFor(second);
  }

  DateTime _mondayFor(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    return midnight.subtract(Duration(days: date.weekday - DateTime.monday));
  }
}
