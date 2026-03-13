String deviceTimezone() {
  final tz = DateTime.now().timeZoneName.trim();
  return tz.isEmpty ? 'UTC' : tz;
}

DateTime localNow() => DateTime.now();

DateTime asLocal(DateTime value) => value.toLocal();

bool isSameLocalDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
