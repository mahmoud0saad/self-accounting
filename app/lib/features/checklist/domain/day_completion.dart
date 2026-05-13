import '../../../core/time/day_key.dart';

/// Per-day completion summary derived from `daily_logs` rows.
///
/// Equality is field-based so `StreamProvider` listeners suppress duplicate
/// re-emissions when nothing relevant has changed (see requirements R6).
class DayCompletion {
  const DayCompletion({
    required this.day,
    required this.completedPoints,
    required this.totalPoints,
    required this.completedTasks,
    required this.totalTasks,
    required this.fardMet,
  });

  final DayKey day;
  final int completedPoints;
  final int totalPoints;
  final int completedTasks;
  final int totalTasks;
  final bool fardMet;

  double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;

  int get percentInt => (fraction * 100).round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayCompletion &&
          other.day == day &&
          other.completedPoints == completedPoints &&
          other.totalPoints == totalPoints &&
          other.completedTasks == completedTasks &&
          other.totalTasks == totalTasks &&
          other.fardMet == fardMet;

  @override
  int get hashCode => Object.hash(
    day,
    completedPoints,
    totalPoints,
    completedTasks,
    totalTasks,
    fardMet,
  );

  @override
  String toString() =>
      'DayCompletion(${day.toIsoDate()}, '
      '$completedPoints/$totalPoints pts, '
      'fardMet=$fardMet)';
}
