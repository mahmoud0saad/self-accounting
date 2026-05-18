/// Calendar day in the device's local timezone (no UTC normalization).
final class DayKey implements Comparable<DayKey> {
  const DayKey({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  factory DayKey.fromLocalDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DayKey(year: local.year, month: local.month, day: local.day);
  }

  factory DayKey.today() => DayKey.fromLocalDateTime(DateTime.now());

  factory DayKey.parseIso(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected YYYY-MM-DD, got $iso');
    }
    return DayKey(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
    );
  }

  DateTime toLocalDateTime() => DateTime(year, month, day);

  String toIsoDate() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  DayKey previousDay() {
    final dt = toLocalDateTime().subtract(const Duration(days: 1));
    return DayKey.fromLocalDateTime(dt);
  }

  DayKey nextDay() {
    final dt = toLocalDateTime().add(const Duration(days: 1));
    return DayKey.fromLocalDateTime(dt);
  }

  /// Whole calendar days from [other] to this (negative if this is before other).
  int daysSince(DayKey other) {
    final a = toLocalDateTime();
    final b = other.toLocalDateTime();
    return a.difference(b).inDays;
  }

  @override
  int compareTo(DayKey other) {
    final c = year.compareTo(other.year);
    if (c != 0) {
      return c;
    }
    final cm = month.compareTo(other.month);
    if (cm != 0) {
      return cm;
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is DayKey &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'DayKey(${toIsoDate()})';
}
