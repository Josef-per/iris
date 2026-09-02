import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/notifications/fake_support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/flutter_local_support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/noop_support_notification_gateway.dart';
import 'package:iris/features/ai_support/notifications/support_notification_gateway.dart';

void main() {
  const candidateId = 'candidate_0123456789abcdef';

  group('contrato de payload', () {
    test('gerador produz ID opaco de 128 bits aceito pelo contrato', () {
      final generated = generateOpaqueSupportNotificationCandidateId();

      expect(generated, hasLength(22));
      expect(isValidSupportNotificationCandidateId(generated), isTrue);
      expect(generated, isNot(contains('candidate')));
    });

    test('aceita somente o candidateId opaco puro', () {
      expect(
        candidateIdFromSupportNotificationPayload(candidateId),
        candidateId,
      );
      expect(
        candidateIdFromSupportNotificationPayload(
          '{"candidateId":"$candidateId"}',
        ),
        isNull,
      );
      expect(
        candidateIdFromSupportNotificationPayload(
          'https://iris.app/support/$candidateId',
        ),
        isNull,
      );
      expect(
        candidateIdFromSupportNotificationPayload('humor difícil'),
        isNull,
      );
    });

    test('pedido rejeita identificador com conteúdo adicional', () {
      expect(
        () => SupportNotificationRequest(
          candidateId: '$candidateId?mood=hard',
          template: SupportNotificationTemplate.gentlePause,
          scheduledAt: DateTime(2026, 8, 24, 12),
        ),
        throwsArgumentError,
      );
    });

    test('templates disponíveis são fechados e resolvidos por ID', () {
      expect(
        SupportNotificationTemplate.tryFromId('notification_pause_gentle_v1'),
        SupportNotificationTemplate.gentlePause,
      );
      expect(
        SupportNotificationTemplate.tryFromId('template_desconhecido'),
        isNull,
      );
    });
  });

  group('fake e noop', () {
    test('fake registra agendamento, cancelamento e abertura', () async {
      final fake = FakeSupportNotificationGateway(
        initialCandidateId: candidateId,
      );
      String? openedCandidateId;

      expect(
        await fake.initialize(onOpen: (value) => openedCandidateId = value),
        candidateId,
      );
      expect(
        await fake.requestPermission(),
        SupportNotificationPermissionStatus.granted,
      );
      expect(fake.permissionRequestCount, 1);

      final request = SupportNotificationRequest(
        candidateId: candidateId,
        template: SupportNotificationTemplate.gentlePause,
        scheduledAt: DateTime(2026, 8, 24, 12),
      );
      await fake.schedule(request);
      expect(fake.scheduled, <SupportNotificationRequest>[request]);

      fake.simulateOpen(candidateId);
      expect(openedCandidateId, candidateId);

      await fake.cancel(candidateId);
      expect(fake.scheduled, isEmpty);
      expect(fake.cancelledCandidateIds, <String>[candidateId]);
    });

    test('noop informa indisponibilidade sem falhar', () async {
      const gateway = NoopSupportNotificationGateway();

      expect(gateway.isSupported, isFalse);
      expect(
        await gateway.permissionStatus(),
        SupportNotificationPermissionStatus.unavailable,
      );
      await gateway.schedule(
        SupportNotificationRequest(
          candidateId: candidateId,
          template: SupportNotificationTemplate.twoMinutes,
          scheduledAt: DateTime(2026, 8, 24, 12),
        ),
      );
    });
  });

  group('configuração nativa', () {
    final gateway = FlutterLocalSupportNotificationGateway(
      platformOverride: TargetPlatform.android,
    );

    test('não solicita permissão automaticamente no iOS', () {
      final iOS = gateway.initializationSettings.iOS!;

      expect(iOS.requestAlertPermission, isFalse);
      expect(iOS.requestBadgePermission, isFalse);
      expect(iOS.requestSoundPermission, isFalse);
      expect(iOS.requestProvisionalPermission, isFalse);
    });

    test('Android usa canal discreto e privacidade configurável', () {
      final generic = gateway
          .notificationDetailsFor(
            SupportNotificationRequest(
              candidateId: candidateId,
              template: SupportNotificationTemplate.supportSuggestion,
              scheduledAt: DateTime(2026, 8, 24, 12),
            ),
          )
          .android!;
      final hidden = gateway
          .notificationDetailsFor(
            SupportNotificationRequest(
              candidateId: candidateId,
              template: SupportNotificationTemplate.supportSuggestion,
              scheduledAt: DateTime(2026, 8, 24, 12),
              privacy: SupportNotificationPrivacy.hidden,
            ),
          )
          .android!;

      expect(
        generic.channelId,
        FlutterLocalSupportNotificationGateway.channelId,
      );
      expect(generic.importance, Importance.low);
      expect(generic.priority, Priority.low);
      expect(generic.playSound, isFalse);
      expect(generic.enableVibration, isFalse);
      expect(generic.channelShowBadge, isFalse);
      expect(generic.visibility, NotificationVisibility.private);
      expect(hidden.visibility, NotificationVisibility.secret);
    });

    test('iOS usa entrega passiva, sem som ou banner em foreground', () {
      final details = gateway
          .notificationDetailsFor(
            SupportNotificationRequest(
              candidateId: candidateId,
              template: SupportNotificationTemplate.gentlePause,
              scheduledAt: DateTime(2026, 8, 24, 12),
            ),
          )
          .iOS!;

      expect(details.presentSound, isFalse);
      expect(details.presentBadge, isFalse);
      expect(details.presentBanner, isFalse);
      expect(details.interruptionLevel, InterruptionLevel.passive);
    });

    test('opção oculta não envia título nem corpo ao sistema', () {
      final request = SupportNotificationRequest(
        candidateId: candidateId,
        template: SupportNotificationTemplate.gentlePause,
        scheduledAt: DateTime(2026, 8, 24, 12),
        privacy: SupportNotificationPrivacy.hidden,
      );

      expect(gateway.notificationTitleFor(request), isNull);
      expect(gateway.notificationBodyFor(request), isNull);
    });

    test('ID nativo é determinístico e fica na faixa reservada', () {
      final id = supportNotificationIdForCandidate(candidateId);

      expect(supportNotificationIdForCandidate(candidateId), id);
      expect(id, inInclusiveRange(1200000000, 1899999999));
      expect(
        supportNotificationIdForCandidate('candidate_fedcba9876543210'),
        isNot(id),
      );
    });
  });
}
