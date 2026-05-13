import '../../../core/time/day_key.dart';

/// Per-day completion summary derived from `daily_logs` rows.
///
/// Equality is field-based so `StreamProvider` listeners suppress duplicate
/// re-emissions when nothing relevant has changed (see requirements R6).
class DayCompletion {
  DayCompletion({
    required this.day,
    required this.completedPoints,
    required this.totalPoints,
    required this.completedTasks,
    required this.totalTasks,
    required this.fardMet,
    Set<String>? completedTaskIds,
  }) : completedTaskIds = completedTaskIds == null
           ? const <String>{}
           : Set<String>.unmodifiable(completedTaskIds);

  final DayKey day;
  final int completedPoints;
  final int totalPoints;
  final int completedTasks;
  final int totalTasks;
  final bool fardMet;

  /// Task ids completed on this day (Phase 4 widening). Used by
  /// `DashboardAggregator` to compute per-category breakdowns without an
  /// additional repository query.
  ///
  /// Empty for synthetic test instances that pre-date Phase 4 — the per-task
  /// fidelity is opt-in.
  final Set<String> completedTaskIds;

  double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;

  int get percentInt => (fraction * 100).round();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DayCompletion) return false;
    if (other.day != day) return false;
    if (other.completedPoints != completedPoints) return false;
    if (other.totalPoints != totalPoints) return false;
    if (other.completedTasks != completedTasks) return false;
    if (other.totalTasks != totalTasks) return false;
    if (other.fardMet != fardMet) return false;
    if (other.completedTaskIds.length != completedTaskIds.length) return false;
    return other.completedTaskIds.containsAll(completedTaskIds);
  }

  @override
  int get hashCode => Object.hash(
    day,
    completedPoints,
    totalPoints,
    completedTasks,
    totalTasks,
    fardMet,
    Object.hashAllUnordered(completedTaskIds),
  );

  @override
  String toString() =>
      'DayCompletion(${day.toIsoDate()}, '
      '$completedPoints/$totalPoints pts, '
      'fardMet=$fardMet, '
      'ids=${completedTaskIds.length})';
}
