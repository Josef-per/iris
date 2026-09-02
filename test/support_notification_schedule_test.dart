import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/notifications/support_notification_schedule.dart';

void main() {
  group('SupportNotificationSchedule', () {
    test('mantém um instante que já está na janela permitida', () {
      final now = DateTime(2026, 8, 24, 12, 30);

      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: now,
        expiresAt: now.add(const Duration(hours: 3)),
        window: const NotificationWindow(
          start: SupportTimeOfDay(9),
          end: SupportTimeOfDay(21),
        ),
      );

      expect(result, now);
    });

    test('avança para o início da janela no mesmo dia', () {
      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: DateTime(2026, 8, 24, 8, 40, 12),
        expiresAt: DateTime(2026, 8, 24, 18),
        window: const NotificationWindow(
          start: SupportTimeOfDay(9),
          end: SupportTimeOfDay(18),
        ),
      );

      expect(result, DateTime(2026, 8, 24, 9));
    });

    test('pula dias não permitidos', () {
      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: DateTime(2026, 8, 24, 22), // segunda-feira
        expiresAt: DateTime(2026, 8, 27),
        window: const NotificationWindow(
          start: SupportTimeOfDay(9),
          end: SupportTimeOfDay(18),
          allowedWeekdays: <int>{DateTime.wednesday},
        ),
      );

      expect(result, DateTime(2026, 8, 26, 9));
    });

    test('respeita a origem do dia em janela que cruza meia-noite', () {
      final earlyTuesday = DateTime(2026, 8, 25, 1);

      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: earlyTuesday,
        expiresAt: earlyTuesday.add(const Duration(hours: 2)),
        window: const NotificationWindow(
          start: SupportTimeOfDay(22),
          end: SupportTimeOfDay(6),
          allowedWeekdays: <int>{DateTime.monday},
        ),
      );

      expect(result, earlyTuesday);
    });

    test('não agenda no instante de expiração', () {
      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: DateTime(2026, 8, 24, 22),
        expiresAt: DateTime(2026, 8, 25, 9),
        window: const NotificationWindow(
          start: SupportTimeOfDay(9),
          end: SupportTimeOfDay(18),
        ),
      );

      expect(result, isNull);
    });

    test('retorna silêncio quando nenhum dia está habilitado', () {
      final result = SupportNotificationSchedule.nextAllowedTime(
        notBefore: DateTime(2026, 8, 24, 12),
        expiresAt: DateTime(2026, 9),
        window: const NotificationWindow(allowedWeekdays: <int>{}),
      );

      expect(result, isNull);
    });
  });
}
