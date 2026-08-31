import 'support_notification_gateway.dart';

/// Fake manual para testes de store, orquestrador e interface.
class FakeSupportNotificationGateway implements SupportNotificationGateway {
  FakeSupportNotificationGateway({
    this.supported = true,
    this.currentPermission = SupportNotificationPermissionStatus.notGranted,
    this.permissionAfterRequest = SupportNotificationPermissionStatus.granted,
    this.initialCandidateId,
  });

  final bool supported;
  SupportNotificationPermissionStatus currentPermission;
  SupportNotificationPermissionStatus permissionAfterRequest;
  String? initialCandidateId;

  final List<SupportNotificationRequest> scheduled =
      <SupportNotificationRequest>[];
  final List<String> cancelledCandidateIds = <String>[];
  int permissionRequestCount = 0;
  int openSettingsCount = 0;
  int cancelAllCount = 0;
  SupportNotificationOpenHandler? _onOpen;

  @override
  bool get isSupported => supported;

  @override
  Future<String?> initialize({
    required SupportNotificationOpenHandler onOpen,
  }) async {
    _onOpen = onOpen;
    return candidateIdFromSupportNotificationPayload(initialCandidateId);
  }

  @override
  Future<SupportNotificationPermissionStatus> permissionStatus() async {
    return supported
        ? currentPermission
        : SupportNotificationPermissionStatus.unavailable;
  }

  @override
  Future<SupportNotificationPermissionStatus> requestPermission() async {
    permissionRequestCount++;
    if (!supported) return SupportNotificationPermissionStatus.unavailable;
    currentPermission = permissionAfterRequest;
    return currentPermission;
  }

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCount++;
    return supported;
  }

  @override
  Future<void> schedule(SupportNotificationRequest request) async {
    scheduled.add(request);
  }

  @override
  Future<void> cancel(String candidateId) async {
    cancelledCandidateIds.add(candidateId);
    scheduled.removeWhere((item) => item.candidateId == candidateId);
  }

  @override
  Future<void> cancelAllSupportNotifications() async {
    cancelAllCount++;
    scheduled.clear();
  }

  void simulateOpen(String candidateId) {
    final parsed = candidateIdFromSupportNotificationPayload(candidateId);
    if (parsed != null) _onOpen?.call(parsed);
  }
}
