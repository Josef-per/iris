class LocalDay {
  const LocalDay._();

  static String key(DateTime instant) {
    final local = instant.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String timeZone(DateTime instant) {
    final local = instant.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absoluteMinutes = offset.inMinutes.abs();
    final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
    final name = local.timeZoneName.trim();
    final utcOffset = 'UTC$sign$hours:$minutes';

    return name.isEmpty ? utcOffset : '$name ($utcOffset)';
  }

  static DateTime start(DateTime instant) {
    final local = instant.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime end(DateTime instant) =>
      start(instant).add(const Duration(days: 1));
}
