import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

import 'support_notification_gateway.dart';

typedef LocalTimeZoneIdentifierResolver = Future<String> Function();

/// Entrega local para Android e iOS.
///
/// A inicialização é silenciosa. O prompt do sistema só aparece após uma
/// chamada explícita a [requestPermission].
class FlutterLocalSupportNotificationGateway
    implements SupportNotificationGateway {
  FlutterLocalSupportNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    LocalTimeZoneIdentifierResolver? localTimeZoneIdentifierResolver,
    TargetPlatform? platformOverride,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localTimeZoneIdentifierResolver =
           localTimeZoneIdentifierResolver ?? _deviceTimeZoneIdentifier,
       _platformOverride = platformOverride;

  static const String channelId = 'iris_support_v1';
  static const String channelName = 'Sugestões de apoio';
  static const String threadIdentifier = 'iris_support';
  static const String notificationTitle = 'Íris';

  final FlutterLocalNotificationsPlugin _plugin;
  final LocalTimeZoneIdentifierResolver _localTimeZoneIdentifierResolver;
  final TargetPlatform? _platformOverride;

  SupportNotificationOpenHandler? _onOpen;
  bool _initialized = false;

  TargetPlatform get _platform => _platformOverride ?? defaultTargetPlatform;

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    return _platform == TargetPlatform.android ||
        _platform == TargetPlatform.iOS;
  }

  @visibleForTesting
  InitializationSettings get initializationSettings {
    return const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_iris_support'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestProvisionalPermission: false,
        defaultPresentAlert: false,
        defaultPresentBadge: false,
        defaultPresentSound: false,
        defaultPresentBanner: false,
        defaultPresentList: true,
      ),
    );
  }

  @visibleForTesting
  NotificationDetails notificationDetailsFor(
    SupportNotificationRequest request,
  ) {
    final visibility = request.privacy == SupportNotificationPrivacy.hidden
        ? NotificationVisibility.secret
        : NotificationVisibility.private;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Convites breves e opcionais de apoio.',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
        onlyAlertOnce: true,
        silent: true,
        visibility: visibility,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        presentBanner: false,
        presentList: true,
        threadIdentifier: threadIdentifier,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  @visibleForTesting
  String? notificationTitleFor(SupportNotificationRequest request) {
    return request.privacy == SupportNotificationPrivacy.hidden
        ? null
        : notificationTitle;
  }

  @visibleForTesting
  String? notificationBodyFor(SupportNotificationRequest request) {
    return request.privacy == SupportNotificationPrivacy.hidden
        ? null
        : request.template.body;
  }

  @override
  Future<String?> initialize({
    required SupportNotificationOpenHandler onOpen,
  }) async {
    _onOpen = onOpen;
    if (!isSupported) return null;

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    time_zone_data.initializeTimeZones();
    final identifier = await _localTimeZoneIdentifierResolver();
    time_zone.setLocalLocation(time_zone.getLocation(identifier));
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return null;
    return candidateIdFromSupportNotificationPayload(
      launchDetails?.notificationResponse?.payload,
    );
  }

  @override
  Future<SupportNotificationPermissionStatus> permissionStatus() async {
    if (!isSupported) {
      return SupportNotificationPermissionStatus.unavailable;
    }
    _requireInitialized();

    if (_platform == TargetPlatform.android) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled == true
          ? SupportNotificationPermissionStatus.granted
          : SupportNotificationPermissionStatus.notGranted;
    }

    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    if (options?.isProvisionalEnabled == true) {
      return SupportNotificationPermissionStatus.provisional;
    }
    return options?.isEnabled == true
        ? SupportNotificationPermissionStatus.granted
        : SupportNotificationPermissionStatus.notGranted;
  }

  @override
  Future<SupportNotificationPermissionStatus> requestPermission() async {
    if (!isSupported) {
      return SupportNotificationPermissionStatus.unavailable;
    }
    _requireInitialized();

    if (_platform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: false);
    }
    return permissionStatus();
  }

  @override
  Future<bool> openSystemSettings() async {
    if (!isSupported) return false;
    _requireInitialized();
    return await _plugin.openAppNotificationSettings() ?? false;
  }

  @override
  Future<void> schedule(SupportNotificationRequest request) async {
    if (!isSupported) return;
    _requireInitialized();

    await _plugin.zonedSchedule(
      id: supportNotificationIdForCandidate(request.candidateId),
      title: notificationTitleFor(request),
      body: notificationBodyFor(request),
      scheduledDate: time_zone.TZDateTime.from(
        request.scheduledAt,
        time_zone.local,
      ),
      notificationDetails: notificationDetailsFor(request),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: request.candidateId,
    );
  }

  @override
  Future<void> cancel(String candidateId) async {
    if (!isSupported) return;
    _requireInitialized();
    if (!isValidSupportNotificationCandidateId(candidateId)) return;
    await _plugin.cancel(id: supportNotificationIdForCandidate(candidateId));
  }

  @override
  Future<void> cancelAllSupportNotifications() async {
    if (!isSupported) return;
    _requireInitialized();
    final ids = <int>{};

    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      final candidateId = candidateIdFromSupportNotificationPayload(
        notification.payload,
      );
      if (candidateId != null &&
          notification.id == supportNotificationIdForCandidate(candidateId)) {
        ids.add(notification.id);
      }
    }

    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final belongsToSupport =
            notification.channelId == channelId ||
            notification.groupKey == threadIdentifier;
        if (belongsToSupport && notification.id != null) {
          ids.add(notification.id!);
        }
      }
    } on UnimplementedError {
      // A lista pendente ainda permite cancelar agendamentos em plataformas
      // que não expõem notificações já exibidas.
    } on UnsupportedError {
      // Mesmo fallback acima.
    }

    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.notificationResponseType ==
        NotificationResponseType.notificationDismissed) {
      return;
    }
    final candidateId = candidateIdFromSupportNotificationPayload(
      response.payload,
    );
    if (candidateId != null) _onOpen?.call(candidateId);
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError(
        'Inicialize SupportNotificationGateway antes de usá-lo.',
      );
    }
  }

  static Future<String> _deviceTimeZoneIdentifier() async {
    final current = await FlutterTimezone.getLocalTimezone();
    return current.identifier;
  }
}

/// Reserva uma faixa alta de IDs para não conflitar com outros lembretes.
int supportNotificationIdForCandidate(String candidateId) {
  if (!isValidSupportNotificationCandidateId(candidateId)) {
    throw ArgumentError.value(candidateId, 'candidateId');
  }
  var hash = 0x811c9dc5;
  for (final unit in candidateId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 1200000000 + ((hash & 0x7fffffff) % 700000000);
}
