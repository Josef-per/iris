import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/mock_diary_signals.dart';
import 'package:iris/features/ai_support/data/mock_notification_policy.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_candidate.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

/// Estado local e descartável para a interface da Fase 1.
///
/// Não pede permissões, não agenda push, não usa Supabase e não aceita texto
/// livre. O "inbox" é somente uma simulação em memória.
class MockAiSupportStore extends ChangeNotifier {
  MockAiSupportStore({
    DateTime Function()? clock,
    AiSupportConsent consent = AiSupportConsent.none,
    AiSupportPreferences preferences = AiSupportPreferences.defaults,
    List<MockAiSupportScenario>? scenarios,
    MockAiRecommender? recommender,
    MockNotificationPolicy? notificationPolicy,
  }) : _clock = clock ?? DateTime.now,
       _consent = consent,
       _preferences = preferences,
       _recommender = recommender ?? MockAiRecommender(),
       _notificationPolicy =
           notificationPolicy ?? const MockNotificationPolicy() {
    _scenarios = scenarios ?? MockDiarySignals.scenarios(_clock());
    if (_scenarios.isEmpty) {
      throw ArgumentError.value(
        scenarios,
        'scenarios',
        'Informe ao menos um cenário.',
      );
    }
    _selectedScenario = _scenarios.first;
    _signals = List<SupportSignal>.from(_selectedScenario.signals);
    _isOnboarded =
        consent.personalizedSuggestionsGranted ||
        preferences.personalizedSuggestionsEnabled;
  }

  final DateTime Function() _clock;
  final MockAiRecommender _recommender;
  final MockNotificationPolicy _notificationPolicy;

  late final List<MockAiSupportScenario> _scenarios;
  late MockAiSupportScenario _selectedScenario;
  late List<SupportSignal> _signals;

  AiSupportConsent _consent;
  AiSupportPreferences _preferences;
  bool _isOnboarded = false;
  SupportSuggestion? _pendingSuggestion;
  NotificationCandidate? _pendingNotificationCandidate;
  NotificationPolicyResult? _lastNotificationDecision;

  final List<SupportSuggestion> _suggestionInbox = <SupportSuggestion>[];
  final List<NotificationCandidate> _notificationCandidates =
      <NotificationCandidate>[];
  final List<NotificationDeliveryRecord> _deliveries =
      <NotificationDeliveryRecord>[];
  final List<SuggestionFeedback> _feedback = <SuggestionFeedback>[];
  int _nextSequence = 1;

  AiSupportConsent get consent => _consent;
  AiSupportPreferences get preferences => _preferences;
  bool get isOnboarded => _isOnboarded;
  bool get isPersonalizationEnabled {
    return _consent.personalizedSuggestionsGranted &&
        _preferences.personalizedSuggestionsEnabled;
  }

  bool get isPaused => _preferences.notifications.isPausedAt(_clock());

  UnmodifiableListView<MockAiSupportScenario> get scenarios {
    return UnmodifiableListView<MockAiSupportScenario>(_scenarios);
  }

  MockAiSupportScenario get selectedScenario => _selectedScenario;

  /// Sinais ainda existentes e autorizados para o cenário atual.
  UnmodifiableListView<SupportSignal> get activeSignals {
    final now = _clock();
    return UnmodifiableListView<SupportSignal>(
      _signals
          .where((signal) => signal.isUsableAt(now))
          .where((signal) => _consent.allowsSource(signal.source))
          .toList(growable: false),
    );
  }

  SupportSuggestion? get pendingSuggestion {
    final suggestion = _pendingSuggestion;
    if (suggestion == null || suggestion.isExpiredAt(_clock())) return null;
    return suggestion;
  }

  NotificationCandidate? get pendingNotificationCandidate {
    final candidate = _pendingNotificationCandidate;
    if (candidate == null || candidate.isExpiredAt(_clock())) return null;
    return candidate;
  }

  /// Alias curto para o último candidato aprovado pela política.
  NotificationCandidate? get latestCandidate {
    final now = _clock();
    for (final candidate in _notificationCandidates.reversed) {
      if (!candidate.isExpiredAt(now)) return candidate;
    }
    return null;
  }

  UnmodifiableListView<NotificationCandidate> get notificationCandidates {
    final now = _clock();
    return UnmodifiableListView<NotificationCandidate>(
      _notificationCandidates
          .where((candidate) => !candidate.isExpiredAt(now))
          .toList(growable: false),
    );
  }

  UnmodifiableListView<SupportSuggestion> get suggestionInbox {
    final now = _clock();
    return UnmodifiableListView<SupportSuggestion>(
      _suggestionInbox
          .where((suggestion) => !suggestion.isExpiredAt(now))
          .toList(growable: false),
    );
  }

  UnmodifiableListView<SuggestionFeedback> get feedback {
    return UnmodifiableListView<SuggestionFeedback>(_feedback);
  }

  NotificationPolicyResult? get lastNotificationDecision {
    return _lastNotificationDecision;
  }

  /// Configurar consentimento também conclui o onboarding fictício.
  void configureConsent(AiSupportConsent value) {
    final revokeAll =
        _consent.personalizedSuggestionsGranted &&
        !value.personalizedSuggestionsGranted;
    final revokedSources = <SupportSignalSource>{
      ..._consent.grantedSources.where(
        (source) => !value.grantedSources.contains(source),
      ),
    };
    _consent = value;
    _isOnboarded = true;
    if (revokeAll) {
      _clearAllDerivedData();
    } else {
      for (final source in revokedSources) {
        _removeSourceData(source);
      }
    }
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  /// Configurar preferências também conclui o onboarding fictício.
  void configurePreferences(AiSupportPreferences value) {
    _preferences = value;
    _isOnboarded = true;
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void completeOnboarding({
    required AiSupportConsent consent,
    required AiSupportPreferences preferences,
  }) {
    final revokeAll =
        _consent.personalizedSuggestionsGranted &&
        !consent.personalizedSuggestionsGranted;
    final revokedSources = <SupportSignalSource>{
      ..._consent.grantedSources.where(
        (source) => !consent.grantedSources.contains(source),
      ),
    };
    _consent = consent;
    _preferences = preferences;
    _isOnboarded = true;
    if (revokeAll) {
      _clearAllDerivedData();
    } else {
      for (final source in revokedSources) {
        _removeSourceData(source);
      }
    }
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void selectScenario(String scenarioId) {
    final scenario = _scenarios.where((item) => item.id == scenarioId);
    if (scenario.isEmpty) {
      throw ArgumentError.value(
        scenarioId,
        'scenarioId',
        'Cenário desconhecido.',
      );
    }
    _selectedScenario = scenario.first;
    _signals = List<SupportSignal>.from(_selectedScenario.signals);
    _pendingSuggestion = null;
    _pendingNotificationCandidate = null;
    _lastNotificationDecision = null;
    notifyListeners();
  }

  void setSourceConsent(SupportSignalSource source, bool granted) {
    final sources = <SupportSignalSource>{..._consent.grantedSources};
    if (granted) {
      sources.add(source);
    } else {
      sources.remove(source);
      _removeSourceData(source);
    }
    _consent = _consent.copyWith(grantedSources: sources);
    _isOnboarded = true;
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void setPersonalizationEnabled(bool enabled) {
    _preferences = _preferences.copyWith(
      personalizedSuggestionsEnabled: enabled,
    );
    if (!enabled) {
      _pendingSuggestion = null;
      _pendingNotificationCandidate = null;
    }
    notifyListeners();
  }

  void configureNotifications(NotificationPreferences value) {
    _preferences = _preferences.copyWith(notifications: value);
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  /// Desativa sem apagar a escolha de consentimento. Use [revokeAllConsent]
  /// quando a pessoa quiser eliminar os sinais derivados deste cenário.
  void disablePersonalization() => setPersonalizationEnabled(false);

  void pauseFor(Duration duration, {DateTime? now}) {
    final at = now ?? _clock();
    _preferences = _preferences.copyWith(
      notifications: _preferences.notifications.withPauseUntil(
        at.add(duration),
      ),
    );
    _pendingNotificationCandidate = null;
    notifyListeners();
  }

  void resumeNotifications() {
    _preferences = _preferences.copyWith(
      notifications: _preferences.notifications.withPauseUntil(null),
    );
    notifyListeners();
  }

  void revokeSourceConsent(SupportSignalSource source) {
    final sources = <SupportSignalSource>{..._consent.grantedSources}
      ..remove(source);
    _consent = _consent.copyWith(grantedSources: sources);
    _removeSourceData(source);
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void revokeAllConsent() {
    _consent = _consent.revokeAll();
    _clearAllDerivedData();
    notifyListeners();
  }

  /// Cria uma sugestão local e, caso a política permita, a coloca no inbox
  /// simulado como candidato de notificação genérica.
  SupportSuggestion? generateSuggestion({DateTime? now}) {
    final at = now ?? _clock();
    final result = _recommender.recommend(
      AiSupportRecommendationContext(
        consent: _consent,
        preferences: _preferences,
        signals: _signals,
        now: at,
      ),
    );
    _pendingSuggestion = result.suggestion;
    _pendingNotificationCandidate = null;
    _lastNotificationDecision = null;

    final suggestion = result.suggestion;
    if (suggestion != null) {
      _addSuggestionToInbox(suggestion);
      _createCandidateForPendingSuggestion(at);
    }
    notifyListeners();
    return suggestion;
  }

  /// Reavalia somente a entrega para a sugestão pendente atual.
  NotificationPolicyResult? generateNotificationCandidate({DateTime? now}) {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) return null;
    final at = now ?? _clock();
    _createCandidateForPendingSuggestion(at);
    notifyListeners();
    return _lastNotificationDecision;
  }

  /// Registra feedback sem comentário livre e aplica a pausa automática.
  SuggestionFeedback? recordFeedback(
    SuggestionFeedbackType type, {
    SupportSuggestion? suggestion,
    DateTime? now,
  }) {
    final target = suggestion ?? _pendingSuggestion;
    if (target == null) return null;
    final at = now ?? _clock();
    final event = SuggestionFeedback(
      id: _nextOpaqueId('feedback', at),
      suggestionId: target.id,
      templateId: target.templateId,
      exerciseId: target.exerciseId,
      type: type,
      createdAt: at,
    );
    _feedback.add(event);

    if (type == SuggestionFeedbackType.doesNotMatch) {
      _signals.removeWhere(
        (signal) => target.usedSources.contains(signal.source),
      );
      _notificationCandidates.removeWhere(
        (candidate) => candidate.suggestionId == target.id,
      );
      _deliveries.removeWhere((delivery) => delivery.suggestionId == target.id);
      if (_pendingSuggestion?.id == target.id) {
        _pendingSuggestion = null;
        _pendingNotificationCandidate = null;
      }
    }
    final automaticPause = _notificationPolicy.automaticPauseUntil(
      _feedback,
      at,
    );
    if (automaticPause != null) {
      _preferences = _preferences.copyWith(
        notifications: _preferences.notifications.withPauseUntil(
          automaticPause,
        ),
      );
    }
    if (type == SuggestionFeedbackType.dismissed ||
        type == SuggestionFeedbackType.doesNotMatch ||
        type == SuggestionFeedbackType.notHelpful ||
        type == SuggestionFeedbackType.harmful) {
      _pendingNotificationCandidate = null;
    }
    notifyListeners();
    return event;
  }

  SuggestionFeedback? dismissLatestCandidate({DateTime? now}) {
    return recordFeedback(SuggestionFeedbackType.dismissed, now: now);
  }

  /// Remove um sinal derivado sem editar nenhum diário original.
  void discardSignal(String signalId) {
    _signals.removeWhere((signal) => signal.id == signalId);
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void _createCandidateForPendingSuggestion(DateTime at) {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) return;
    final template = MockSupportTemplateCatalog.catalog.templateById(
      suggestion.templateId,
    );
    if (template == null) return;
    final candidate = notificationCandidateForSuggestion(
      suggestion,
      candidateId: _nextOpaqueId('candidate', at),
      genericNotificationTemplateId: template.genericNotificationTemplateId,
    );
    final decision = _notificationPolicy.evaluate(
      NotificationPolicyInput(
        consent: _consent,
        preferences: _preferences,
        suggestion: suggestion,
        candidate: candidate,
        deliveries: _deliveries,
        feedback: _feedback,
        now: at,
      ),
    );
    _lastNotificationDecision = decision;
    if (!decision.canDeliver) {
      _pendingNotificationCandidate = null;
      final automaticPause = decision.automaticPauseUntil;
      if (automaticPause != null) {
        _preferences = _preferences.copyWith(
          notifications: _preferences.notifications.withPauseUntil(
            automaticPause,
          ),
        );
      }
      return;
    }
    _pendingNotificationCandidate = candidate;
    _notificationCandidates.add(candidate);
    _deliveries.add(
      NotificationDeliveryRecord(
        candidateId: candidate.id,
        suggestionId: suggestion.id,
        templateId: suggestion.templateId,
        deliveredAt: at,
      ),
    );
  }

  void _addSuggestionToInbox(SupportSuggestion suggestion) {
    if (_suggestionInbox.every((item) => item.id != suggestion.id)) {
      _suggestionInbox.add(suggestion);
    }
  }

  void _invalidatePendingForPreferences() {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) {
      _pendingNotificationCandidate = null;
      return;
    }
    final hasSourceConsent = suggestion.usedSources.every(
      _consent.allowsSource,
    );
    if (!isPersonalizationEnabled ||
        !hasSourceConsent ||
        !_preferences.allowsCategory(suggestion.category)) {
      _pendingSuggestion = null;
    }
    _pendingNotificationCandidate = null;
  }

  void _removeSourceData(SupportSignalSource source) {
    _signals.removeWhere((signal) => signal.source == source);
    final removedSuggestionIds = _suggestionInbox
        .where((suggestion) => suggestion.usedSources.contains(source))
        .map((suggestion) => suggestion.id)
        .toSet();
    _suggestionInbox.removeWhere(
      (suggestion) => removedSuggestionIds.contains(suggestion.id),
    );
    _notificationCandidates.removeWhere(
      (candidate) => removedSuggestionIds.contains(candidate.suggestionId),
    );
    _deliveries.removeWhere(
      (delivery) => removedSuggestionIds.contains(delivery.suggestionId),
    );
    _feedback.removeWhere(
      (event) => removedSuggestionIds.contains(event.suggestionId),
    );
    if (_pendingSuggestion != null &&
        _pendingSuggestion!.usedSources.contains(source)) {
      _pendingSuggestion = null;
      _pendingNotificationCandidate = null;
    }
  }

  void _clearAllDerivedData() {
    _signals.clear();
    _suggestionInbox.clear();
    _notificationCandidates.clear();
    _deliveries.clear();
    _feedback.clear();
    _pendingSuggestion = null;
    _pendingNotificationCandidate = null;
    _lastNotificationDecision = null;
  }

  String _nextOpaqueId(String prefix, DateTime at) {
    final sequence = _nextSequence++;
    final timestamp = at.toUtc().millisecondsSinceEpoch.toRadixString(36);
    return '$prefix-$timestamp-$sequence';
  }
}
