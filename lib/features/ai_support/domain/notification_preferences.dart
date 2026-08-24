/// Horário local sem dependência de widgets ou de permissões de plataforma.
class SupportTimeOfDay implements Comparable<SupportTimeOfDay> {
  const SupportTimeOfDay(this.hour, [this.minute = 0])
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  String get label {
    final displayedMinute = minute.toString().padLeft(2, '0');
    return '$hour:$displayedMinute';
  }

  @override
  int compareTo(SupportTimeOfDay other) {
    return minutesSinceMidnight.compareTo(other.minutesSinceMidnight);
  }
}

/// Faixa de horário e dias em que uma notificação simulada pode ser exibida.
///
/// Para janelas que cruzam meia-noite, por exemplo 22:00–06:00, o começo da
/// janela define o dia permitido. Assim, 02:00 de terça pertence à janela de
/// segunda-feira.
class NotificationWindow {
  const NotificationWindow({
    this.start = const SupportTimeOfDay(9),
    this.end = const SupportTimeOfDay(21),
    this.allowedWeekdays = const <int>{
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    },
    this.isAllDay = false,
  });

  final SupportTimeOfDay start;
  final SupportTimeOfDay end;
  final Set<int> allowedWeekdays;
  final bool isAllDay;

  bool contains(DateTime localTime) {
    if (!allowedWeekdays.contains(localTime.weekday)) {
      if (!crossesMidnight ||
          localTime.hour * 60 + localTime.minute >=
              start.minutesSinceMidnight) {
        return false;
      }
    }
    if (coversAllDay) return allowedWeekdays.contains(localTime.weekday);

    final minute = localTime.hour * 60 + localTime.minute;
    if (!crossesMidnight) {
      return allowedWeekdays.contains(localTime.weekday) &&
          minute >= start.minutesSinceMidnight &&
          minute < end.minutesSinceMidnight;
    }
    if (minute >= start.minutesSinceMidnight) {
      return allowedWeekdays.contains(localTime.weekday);
    }
    if (minute < end.minutesSinceMidnight) {
      return allowedWeekdays.contains(_previousWeekday(localTime.weekday));
    }
    return false;
  }

  bool get crossesMidnight {
    return !coversAllDay &&
        start.minutesSinceMidnight > end.minutesSinceMidnight;
  }

  /// Horários iguais representam a janela completa do dia.
  bool get coversAllDay {
    return isAllDay || start.minutesSinceMidnight == end.minutesSinceMidnight;
  }

  int _previousWeekday(int weekday) {
    return weekday == DateTime.monday ? DateTime.sunday : weekday - 1;
  }

  NotificationWindow copyWith({
    SupportTimeOfDay? start,
    SupportTimeOfDay? end,
    Set<int>? allowedWeekdays,
    bool? isAllDay,
  }) {
    return NotificationWindow(
      start: start ?? this.start,
      end: end ?? this.end,
      allowedWeekdays: allowedWeekdays ?? this.allowedWeekdays,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }
}

enum NotificationFrequency {
  never,
  oncePerWeek,
  twicePerWeek,
  threeTimesPerWeek;

  int get maxPerWeek => switch (this) {
    NotificationFrequency.never => 0,
    NotificationFrequency.oncePerWeek => 1,
    NotificationFrequency.twicePerWeek => 2,
    NotificationFrequency.threeTimesPerWeek => 3,
  };
}

/// Conteúdo permitido na prévia de tela bloqueada.
///
/// A opção [generic] só pode apontar para um template genérico aprovado.
enum LockScreenPreview { none, generic }

/// Preferências específicas da entrega de notificações simuladas.
class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.frequency = NotificationFrequency.never,
    this.window = const NotificationWindow(),
    this.lockScreenPreview = LockScreenPreview.generic,
    this.soundEnabled = false,
    this.vibrationEnabled = false,
    this.pausedUntil,
  });

  final bool enabled;
  final NotificationFrequency frequency;
  final NotificationWindow window;
  final LockScreenPreview lockScreenPreview;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime? pausedUntil;

  bool get allowsDelivery =>
      enabled && frequency != NotificationFrequency.never;

  bool isPausedAt(DateTime now) {
    final until = pausedUntil;
    return until != null && now.isBefore(until);
  }

  NotificationPreferences copyWith({
    bool? enabled,
    NotificationFrequency? frequency,
    NotificationWindow? window,
    LockScreenPreview? lockScreenPreview,
    bool? soundEnabled,
    bool? vibrationEnabled,
    DateTime? pausedUntil,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      window: window ?? this.window,
      lockScreenPreview: lockScreenPreview ?? this.lockScreenPreview,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      pausedUntil: pausedUntil ?? this.pausedUntil,
    );
  }

  NotificationPreferences withPauseUntil(DateTime? until) {
    return NotificationPreferences(
      enabled: enabled,
      frequency: frequency,
      window: window,
      lockScreenPreview: lockScreenPreview,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      pausedUntil: until,
    );
  }
}
