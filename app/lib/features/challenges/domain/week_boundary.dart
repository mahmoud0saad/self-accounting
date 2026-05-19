enum WeekStartDow { sat, sun, mon }

WeekStartDow weekStartDowFromStorage(String? raw) {
  return switch (raw) {
    'sun' => WeekStartDow.sun,
    'mon' => WeekStartDow.mon,
    _ => WeekStartDow.sat,
  };
}

String weekStartDowToStorage(WeekStartDow dow) {
  return switch (dow) {
    WeekStartDow.sun => 'sun',
    WeekStartDow.mon => 'mon',
    WeekStartDow.sat => 'sat',
  };
}

/// Calendar date at local midnight for [date].
DateTime dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

int _daysSinceWeekStart(DateTime date, WeekStartDow dow) {
  final w = date.weekday;
  return switch (dow) {
    WeekStartDow.sat => (w - DateTime.saturday + 7) % 7,
    WeekStartDow.sun => w == DateTime.sunday ? 0 : w,
    WeekStartDow.mon => (w - DateTime.monday + 7) % 7,
  };
}

DateTime weekStartFor(DateTime date, WeekStartDow dow) {
  final d = dateOnly(date);
  return d.subtract(Duration(days: _daysSinceWeekStart(d, dow)));
}

DateTime weekEndFor(DateTime weekStart) =>
    dateOnly(weekStart).add(const Duration(days: 6));

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<String> datesInWeek(DateTime weekStart, DateTime weekEnd) {
  final out = <String>[];
  var cur = dateOnly(weekStart);
  final end = dateOnly(weekEnd);
  while (!cur.isAfter(end)) {
    out.add(isoDate(cur));
    cur = cur.add(const Duration(days: 1));
  }
  return out;
}
