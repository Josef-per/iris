import 'package:iris/features/ai_support/domain/notification_preferences.dart';

/// Cálculo puro do próximo instante permitido pela janela escolhida.
abstract final class SupportNotificationSchedule {
  /// Retorna o primeiro instante igual ou posterior a [notBefore] que pertence
  /// à janela. Retorna `null` quando não há dia habilitado ou quando o primeiro
  /// instante possível já estaria expirado.
  ///
  /// A busca é limitada a oito dias: toda configuração semanal válida deve
  /// possuir um horário nesse intervalo. A decisão de descartar em vez de
  /// adiar para outra janela continua pertencendo à política/orquestrador.
  static DateTime? nextAllowedTime({
    required DateTime notBefore,
    required DateTime expiresAt,
    required NotificationWindow window,
  }) {
    if (!notBefore.isBefore(expiresAt) || window.allowedWeekdays.isEmpty) {
      return null;
    }
    if (window.contains(notBefore)) return notBefore;

    var cursor = DateTime(
      notBefore.year,
      notBefore.month,
      notBefore.day,
      notBefore.hour,
      notBefore.minute,
    );
    if (cursor.isBefore(notBefore)) {
      cursor = cursor.add(const Duration(minutes: 1));
    }
    final searchEndsAt = notBefore.add(const Duration(days: 8));

    while (cursor.isBefore(expiresAt) && !cursor.isAfter(searchEndsAt)) {
      if (window.contains(cursor)) return cursor;
      cursor = cursor.add(const Duration(minutes: 1));
    }
    return null;
  }
}
