/// Enterprise wall-clock time, independent of the device time zone.
DateTime enterpriseTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 5));

DateTime enterpriseWallTimeToUtc(DateTime date, int hour, int minute) =>
    DateTime.utc(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    ).subtract(const Duration(hours: 5));

String enterpriseDateTimeLabel(DateTime instant) {
  final time = enterpriseTime(instant);
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)} '
      '${twoDigits(time.day)}.${twoDigits(time.month)}.${time.year}';
}
