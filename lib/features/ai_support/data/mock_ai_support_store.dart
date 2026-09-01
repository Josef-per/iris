import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:iris/features/ai_support/data/mock_ai_recommender.dart';
import 'package:iris/features/ai_support/data/mock_diary_signals.dart';
import 'package:iris/features/ai_support/data/mock_notification_policy.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_suggestion_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_settings_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_event_repository.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_candidate.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/notifications/noop_support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/support_notification_schedule.dart';

/// Orquestra sugestões seguras nos modos de demonstração e conectado.
///
/// O modo conectado aceita apenas sinais estruturados e usa a infraestrutura
/// local de notificações. O modo de demonstração preserva o simulador
/// inteiramente síncrono usado pelo protótipo e pelos testes de interface.
class MockAiSupportStore extends ChangeNotifier {
  MockAiSupportStore({
    DateTime Function()? clock,
    AiSupportConsent consent = AiSupportConsent.none,
    AiSupportPreferences preferences = AiSupportPreferences.defaults,
    List<MockAiSupportScenario>? scenarios,
    MockAiRecommender? recommender,
    MockNotificationPolicy? notificationPolicy,
    AiSupportSignalDataSource? signalDataSource,
    AiSupportRemoteRecommender? remoteRecommender,
    AiSupportSettingsDataSource? settingsDataSource,
    AiSupportEventDataSource? eventDataSource,
    AiSupportSuggestionDataSource? suggestionDataSource,
    SupportNotificationGateway? notificationGateway,
    ValueChanged<String>? notificationOpenHandler,
    this.isDemonstration = true,
  }) : _clock = clock ?? DateTime.now,
       _consent = consent,
       _preferences = preferences,
       _recommender = recommender ?? MockAiRecommender(),
       _notificationPolicy =
           notificationPolicy ?? const MockNotificationPolicy(),
       _signalDataSource = signalDataSource,
       _remoteRecommender = remoteRecommender,
       _settingsDataSource = settingsDataSource,
       _eventDataSource = eventDataSource,
       _suggestionDataSource = suggestionDataSource,
       _notificationGateway =
           notificationGateway ?? const NoopSupportNotificationGateway(),
       _notificationOpenHandler = notificationOpenHandler,
       _validator = const AiSupportRecommendationValidator() {
    _scenarios = scenarios ?? MockDiarySignals.scenarios(_clock());
    if (_scenarios.isEmpty) {
      throw ArgumentError.value(
        scenarios,
        'scenarios',
        'Informe ao menos um cenário.',
      );
    }
    _selectedScenario = _scenarios.first;
    _signals = isDemonstration
        ? List<SupportSignal>.from(_selectedScenario.signals)
        : <SupportSignal>[];
    _isOnboarded =
        consent.personalizedSuggestionsGranted ||
        preferences.personalizedSuggestionsEnabled;
    _notificationInitialization = isDemonstration
        ? Future<void>.value()
        : _initializeNotificationGateway();
    _settingsReady = isDemonstration || _settingsDataSource == null;
    _settingsInitialization = _settingsReady
        ? Future<void>.value()
        : _loadSavedSettings();
    _eventHistoryInitialization =
        !isDemonstration && _eventDataSource is AiSupportEventHistoryDataSource
        ? _loadEventHistory(_eventDataSource as AiSupportEventHistoryDataSource)
        : Future<void>.value();
    _eventHistoryReady =
        isDemonstration || _eventDataSource is! AiSupportEventHistoryDataSource;
    if (!isDemonstration) unawaited(_notificationInitialization);
    if (!isDemonstration) unawaited(_settingsInitialization);
    if (!isDemonstration) unawaited(_eventHistoryInitialization);
  }

  final DateTime Function() _clock;
  final MockAiRecommender _recommender;
  final MockNotificationPolicy _notificationPolicy;
  final AiSupportSignalDataSource? _signalDataSource;
  final AiSupportRemoteRecommender? _remoteRecommender;
  final AiSupportSettingsDataSource? _settingsDataSource;
  final AiSupportEventDataSource? _eventDataSource;
  final AiSupportSuggestionDataSource? _suggestionDataSource;
  final SupportNotificationGateway _notificationGateway;
  final ValueChanged<String>? _notificationOpenHandler;
  final AiSupportRecommendationValidator _validator;
  final bool isDemonstration;
  late final Future<void> _notificationInitialization;
  late final Future<void> _settingsInitialization;
  late final Future<void> _eventHistoryInitialization;
  Future<SupportSuggestion?>? _personalizedGeneration;
  Future<void> _settingsWrite = Future<void>.value();
  Future<void> _eventWrite = Future<void>.value();

  late final List<MockAiSupportScenario> _scenarios;
  late MockAiSupportScenario _selectedScenario;
  late List<SupportSignal> _signals;

  AiSupportConsent _consent;
  AiSupportPreferences _preferences;
  bool _isOnboarded = false;
  SupportSuggestion? _pendingSuggestion;
  NotificationCandidate? _pendingNotificationCandidate;
  NotificationPolicyResult? _lastNotificationDecision;
  bool _isRefreshing = false;
  Object? _lastRefreshError;
  AiSupportRolloutMode _rolloutMode = AiSupportRolloutMode.local;
  SupportNotificationPermissionStatus _notificationPermissionStatus =
      SupportNotificationPermissionStatus.unavailable;
  Object? _lastNotificationError;
  Object? _lastSettingsError;
  Object? _lastEventError;
  bool _notificationsInitialized = false;
  bool _pendingNotificationOpenRecommendation = false;
  String? _pendingOpenedNotificationSuggestionId;
  bool _settingsReady = false;
  bool _eventHistoryReady = false;
  bool _disposed = false;

  final List<SupportSuggestion> _suggestionInbox = <SupportSuggestion>[];
  final List<NotificationCandidate> _notificationCandidates =
      <NotificationCandidate>[];
  final List<NotificationDeliveryRecord> _deliveries =
      <NotificationDeliveryRecord>[];
  final List<SuggestionFeedback> _feedback = <SuggestionFeedback>[];
  final Set<String> _schedulingSuggestionIds = <String>{};
  final Set<String> _acceptedNotificationCandidateIds = <String>{};
  final Set<String> _openedNotificationCandidateIds = <String>{};
  final Set<String> _openedFromNotificationSuggestionIds = <String>{};
  final Set<String> _blockedTemplateIds = <String>{};
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

  bool get isRefreshing => _isRefreshing;
  Object? get lastRefreshError => _lastRefreshError;
  AiSupportRolloutMode get rolloutMode => _rolloutMode;
  SupportNotificationPermissionStatus get notificationPermissionStatus =>
      _notificationPermissionStatus;
  Object? get lastNotificationError => _lastNotificationError;
  Object? get lastSettingsError => _lastSettingsError;
  Object? get lastEventError => _lastEventError;
  bool get settingsReady => _settingsReady;
  bool get hasPendingNotificationOpen =>
      _pendingOpenedNotificationSuggestionId != null;

  /// Recupera escolhas persistidas e inicializa notificações silenciosamente.
  /// Falhas secundárias ficam registradas, sem bloquear check-in ou diário.
  Future<void> initialize() async {
    await Future.wait<void>([
      _settingsInitialization,
      _notificationInitialization,
      _eventHistoryInitialization,
    ]);
  }

  /// Aguarda a inicialização silenciosa. Esta etapa nunca exibe o prompt do
  /// sistema operacional.
  Future<void> initializeNotifications() => _notificationInitialization;

  /// Aguarda apenas as escolhas da pessoa, sem bloquear o restante do app.
  Future<void> waitForSettings() => _settingsInitialization;

  Future<void> _loadSavedSettings() async {
    try {
      final saved = await _settingsDataSource!.load();
      if (saved != null) {
        final connectedSources = saved.consent.grantedSources.intersection(
          connectedAiSupportSources,
        );
        final connectedCategories = saved.preferences.allowedCategories
            .intersection(connectedAiSupportCategories);
        final enabled =
            saved.consent.personalizedSuggestionsGranted &&
            saved.preferences.personalizedSuggestionsEnabled &&
            connectedSources.isNotEmpty &&
            connectedCategories.isNotEmpty;
        _consent = saved.consent.copyWith(
          personalizedSuggestionsGranted: enabled,
          grantedSources: connectedSources,
        );
        _preferences = saved.preferences.copyWith(
          personalizedSuggestionsEnabled: enabled,
          allowedCategories: connectedCategories,
          notifications: enabled
              ? saved.preferences.notifications
              : saved.preferences.notifications.copyWith(
                  enabled: false,
                  frequency: NotificationFrequency.never,
                ),
        );
        _isOnboarded = true;
      }
      _lastSettingsError = null;
    } catch (error) {
      _lastSettingsError = error;
    } finally {
      if (!isPersonalizationEnabled ||
          !_preferences.notifications.allowsDelivery) {
        await _cancelAllRealNotifications();
      }
      _settingsReady = true;
      _notifyIfAlive();
    }
  }

  Future<void> _loadEventHistory(AiSupportEventHistoryDataSource source) async {
    await _settingsInitialization;
    try {
      final events = await source.loadRecentEvents();
      for (final event in events.reversed) {
        final category = _categoryFromStoredEvent(event.category);
        if (category == null) continue;
        if (event.type == AiSupportEventType.scheduled &&
            (event.scheduledFor ?? event.occurredAt).isAfter(_clock()) &&
            !_preferences.notifications.allowsDelivery) {
          continue;
        }
        if (event.type == AiSupportEventType.scheduled &&
            _deliveries.every(
              (delivery) => delivery.candidateId != event.suggestionId,
            )) {
          _deliveries.add(
            NotificationDeliveryRecord(
              candidateId: event.suggestionId,
              suggestionId: event.suggestionId,
              templateId: event.templateId,
              deliveredAt: event.scheduledFor ?? event.occurredAt,
            ),
          );
        }

        final feedbackType = _feedbackTypeFromStoredEvent(event.type);
        if (feedbackType != null &&
            _feedback.every((item) => item.id != event.id)) {
          _feedback.add(
            SuggestionFeedback(
              id: event.id,
              suggestionId: event.suggestionId,
              templateId: event.templateId,
              exerciseId: event.exerciseId,
              type: feedbackType,
              createdAt: event.occurredAt,
            ),
          );
          _updateBlockedTemplate(event.templateId, feedbackType);
        }

        if (_consent.allowsSource(
          SupportSignalSource.notificationInteractions,
        )) {
          final interaction = switch (event.type) {
            AiSupportEventType.opened
                when event.channel == AiSupportEventChannel.localNotification =>
              NotificationInteractionType.opened,
            AiSupportEventType.doesNotMatch ||
            AiSupportEventType.notHelpful ||
            AiSupportEventType.harmful =>
              NotificationInteractionType.markedUnhelpful,
            AiSupportEventType.dismissed =>
              NotificationInteractionType.dismissed,
            _ => null,
          };
          if (interaction != null &&
              _signals.every((signal) => signal.id != 'event-${event.id}')) {
            _signals.add(
              NotificationInteractionSignal(
                id: 'event-${event.id}',
                createdAt: event.occurredAt,
                expiresAt: event.occurredAt.add(const Duration(days: 30)),
                interaction: interaction,
                templateId: event.templateId,
                category: category,
              ),
            );
          }
        }
      }
      _eventHistoryReady = true;
      _lastEventError = null;
    } catch (error) {
      _eventHistoryReady = false;
      _lastEventError = error;
    }
    _notifyIfAlive();
  }

  /// Pede permissão somente após uma ação explícita da pessoa na interface.
  Future<SupportNotificationPermissionStatus>
  requestNotificationPermission() async {
    if (isDemonstration) {
      return SupportNotificationPermissionStatus.unavailable;
    }
    await _notificationInitialization;
    if (!_notificationsInitialized || !_notificationGateway.isSupported) {
      return SupportNotificationPermissionStatus.unavailable;
    }
    try {
      _notificationPermissionStatus = await _notificationGateway
          .requestPermission();
      _lastNotificationError = null;
    } catch (error) {
      _lastNotificationError = error;
      _notificationPermissionStatus =
          SupportNotificationPermissionStatus.unavailable;
    }
    _notifyIfAlive();
    return _notificationPermissionStatus;
  }

  Future<void> _initializeNotificationGateway() async {
    try {
      final initiallyOpenedCandidateId = await _notificationGateway.initialize(
        onOpen: recordNotificationOpened,
      );
      _notificationsInitialized = true;
      _notificationPermissionStatus = await _notificationGateway
          .permissionStatus();
      _lastNotificationError = null;
      if (initiallyOpenedCandidateId != null) {
        recordNotificationOpened(initiallyOpenedCandidateId);
      } else {
        _notifyIfAlive();
      }
    } catch (error) {
      _notificationsInitialized = false;
      _notificationPermissionStatus =
          SupportNotificationPermissionStatus.unavailable;
      _lastNotificationError = error;
      _notifyIfAlive();
    }
  }

  /// Atualiza os sinais reais sem carregar o texto livre do diário.
  Future<void> refreshSignals() async {
    _setRefreshing(true);
    try {
      await _refreshSignalData();
    } finally {
      _setRefreshing(false);
    }
  }

  Future<void> _refreshSignalData() async {
    final source = _signalDataSource;
    if (source == null) return;
    try {
      final loaded = await source.loadRecentSignals();
      final retainedInteractions = _signals
          .whereType<NotificationInteractionSignal>()
          .toList(growable: false);
      final retainedExerciseFeedback = _signals
          .whereType<ExerciseFeedbackSignal>()
          .toList(growable: false);
      _signals = <SupportSignal>[
        ...loaded,
        ...retainedInteractions,
        ...retainedExerciseFeedback,
      ];
      _lastRefreshError = null;
    } catch (error) {
      _lastRefreshError = error;
      rethrow;
    }
  }

  /// Recomendação conectada: somente uma seleção validada do modelo pode
  /// influenciar a experiência.
  ///
  /// As regras locais existem apenas no modo de demonstração. Em shadow mode,
  /// a resposta remota é auditada no backend e não aparece. Em
  /// piloto/produção limitada, a proposta do modelo ainda precisa passar pelo
  /// validador local e pelo catálogo fechado.
  Future<SupportSuggestion?> generatePersonalizedSuggestion({
    DateTime? now,
    bool refresh = true,
    AiSupportRecommendationTrigger trigger =
        AiSupportRecommendationTrigger.manual,
  }) {
    final active = _personalizedGeneration;
    if (active != null) {
      final notificationMustWin =
          trigger == AiSupportRecommendationTrigger.notificationOpen ||
          _pendingNotificationOpenRecommendation;
      if (notificationMustWin) {
        return active.then(
          (_) => generatePersonalizedSuggestion(
            now: now,
            refresh: refresh,
            trigger: trigger,
          ),
        );
      }
      return active;
    }

    _setRefreshing(true);
    late final Future<SupportSuggestion?> generation;
    generation =
        _generatePersonalizedSuggestion(
          now: now,
          refresh: refresh,
          trigger: trigger,
        ).whenComplete(() {
          if (identical(_personalizedGeneration, generation)) {
            _personalizedGeneration = null;
            _setRefreshing(false);
          }
        });
    _personalizedGeneration = generation;
    return generation;
  }

  Future<SupportSuggestion?> _generatePersonalizedSuggestion({
    required DateTime? now,
    required bool refresh,
    required AiSupportRecommendationTrigger trigger,
  }) async {
    await _settingsInitialization;
    final effectiveTrigger =
        trigger == AiSupportRecommendationTrigger.manual &&
            _pendingNotificationOpenRecommendation
        ? AiSupportRecommendationTrigger.notificationOpen
        : trigger;
    if (effectiveTrigger == AiSupportRecommendationTrigger.notificationOpen) {
      _pendingNotificationOpenRecommendation = false;
    }
    final openedSuggestionId =
        effectiveTrigger == AiSupportRecommendationTrigger.notificationOpen
        ? _pendingOpenedNotificationSuggestionId
        : null;
    if (effectiveTrigger == AiSupportRecommendationTrigger.notificationOpen) {
      _pendingOpenedNotificationSuggestionId = null;
    }
    final at = now ?? _clock();
    if (refresh && _signalDataSource != null) {
      try {
        await _refreshSignalData();
      } catch (_) {
        // A Edge Function consultará os sinais persistidos. Não criamos uma
        // recomendação local quando a atualização falha.
      }
    }

    if (openedSuggestionId != null) {
      SupportSuggestion? openedSuggestion;
      for (final item in _suggestionInbox) {
        if (item.id == openedSuggestionId) {
          openedSuggestion = item;
          break;
        }
      }
      openedSuggestion ??= _pendingSuggestion?.id == openedSuggestionId
          ? _pendingSuggestion
          : null;
      final suggestionSource = _suggestionDataSource;
      if (openedSuggestion == null && suggestionSource != null) {
        try {
          openedSuggestion = await suggestionSource.loadVisibleSuggestion(
            openedSuggestionId,
          );
        } catch (error) {
          _lastRefreshError = error;
        }
      }
      if (openedSuggestion != null && !openedSuggestion.isExpiredAt(at)) {
        final validation = _validator.validate(
          AiSupportRecommendationProposal(
            suggestionTemplateId: openedSuggestion.templateId,
            exerciseId: openedSuggestion.exerciseId,
            reasonCodes: openedSuggestion.reasonCodes,
            confidenceBand: openedSuggestion.confidenceBand,
          ),
          preferences: _preferences,
          usedSources: openedSuggestion.usedSources,
          createdAt: openedSuggestion.createdAt,
          expiresAt: openedSuggestion.expiresAt,
          suggestionId: openedSuggestion.id,
        );
        final validated = validation.suggestion;
        if (validated != null &&
            validated.category == openedSuggestion.category &&
            validated.exerciseId == openedSuggestion.exerciseId &&
            _isSuggestionAllowedNow(validated)) {
          _openedFromNotificationSuggestionIds.add(validated.id);
          _acceptSuggestion(validated, at, scheduleRealNotification: false);
          _notifyIfAlive();
          return validated;
        }
      }
    }

    final context = AiSupportRecommendationContext(
      consent: _consent,
      preferences: _preferences,
      signals: _signals,
      now: at,
      focus: switch (effectiveTrigger) {
        AiSupportRecommendationTrigger.afterCheckIn =>
          AiSupportRecommendationFocus.checkIn,
        AiSupportRecommendationTrigger.afterDiary =>
          AiSupportRecommendationFocus.diary,
        AiSupportRecommendationTrigger.notificationOpen =>
          AiSupportRecommendationFocus.notification,
        AiSupportRecommendationTrigger.manual =>
          AiSupportRecommendationFocus.general,
      },
      blockedTemplateIds: Set<String>.unmodifiable(_blockedTemplateIds),
    );
    SupportSuggestion? selected = isDemonstration
        ? _recommender.recommend(context).suggestion
        : null;
    final remote = _remoteRecommender;
    if (remote != null && isPersonalizationEnabled) {
      try {
        await _settingsWrite;
        if (_lastSettingsError != null) {
          throw StateError('Preferências ainda não foram sincronizadas.');
        }
        // Uma abertura em cold start precisa chegar ao backend antes da nova
        // seleção, para que a interação realmente personalize a resposta.
        await _eventWrite;
        final decision = await remote.recommend(
          context,
          trigger: effectiveTrigger,
        );
        _rolloutMode = decision.mode;
        if (decision.shouldUseProposal) {
          final proposal = decision.proposal!;
          final usedSources = _sourcesForRemoteProposal(proposal);
          if (!usedSources.every(_consent.allowsSource)) {
            throw StateError('A resposta usou uma fonte não autorizada.');
          }
          final validation = _validator.validateUntrustedPayload(
            proposal,
            preferences: _preferences,
            usedSources: usedSources,
            createdAt: at,
            suggestionId: decision.suggestionId,
          );
          if (validation.isAccepted) selected = validation.suggestion;
        }
      } catch (error) {
        _lastRefreshError = error;
      }
    }
    // Preferências podem mudar enquanto a chamada remota está em andamento.
    // A resposta antiga nunca pode reaparecer depois de um opt-out.
    if (selected != null && !_isSuggestionAllowedNow(selected)) {
      selected = null;
    }
    _acceptSuggestion(selected, at, scheduleRealNotification: false);
    if (!isDemonstration &&
        selected != null &&
        (_eventDataSource == null || isAiSupportUuid(selected.id)) &&
        effectiveTrigger != AiSupportRecommendationTrigger.notificationOpen) {
      await _scheduleNotificationForSuggestion(selected, at);
    }
    _notifyIfAlive();
    return selected;
  }

  /// Configurar consentimento também conclui o onboarding fictício.
  void configureConsent(AiSupportConsent value) {
    final allowedSources = isDemonstration
        ? value.grantedSources
        : value.grantedSources.intersection(connectedAiSupportSources);
    final normalized = value.copyWith(
      personalizedSuggestionsGranted:
          value.personalizedSuggestionsGranted && allowedSources.isNotEmpty,
      grantedSources: allowedSources,
    );
    final revokeAll =
        _consent.personalizedSuggestionsGranted &&
        !normalized.personalizedSuggestionsGranted;
    final revokedSources = <SupportSignalSource>{
      ..._consent.grantedSources.where(
        (source) => !normalized.grantedSources.contains(source),
      ),
    };
    _consent = normalized;
    if (!normalized.personalizedSuggestionsGranted) {
      _preferences = _preferences.copyWith(
        personalizedSuggestionsEnabled: false,
        notifications: _preferences.notifications.copyWith(
          enabled: false,
          frequency: NotificationFrequency.never,
        ),
      );
    }
    _isOnboarded = true;
    if (revokeAll) {
      _clearAllDerivedData();
    } else {
      for (final source in revokedSources) {
        _removeSourceData(source);
      }
    }
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
  }

  /// Configurar preferências também conclui o onboarding fictício.
  void configurePreferences(AiSupportPreferences value) {
    final allowedCategories = isDemonstration
        ? value.allowedCategories
        : value.allowedCategories.intersection(connectedAiSupportCategories);
    final canRemainEnabled =
        value.personalizedSuggestionsEnabled &&
        _consent.personalizedSuggestionsGranted &&
        _consent.grantedSources.isNotEmpty &&
        allowedCategories.isNotEmpty;
    _preferences = value.copyWith(
      personalizedSuggestionsEnabled: canRemainEnabled,
      allowedCategories: allowedCategories,
      notifications: canRemainEnabled
          ? value.notifications
          : value.notifications.copyWith(
              enabled: false,
              frequency: NotificationFrequency.never,
            ),
    );
    _isOnboarded = true;
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
  }

  void completeOnboarding({
    required AiSupportConsent consent,
    required AiSupportPreferences preferences,
  }) {
    final allowedSources = isDemonstration
        ? consent.grantedSources
        : consent.grantedSources.intersection(connectedAiSupportSources);
    final allowedCategories = isDemonstration
        ? preferences.allowedCategories
        : preferences.allowedCategories.intersection(
            connectedAiSupportCategories,
          );
    final canEnable =
        consent.personalizedSuggestionsGranted &&
        preferences.personalizedSuggestionsEnabled &&
        allowedSources.isNotEmpty &&
        allowedCategories.isNotEmpty;
    final normalizedConsent = consent.copyWith(
      personalizedSuggestionsGranted: canEnable,
      grantedSources: allowedSources,
    );
    final normalizedPreferences = preferences.copyWith(
      personalizedSuggestionsEnabled: canEnable,
      allowedCategories: allowedCategories,
      notifications: canEnable
          ? preferences.notifications
          : preferences.notifications.copyWith(
              enabled: false,
              frequency: NotificationFrequency.never,
            ),
    );
    final revokeAll =
        _consent.personalizedSuggestionsGranted &&
        !normalizedConsent.personalizedSuggestionsGranted;
    final revokedSources = <SupportSignalSource>{
      ..._consent.grantedSources.where(
        (source) => !normalizedConsent.grantedSources.contains(source),
      ),
    };
    _consent = normalizedConsent;
    _preferences = normalizedPreferences;
    _isOnboarded = true;
    if (revokeAll) {
      _clearAllDerivedData();
    } else {
      for (final source in revokedSources) {
        _removeSourceData(source);
      }
    }
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
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
    if (granted &&
        (isDemonstration || connectedAiSupportSources.contains(source))) {
      sources.add(source);
    } else {
      sources.remove(source);
      _removeSourceData(source);
    }
    _consent = _consent.copyWith(
      personalizedSuggestionsGranted: sources.isEmpty
          ? false
          : _consent.personalizedSuggestionsGranted,
      grantedSources: sources,
    );
    if (sources.isEmpty) {
      _preferences = _preferences.copyWith(
        personalizedSuggestionsEnabled: false,
        notifications: _preferences.notifications.copyWith(
          enabled: false,
          frequency: NotificationFrequency.never,
        ),
      );
    }
    _isOnboarded = true;
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
    final eventSource = _eventDataSource;
    if (granted &&
        source == SupportSignalSource.notificationInteractions &&
        eventSource is AiSupportEventHistoryDataSource) {
      unawaited(
        _loadEventHistory(eventSource as AiSupportEventHistoryDataSource),
      );
    }
  }

  void setPersonalizationEnabled(bool enabled) {
    final canEnable =
        _consent.personalizedSuggestionsGranted &&
        _consent.grantedSources.isNotEmpty &&
        _preferences.allowedCategories.isNotEmpty;
    final willEnable = enabled && canEnable;
    _preferences = _preferences.copyWith(
      personalizedSuggestionsEnabled: willEnable,
      notifications: willEnable
          ? _preferences.notifications
          : _preferences.notifications.copyWith(
              enabled: false,
              frequency: NotificationFrequency.never,
            ),
    );
    if (!willEnable) {
      _pendingSuggestion = null;
      if (!isDemonstration) unawaited(_cancelAllRealNotifications());
      _pendingNotificationCandidate = null;
    }
    _persistSettings();
    _notifyIfAlive();
  }

  void configureNotifications(NotificationPreferences value) {
    final normalized = isPersonalizationEnabled
        ? value
        : value.copyWith(
            enabled: false,
            frequency: NotificationFrequency.never,
          );
    _preferences = _preferences.copyWith(notifications: normalized);
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
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
    if (!isDemonstration) unawaited(_cancelAllRealNotifications());
    _pendingNotificationCandidate = null;
    _persistSettings();
    _notifyIfAlive();
  }

  void resumeNotifications() {
    _preferences = _preferences.copyWith(
      notifications: _preferences.notifications.withPauseUntil(null),
    );
    _persistSettings();
    _notifyIfAlive();
  }

  void revokeSourceConsent(SupportSignalSource source) {
    final sources = <SupportSignalSource>{..._consent.grantedSources}
      ..remove(source);
    _consent = _consent.copyWith(
      personalizedSuggestionsGranted: sources.isEmpty
          ? false
          : _consent.personalizedSuggestionsGranted,
      grantedSources: sources,
    );
    if (sources.isEmpty) {
      _preferences = _preferences.copyWith(
        personalizedSuggestionsEnabled: false,
        notifications: _preferences.notifications.copyWith(
          enabled: false,
          frequency: NotificationFrequency.never,
        ),
      );
    }
    _removeSourceData(source);
    _invalidatePendingForPreferences();
    _persistSettings();
    _notifyIfAlive();
  }

  Future<void> revokeAllConsent() async {
    _consent = _consent.revokeAll();
    _preferences = _preferences.copyWith(
      personalizedSuggestionsEnabled: false,
      notifications: _preferences.notifications.copyWith(
        enabled: false,
        frequency: NotificationFrequency.never,
      ),
    );
    _isOnboarded = false;
    _clearAllDerivedData();
    final clearing = _clearSavedSettings();
    _notifyIfAlive();
    await clearing;
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
    final suggestion = result.suggestion;
    _acceptSuggestion(suggestion, at);
    notifyListeners();
    return suggestion;
  }

  void recordNotificationOpened(String candidateId, {DateTime? now}) {
    if (!isValidSupportNotificationCandidateId(candidateId) ||
        !_openedNotificationCandidateIds.add(candidateId)) {
      return;
    }
    NotificationCandidate? knownCandidate;
    for (final candidate in _notificationCandidates) {
      if (candidate.id == candidateId) {
        knownCandidate = candidate;
        break;
      }
    }
    final hasKnownSuggestion = knownCandidate != null;
    _pendingOpenedNotificationSuggestionId =
        knownCandidate?.suggestionId ?? candidateId;
    _pendingNotificationOpenRecommendation = true;
    _recordNotificationInteraction(
      candidateId,
      NotificationInteractionType.opened,
      now: now,
    );
    if (!hasKnownSuggestion && isAiSupportUuid(candidateId)) {
      _recordRemoteEventById(
        candidateId,
        AiSupportEventType.opened,
        channel: AiSupportEventChannel.localNotification,
      );
    }
    _notificationOpenHandler?.call(candidateId);
  }

  void recordNotificationUnhelpful(String candidateId, {DateTime? now}) {
    if (!isValidSupportNotificationCandidateId(candidateId)) return;
    _recordNotificationInteraction(
      candidateId,
      NotificationInteractionType.markedUnhelpful,
      now: now,
    );
  }

  /// Reavalia somente a entrega para a sugestão pendente atual.
  NotificationPolicyResult? generateNotificationCandidate({DateTime? now}) {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) return null;
    final at = now ?? _clock();
    if (isDemonstration) {
      _createSimulatedCandidateForPendingSuggestion(at);
    } else {
      unawaited(_scheduleNotificationForSuggestion(suggestion, at));
    }
    notifyListeners();
    return _lastNotificationDecision;
  }

  /// Avalia a política, encontra o próximo horário permitido e agenda a
  /// notificação local. Nenhuma permissão é pedida implicitamente.
  Future<NotificationPolicyResult?> schedulePendingNotification({
    DateTime? now,
  }) async {
    final suggestion = _pendingSuggestion;
    if (suggestion == null) return null;
    if (isDemonstration) {
      _createSimulatedCandidateForPendingSuggestion(now ?? _clock());
      notifyListeners();
      return _lastNotificationDecision;
    }
    return _scheduleNotificationForSuggestion(suggestion, now ?? _clock());
  }

  /// Registra feedback sem comentário livre e aplica a pausa automática.
  SuggestionFeedback? recordFeedback(
    SuggestionFeedbackType type, {
    SupportSuggestion? suggestion,
    DateTime? now,
    AiSupportEventChannel channel = AiSupportEventChannel.app,
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
    _updateBlockedTemplate(target.templateId, type);
    _recordRemoteEvent(target, _eventTypeForFeedback(type), channel: channel);

    if (type == SuggestionFeedbackType.doesNotMatch ||
        type == SuggestionFeedbackType.notHelpful ||
        type == SuggestionFeedbackType.harmful) {
      if (_consent.allowsSource(SupportSignalSource.notificationInteractions)) {
        _signals.add(
          NotificationInteractionSignal(
            id: _nextOpaqueId('negative-template', at),
            createdAt: at,
            expiresAt: at.add(const Duration(days: 30)),
            interaction: NotificationInteractionType.markedUnhelpful,
            templateId: target.templateId,
            category: target.category,
          ),
        );
      }
    } else if (type == SuggestionFeedbackType.helpful ||
        type == SuggestionFeedbackType.matchesPerception) {
      _signals.removeWhere(
        (signal) =>
            signal is NotificationInteractionSignal &&
            signal.templateId == target.templateId &&
            signal.interaction == NotificationInteractionType.markedUnhelpful,
      );
    }

    if (_blockedTemplateIds.contains(target.templateId)) {
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
      _cancelPendingRealNotification();
      _pendingNotificationCandidate = null;
    }
    _persistSettings();
    _notifyIfAlive();
    return event;
  }

  SuggestionFeedback? dismissLatestCandidate({DateTime? now}) {
    return recordFeedback(SuggestionFeedbackType.dismissed, now: now);
  }

  void recordActionStarted(SupportSuggestion suggestion) {
    _recordRemoteEvent(
      suggestion,
      AiSupportEventType.actionStarted,
      channel: AiSupportEventChannel.app,
    );
  }

  void recordSuggestionOpenedInApp(SupportSuggestion suggestion) {
    final candidateIds = _notificationCandidates
        .where((candidate) => candidate.suggestionId == suggestion.id)
        .map((candidate) => candidate.id)
        .toList(growable: false);
    for (final candidateId in candidateIds) {
      if (_pendingNotificationCandidate?.id == candidateId) {
        _pendingNotificationCandidate = null;
      }
      if (!isDemonstration) unawaited(_cancelRealNotification(candidateId));
    }
    if (!_openedFromNotificationSuggestionIds.remove(suggestion.id)) {
      _recordRemoteEvent(
        suggestion,
        AiSupportEventType.opened,
        channel: AiSupportEventChannel.app,
      );
    }
    _notifyIfAlive();
  }

  /// Remove apenas o lembrete associado, preservando a sugestão dentro do app.
  void cancelNotificationForSuggestion(SupportSuggestion suggestion) {
    final candidateIds = _notificationCandidates
        .where((candidate) => candidate.suggestionId == suggestion.id)
        .map((candidate) => candidate.id)
        .toSet();
    if (isAiSupportUuid(suggestion.id)) candidateIds.add(suggestion.id);
    for (final candidateId in candidateIds) {
      if (_pendingNotificationCandidate?.id == candidateId) {
        _pendingNotificationCandidate = null;
      }
      if (!isDemonstration) unawaited(_cancelRealNotification(candidateId));
    }
    _notifyIfAlive();
  }

  /// Remove um sinal derivado sem editar nenhum diário original.
  void discardSignal(String signalId) {
    _signals.removeWhere((signal) => signal.id == signalId);
    _invalidatePendingForPreferences();
    notifyListeners();
  }

  void _createSimulatedCandidateForPendingSuggestion(DateTime at) {
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

  Future<NotificationPolicyResult?> _scheduleNotificationForSuggestion(
    SupportSuggestion suggestion,
    DateTime requestedAt,
  ) async {
    // No modo conectado, o ID persistido é o vínculo que permite abrir
    // exatamente a mesma sugestão depois de um cold start.
    if (_eventDataSource != null && !isAiSupportUuid(suggestion.id)) {
      return _recordNotificationDecision(
        const NotificationPolicyResult.blocked(
          NotificationPolicyBlockReason.deliveryUnavailable,
        ),
      );
    }
    if (_schedulingSuggestionIds.contains(suggestion.id)) {
      return _lastNotificationDecision;
    }
    for (final existing in _notificationCandidates.reversed) {
      if (_acceptedNotificationCandidateIds.contains(existing.id) &&
          existing.suggestionId == suggestion.id &&
          !existing.isExpiredAt(requestedAt)) {
        _pendingNotificationCandidate = existing;
        _lastNotificationDecision = NotificationPolicyResult.allowed(existing);
        return _lastNotificationDecision;
      }
    }

    _schedulingSuggestionIds.add(suggestion.id);
    try {
      await _eventHistoryInitialization;
      if (_eventDataSource case final AiSupportEventHistoryDataSource history) {
        if (!_eventHistoryReady) await _loadEventHistory(history);
        if (!_eventHistoryReady) {
          return _recordNotificationDecision(
            const NotificationPolicyResult.blocked(
              NotificationPolicyBlockReason.deliveryUnavailable,
            ),
          );
        }
      }
      await _notificationInitialization;
      if (_pendingSuggestion?.id != suggestion.id) return null;

      final catalogTemplate = MockSupportTemplateCatalog.catalog.templateById(
        suggestion.templateId,
      );
      if (catalogTemplate == null) {
        return _recordNotificationDecision(
          const NotificationPolicyResult.blocked(
            NotificationPolicyBlockReason.templateNotApproved,
          ),
        );
      }
      final candidate = notificationCandidateForSuggestion(
        suggestion,
        candidateId: isAiSupportUuid(suggestion.id)
            ? suggestion.id
            : generateOpaqueSupportNotificationCandidateId(),
        genericNotificationTemplateId:
            catalogTemplate.genericNotificationTemplateId,
      );
      final earliest = requestedAt.add(const Duration(minutes: 1));
      final scheduledAt = SupportNotificationSchedule.nextAllowedTime(
        notBefore: earliest,
        expiresAt: candidate.expiresAt,
        window: _preferences.notifications.window,
      );
      if (scheduledAt == null) {
        final reason = candidate.isExpiredAt(earliest)
            ? NotificationPolicyBlockReason.expired
            : NotificationPolicyBlockReason.outsideWindow;
        return _recordNotificationDecision(
          NotificationPolicyResult.blocked(reason),
        );
      }

      final policyDecision = _notificationPolicy.evaluate(
        NotificationPolicyInput(
          consent: _consent,
          preferences: _preferences,
          suggestion: suggestion,
          candidate: candidate,
          deliveries: _deliveries,
          feedback: _feedback,
          now: scheduledAt,
        ),
      );
      if (!policyDecision.canDeliver) {
        return _recordNotificationDecision(policyDecision);
      }
      if (!_notificationsInitialized || !_notificationGateway.isSupported) {
        return _recordNotificationDecision(
          const NotificationPolicyResult.blocked(
            NotificationPolicyBlockReason.deliveryUnavailable,
          ),
        );
      }

      _notificationPermissionStatus = await _notificationGateway
          .permissionStatus();
      if (!_notificationPermissionStatus.allowsScheduling) {
        return _recordNotificationDecision(
          const NotificationPolicyResult.blocked(
            NotificationPolicyBlockReason.systemPermissionNotGranted,
          ),
        );
      }

      final notificationTemplate = SupportNotificationTemplate.tryFromId(
        candidate.genericNotificationTemplateId,
      );
      if (notificationTemplate == null) {
        return _recordNotificationDecision(
          const NotificationPolicyResult.blocked(
            NotificationPolicyBlockReason.templateNotApproved,
          ),
        );
      }

      await _notificationGateway.schedule(
        SupportNotificationRequest(
          candidateId: candidate.id,
          template: notificationTemplate,
          scheduledAt: scheduledAt,
          privacy:
              _preferences.notifications.lockScreenPreview ==
                  LockScreenPreview.none
              ? SupportNotificationPrivacy.hidden
              : SupportNotificationPrivacy.generic,
        ),
      );

      // O estado pode ter mudado enquanto a ponte nativa estava agendando.
      // Nesse caso removemos o agendamento e não registramos uma entrega.
      if (_pendingSuggestion?.id != suggestion.id ||
          !isPersonalizationEnabled ||
          !_preferences.notifications.allowsDelivery) {
        await _notificationGateway.cancel(candidate.id);
        return null;
      }

      _pendingNotificationCandidate = candidate;
      _notificationCandidates.add(candidate);
      _acceptedNotificationCandidateIds.add(candidate.id);
      // Este registro só nasce depois de o gateway aceitar o agendamento.
      _deliveries.add(
        NotificationDeliveryRecord(
          candidateId: candidate.id,
          suggestionId: suggestion.id,
          templateId: suggestion.templateId,
          deliveredAt: scheduledAt,
        ),
      );
      _recordRemoteEvent(
        suggestion,
        AiSupportEventType.scheduled,
        channel: AiSupportEventChannel.localNotification,
        scheduledFor: scheduledAt,
      );
      await _eventWrite;
      if (_eventDataSource != null && _lastEventError != null) {
        await _notificationGateway.cancel(candidate.id);
        _acceptedNotificationCandidateIds.remove(candidate.id);
        _notificationCandidates.removeWhere((item) => item.id == candidate.id);
        _deliveries.removeWhere(
          (delivery) => delivery.candidateId == candidate.id,
        );
        _pendingNotificationCandidate = null;
        return _recordNotificationDecision(
          const NotificationPolicyResult.blocked(
            NotificationPolicyBlockReason.deliveryUnavailable,
          ),
        );
      }
      _lastNotificationError = null;
      return _recordNotificationDecision(
        NotificationPolicyResult.allowed(candidate),
      );
    } catch (error) {
      _lastNotificationError = error;
      return _recordNotificationDecision(
        const NotificationPolicyResult.blocked(
          NotificationPolicyBlockReason.deliveryUnavailable,
        ),
      );
    } finally {
      _schedulingSuggestionIds.remove(suggestion.id);
    }
  }

  NotificationPolicyResult _recordNotificationDecision(
    NotificationPolicyResult decision,
  ) {
    _lastNotificationDecision = decision;
    if (!decision.canDeliver) _pendingNotificationCandidate = null;
    final automaticPause = decision.automaticPauseUntil;
    if (automaticPause != null) {
      _preferences = _preferences.copyWith(
        notifications: _preferences.notifications.withPauseUntil(
          automaticPause,
        ),
      );
      _persistSettings();
    }
    _notifyIfAlive();
    return decision;
  }

  void _acceptSuggestion(
    SupportSuggestion? suggestion,
    DateTime at, {
    bool scheduleRealNotification = true,
  }) {
    _pendingSuggestion = suggestion;
    _pendingNotificationCandidate = null;
    _lastNotificationDecision = null;
    if (suggestion == null) return;
    _addSuggestionToInbox(suggestion);
    if (isDemonstration) {
      _createSimulatedCandidateForPendingSuggestion(at);
    } else if (scheduleRealNotification) {
      unawaited(_scheduleNotificationForSuggestion(suggestion, at));
    }
  }

  void _recordNotificationInteraction(
    String candidateId,
    NotificationInteractionType interaction, {
    DateTime? now,
  }) {
    NotificationCandidate? candidate;
    for (final item in _notificationCandidates) {
      if (item.id == candidateId) {
        candidate = item;
        break;
      }
    }
    SupportSuggestion? suggestion;
    if (candidate != null) {
      for (final item in _suggestionInbox) {
        if (item.id == candidate.suggestionId) {
          suggestion = item;
          break;
        }
      }
    }
    final at = now ?? _clock();
    if (interaction == NotificationInteractionType.markedUnhelpful &&
        suggestion != null) {
      recordFeedback(
        SuggestionFeedbackType.notHelpful,
        suggestion: suggestion,
        now: at,
        channel: AiSupportEventChannel.localNotification,
      );
      return;
    }
    if (_consent.allowsSource(SupportSignalSource.notificationInteractions)) {
      _signals.add(
        NotificationInteractionSignal(
          id: _nextOpaqueId('interaction', at),
          createdAt: at,
          expiresAt: at.add(const Duration(days: 30)),
          interaction: interaction,
          templateId: candidate?.templateId,
          category: suggestion?.category,
        ),
      );
    }
    if (suggestion != null) {
      _recordRemoteEvent(
        suggestion,
        AiSupportEventType.opened,
        channel: AiSupportEventChannel.localNotification,
      );
    }
    _notifyIfAlive();
  }

  Set<SupportSignalSource> _sourcesForRemoteProposal(
    Map<String, Object?> proposal,
  ) {
    final sources = <SupportSignalSource>{};
    final reasons = proposal['reasonCodes'];
    if (reasons is! List) return sources;
    for (final raw in reasons) {
      final reason = SupportReasonCodeWire.fromWireName(raw?.toString() ?? '');
      switch (reason) {
        case SupportReasonCode.todayDifficultCheckIn:
        case SupportReasonCode.todaySteadyCheckIn:
        case SupportReasonCode.todayLighterCheckIn:
        case SupportReasonCode.recentDifficultCheckIns:
        case SupportReasonCode.prefersShortPractice:
          sources.add(SupportSignalSource.moodHistory);
        case SupportReasonCode.confirmedOverload:
        case SupportReasonCode.confirmedLoneliness:
        case SupportReasonCode.confirmedSelfKindness:
          sources.add(SupportSignalSource.diaryTags);
        case SupportReasonCode.previousExerciseWasNotHelpful:
          sources.add(SupportSignalSource.exerciseFeedback);
        case SupportReasonCode.preferredFromPastInteractions:
          sources.add(SupportSignalSource.notificationInteractions);
        case null:
          break;
      }
    }
    return sources;
  }

  void _setRefreshing(bool value) {
    if (_isRefreshing == value) return;
    _isRefreshing = value;
    _notifyIfAlive();
  }

  void _addSuggestionToInbox(SupportSuggestion suggestion) {
    if (_suggestionInbox.every((item) => item.id != suggestion.id)) {
      _suggestionInbox.add(suggestion);
    }
  }

  void _invalidatePendingForPreferences() {
    if (!isDemonstration) unawaited(_cancelAllRealNotifications());
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
    _cancelPendingRealNotification();
    _pendingNotificationCandidate = null;
  }

  bool _isSuggestionAllowedNow(SupportSuggestion suggestion) {
    return isPersonalizationEnabled &&
        !_blockedTemplateIds.contains(suggestion.templateId) &&
        _preferences.allowsCategory(suggestion.category) &&
        suggestion.usedSources.isNotEmpty &&
        suggestion.usedSources.every(_consent.allowsSource);
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
    if (!isDemonstration) {
      for (final candidateId
          in _deliveries
              .where(
                (delivery) =>
                    removedSuggestionIds.contains(delivery.suggestionId),
              )
              .map((delivery) => delivery.candidateId)
              .toSet()) {
        unawaited(_cancelRealNotification(candidateId));
      }
    }
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
    if (!isDemonstration) unawaited(_cancelAllRealNotifications());
    _signals.clear();
    _suggestionInbox.clear();
    _notificationCandidates.clear();
    _deliveries.clear();
    _feedback.clear();
    _acceptedNotificationCandidateIds.clear();
    _openedNotificationCandidateIds.clear();
    _openedFromNotificationSuggestionIds.clear();
    _blockedTemplateIds.clear();
    _pendingNotificationOpenRecommendation = false;
    _pendingOpenedNotificationSuggestionId = null;
    _pendingSuggestion = null;
    _pendingNotificationCandidate = null;
    _lastNotificationDecision = null;
  }

  void _cancelPendingRealNotification() {
    final candidateId = _pendingNotificationCandidate?.id;
    if (isDemonstration || candidateId == null) return;
    unawaited(_cancelRealNotification(candidateId));
  }

  Future<void> _cancelRealNotification(String candidateId) async {
    _acceptedNotificationCandidateIds.remove(candidateId);
    final now = _clock();
    final hadFutureDelivery = _deliveries.any(
      (delivery) =>
          delivery.candidateId == candidateId &&
          delivery.deliveredAt.isAfter(now),
    );
    _deliveries.removeWhere(
      (delivery) =>
          delivery.candidateId == candidateId &&
          delivery.deliveredAt.isAfter(now),
    );
    if (hadFutureDelivery) {
      _notificationCandidates.removeWhere(
        (candidate) => candidate.id == candidateId,
      );
    }
    try {
      await _notificationInitialization;
      if (_notificationsInitialized) {
        await _notificationGateway.cancel(candidateId);
      }
    } catch (error) {
      _lastNotificationError = error;
      _notifyIfAlive();
    }
  }

  Future<void> _cancelAllRealNotifications() async {
    final now = _clock();
    final futureCandidateIds = _deliveries
        .where((delivery) => delivery.deliveredAt.isAfter(now))
        .map((delivery) => delivery.candidateId)
        .toSet();
    _acceptedNotificationCandidateIds.removeAll(futureCandidateIds);
    _deliveries.removeWhere(
      (delivery) => futureCandidateIds.contains(delivery.candidateId),
    );
    _notificationCandidates.removeWhere(
      (candidate) => futureCandidateIds.contains(candidate.id),
    );
    try {
      await _notificationInitialization;
      if (_notificationsInitialized) {
        await _notificationGateway.cancelAllSupportNotifications();
      }
    } catch (error) {
      _lastNotificationError = error;
      _notifyIfAlive();
    }
  }

  void _persistSettings() {
    final source = _settingsDataSource;
    if (isDemonstration || source == null) return;
    final consent = _consent;
    final preferences = _preferences;
    final previous = _settingsWrite;
    _settingsWrite = () async {
      await previous;
      await _settingsInitialization;
      try {
        await source.save(consent: consent, preferences: preferences);
        _lastSettingsError = null;
      } catch (error) {
        _lastSettingsError = error;
        _notifyIfAlive();
      }
    }();
  }

  Future<void> _clearSavedSettings() {
    final source = _settingsDataSource;
    if (isDemonstration || source == null) return Future<void>.value();
    final previous = _settingsWrite;
    _settingsWrite = () async {
      await previous;
      await _settingsInitialization;
      try {
        await source.clear();
        _lastSettingsError = null;
      } catch (error) {
        _lastSettingsError = error;
        _notifyIfAlive();
      }
    }();
    return _settingsWrite;
  }

  AiSupportEventType _eventTypeForFeedback(SuggestionFeedbackType type) {
    return switch (type) {
      SuggestionFeedbackType.matchesPerception =>
        AiSupportEventType.matchesPerception,
      SuggestionFeedbackType.doesNotMatch => AiSupportEventType.doesNotMatch,
      SuggestionFeedbackType.preferNotToAnswer =>
        AiSupportEventType.preferNotToAnswer,
      SuggestionFeedbackType.helpful => AiSupportEventType.helpful,
      SuggestionFeedbackType.neutral => AiSupportEventType.neutral,
      SuggestionFeedbackType.notHelpful => AiSupportEventType.notHelpful,
      SuggestionFeedbackType.harmful => AiSupportEventType.harmful,
      SuggestionFeedbackType.dismissed => AiSupportEventType.dismissed,
    };
  }

  SuggestionFeedbackType? _feedbackTypeFromStoredEvent(
    AiSupportEventType type,
  ) => switch (type) {
    AiSupportEventType.dismissed => SuggestionFeedbackType.dismissed,
    AiSupportEventType.matchesPerception =>
      SuggestionFeedbackType.matchesPerception,
    AiSupportEventType.doesNotMatch => SuggestionFeedbackType.doesNotMatch,
    AiSupportEventType.preferNotToAnswer =>
      SuggestionFeedbackType.preferNotToAnswer,
    AiSupportEventType.helpful => SuggestionFeedbackType.helpful,
    AiSupportEventType.neutral => SuggestionFeedbackType.neutral,
    AiSupportEventType.notHelpful => SuggestionFeedbackType.notHelpful,
    AiSupportEventType.harmful => SuggestionFeedbackType.harmful,
    _ => null,
  };

  void _updateBlockedTemplate(
    String templateId,
    SuggestionFeedbackType feedbackType,
  ) {
    switch (feedbackType) {
      case SuggestionFeedbackType.doesNotMatch:
      case SuggestionFeedbackType.notHelpful:
      case SuggestionFeedbackType.harmful:
        _blockedTemplateIds.add(templateId);
      case SuggestionFeedbackType.matchesPerception:
      case SuggestionFeedbackType.helpful:
        _blockedTemplateIds.remove(templateId);
      case SuggestionFeedbackType.preferNotToAnswer:
      case SuggestionFeedbackType.neutral:
      case SuggestionFeedbackType.dismissed:
        break;
    }
  }

  SupportSuggestionCategory? _categoryFromStoredEvent(String value) =>
      switch (value) {
        'reflection' => SupportSuggestionCategory.reflection,
        'exercise' => SupportSuggestionCategory.exercise,
        'video' => SupportSuggestionCategory.video,
        'human_connection' => SupportSuggestionCategory.humanConnection,
        'professional_conversation' =>
          SupportSuggestionCategory.professionalConversation,
        _ => null,
      };

  void _recordRemoteEvent(
    SupportSuggestion suggestion,
    AiSupportEventType type, {
    required AiSupportEventChannel channel,
    DateTime? scheduledFor,
  }) {
    _recordRemoteEventById(
      suggestion.id,
      type,
      channel: channel,
      scheduledFor: scheduledFor,
    );
  }

  void _recordRemoteEventById(
    String suggestionId,
    AiSupportEventType type, {
    required AiSupportEventChannel channel,
    DateTime? scheduledFor,
  }) {
    final source = _eventDataSource;
    if (isDemonstration || source == null || !isAiSupportUuid(suggestionId)) {
      return;
    }
    final previous = _eventWrite;
    _eventWrite = () async {
      await previous;
      try {
        await source.record(
          suggestionId: suggestionId,
          type: type,
          channel: channel,
          scheduledFor: scheduledFor,
        );
        _lastEventError = null;
      } catch (error) {
        _lastEventError = error;
        _notifyIfAlive();
      }
    }();
  }

  String _nextOpaqueId(String prefix, DateTime at) {
    final sequence = _nextSequence++;
    final timestamp = at.toUtc().millisecondsSinceEpoch.toRadixString(36);
    return '$prefix-$timestamp-$sequence';
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
