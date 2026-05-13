import '../../../core/time/day_key.dart';
import '../../checklist/domain/day_completion.dart';
import '../../checklist/domain/task.dart';
import 'dashboard_data.dart';
import 'dashboard_range.dart';

/// Pure-Dart aggregator that turns the [HistoryRepository]'s window of
/// [DayCompletion]s into the view-model the Dashboard renders.
///
/// Performance: O(N × T) where N ≤ 90 (range days) and T = 34 catalog tasks
/// → ≤ 3060 iterations per recompute. Runs synchronously; no isolate.
class DashboardAggregator {
  const DashboardAggregator();

  /// Computes the dashboard's view-model.
  ///
  /// [days] must be the contiguous calendar window of length [range.days]
  /// ending at [today]; the aggregator assumes the upstream provider has
  /// already sized the window correctly.
  ///
  /// [firstDayOfWeekIndex] follows the [MaterialLocalizations] convention:
  /// `0` = Sunday, `1` = Monday, …, `6` = Saturday. Used only for
  /// [DashboardRange.days90] weekly bucketing.
  DashboardData compute({
    required List<DayCompletion> days,
    required Iterable<Task> catalog,
    required DashboardRange range,
    required DayKey today,
    required int firstDayOfWeekIndex,
  }) {
    assert(
      days.length == range.days,
      'aggregator: expected ${range.days} days, got ${days.length}',
    );
    assert(
      firstDayOfWeekIndex >= 0 && firstDayOfWeekIndex <= 6,
      'firstDayOfWeekIndex must be in 0..6',
    );

    final catalogList = catalog.toList(growable: false);

    final bars = range == DashboardRange.days90
        ? _weeklyBars(days, firstDayOfWeekIndex)
        : <DailyBar>[
            for (final dc in days)
              DailyBar(day: dc.day, fraction: dc.fraction, fardMet: dc.fardMet),
          ];

    final heatmap = <HeatmapCell>[
      for (final dc in days)
        HeatmapCell(day: dc.day, fraction: dc.fraction, fardMet: dc.fardMet),
    ];

    final categories = _byCategory(days, catalogList);

    final daysWithAnyActivity = days.where((d) => d.completedTasks > 0).length;

    return DashboardData(
      range: range,
      bars: bars,
      heatmap: heatmap,
      categories: categories,
      daysWithAnyActivity: daysWithAnyActivity,
    );
  }

  List<DailyBar> _weeklyBars(
    List<DayCompletion> days,
    int firstDayOfWeekIndex,
  ) {
    if (days.isEmpty) return const <DailyBar>[];

    final buckets = <List<DayCompletion>>[];
    var current = <DayCompletion>[];

    for (final dc in days) {
      final dt = dc.day.toLocalDateTime();
      final dartWeekday = dt.weekday % 7; // Dart 1..7 (Mon..Sun) → 1..6, 0
      if (dartWeekday == firstDayOfWeekIndex && current.isNotEmpty) {
        buckets.add(current);
        current = <DayCompletion>[];
      }
      current.add(dc);
    }
    if (current.isNotEmpty) {
      buckets.add(current);
    }

    return [
      for (final bucket in buckets)
        DailyBar(
          day: bucket.first.day,
          // Average across the full calendar week (always /7) so a sparse
          // week reads honestly (R6).
          fraction: bucket.fold<double>(0.0, (s, d) => s + d.fraction) / 7.0,
          fardMet: bucket.every((d) => d.fardMet),
        ),
    ];
  }

  List<CategoryCompletion> _byCategory(
    List<DayCompletion> days,
    List<Task> catalog,
  ) {
    final byCategory = <TaskCategory, List<Task>>{};
    for (final t in catalog) {
      byCategory.putIfAbsent(t.category, () => <Task>[]).add(t);
    }

    final taskPoints = <String, int>{for (final t in catalog) t.id: t.points};
    final taskCategory = <String, TaskCategory>{
      for (final t in catalog) t.id: t.category,
    };

    return <CategoryCompletion>[
      for (final category in TaskCategory.values)
        _categoryFor(
          category,
          days,
          byCategory[category] ?? const <Task>[],
          taskPoints,
          taskCategory,
        ),
    ];
  }

  CategoryCompletion _categoryFor(
    TaskCategory category,
    List<DayCompletion> days,
    List<Task> tasksInCategory,
    Map<String, int> taskPoints,
    Map<String, TaskCategory> taskCategory,
  ) {
    final pointsPerDay = tasksInCategory.fold<int>(0, (s, t) => s + t.points);
    final totalPoints = pointsPerDay * days.length;

    var completedPoints = 0;
    var completedDayCount = 0;

    for (final dc in days) {
      var dayPoints = 0;
      for (final id in dc.completedTaskIds) {
        if (taskCategory[id] == category) {
          dayPoints += taskPoints[id] ?? 0;
        }
      }
      completedPoints += dayPoints;
      if (dayPoints > 0) completedDayCount += 1;
    }

    return CategoryCompletion(
      category: category,
      completedPoints: completedPoints,
      totalPoints: totalPoints,
      completedDayCount: completedDayCount,
      totalDayCount: days.length,
    );
  }
}
