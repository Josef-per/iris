import 'support_notification_gateway.dart';

/// Fallback para plataformas sem entrega local suportada nesta fase.
class NoopSupportNotificationGateway implements SupportNotificationGateway {
  const NoopSupportNotificationGateway();

  @override
  bool get isSupported => false;

  @override
  Future<String?> initialize({
    required SupportNotificationOpenHandler onOpen,
  }) async => null;

  @override
  Future<SupportNotificationPermissionStatus> permissionStatus() async {
    return SupportNotificationPermissionStatus.unavailable;
  }

  @override
  Future<SupportNotificationPermissionStatus> requestPermission() async {
    return SupportNotificationPermissionStatus.unavailable;
  }

  @override
  Future<bool> openSystemSettings() async => false;

  @override
  Future<void> schedule(SupportNotificationRequest request) async {}

  @override
  Future<void> cancel(String candidateId) async {}

  @override
  Future<void> cancelAllSupportNotifications() async {}
}
