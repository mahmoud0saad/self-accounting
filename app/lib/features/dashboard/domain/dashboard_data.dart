import '../../../core/time/day_key.dart';
import '../../checklist/domain/task.dart';
import 'dashboard_range.dart';

/// Single bar in the daily-completion bar chart.
///
/// For [DashboardRange.days90] this represents a **weekly** bucket whose
/// [fraction] is the average across the seven calendar days of that week
/// and whose [day] is the **first** day of the bucket. For shorter ranges
/// this is one calendar day.
class DailyBar {
  const DailyBar({
    required this.day,
    required this.fraction,
    required this.fardMet,
  });

  final DayKey day;
  final double fraction;
  final bool fardMet;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyBar &&
          other.day == day &&
          other.fraction == fraction &&
          other.fardMet == fardMet;

  @override
  int get hashCode => Object.hash(day, fraction, fardMet);
}

/// Single cell in the per-day heatmap.
class HeatmapCell {
  const HeatmapCell({
    required this.day,
    required this.fraction,
    required this.fardMet,
  });

  final DayKey day;
  final double fraction;
  final bool fardMet;

  int get percentInt => (fraction * 100).round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCell &&
          other.day == day &&
          other.fraction == fraction &&
          other.fardMet == fardMet;

  @override
  int get hashCode => Object.hash(day, fraction, fardMet);
}

/// Aggregated completion for one [TaskCategory] across the active range.
class CategoryCompletion {
  const CategoryCompletion({
    required this.category,
    required this.completedPoints,
    required this.totalPoints,
    required this.completedDayCount,
    required this.totalDayCount,
  });

  final TaskCategory category;

  /// Sum of catalog points credited across the range.
  final int completedPoints;

  /// Sum of catalog points available across the range (sum across all days).
  final int totalPoints;

  /// Number of days within the range where at least one task of this category
  /// was completed.
  final int completedDayCount;
  final int totalDayCount;

  double get fraction => totalPoints == 0 ? 0.0 : completedPoints / totalPoints;

  int get percentInt => (fraction * 100).round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryCompletion &&
          other.category == category &&
          other.completedPoints == completedPoints &&
          other.totalPoints == totalPoints &&
          other.completedDayCount == completedDayCount &&
          other.totalDayCount == totalDayCount;

  @override
  int get hashCode => Object.hash(
    category,
    completedPoints,
    totalPoints,
    completedDayCount,
    totalDayCount,
  );
}

/// Aggregated dashboard view-model. One instance per `(range, days, catalog)`
/// snapshot; field equality lets selector providers suppress no-op rebuilds.
class DashboardData {
  const DashboardData({
    required this.range,
    required this.bars,
    required this.heatmap,
    required this.categories,
    required this.daysWithAnyActivity,
  });

  final DashboardRange range;
  final List<DailyBar> bars;
  final List<HeatmapCell> heatmap;
  final List<CategoryCompletion> categories;
  final int daysWithAnyActivity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DashboardData) return false;
    if (other.range != range) return false;
    if (other.daysWithAnyActivity != daysWithAnyActivity) return false;
    if (other.bars.length != bars.length) return false;
    for (var i = 0; i < bars.length; i++) {
      if (other.bars[i] != bars[i]) return false;
    }
    if (other.heatmap.length != heatmap.length) return false;
    for (var i = 0; i < heatmap.length; i++) {
      if (other.heatmap[i] != heatmap[i]) return false;
    }
    if (other.categories.length != categories.length) return false;
    for (var i = 0; i < categories.length; i++) {
      if (other.categories[i] != categories[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    range,
    daysWithAnyActivity,
    Object.hashAll(bars),
    Object.hashAll(heatmap),
    Object.hashAll(categories),
  );
}
