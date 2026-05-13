import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/data/static_task_catalog.dart';
import 'package:app/features/checklist/domain/day_completion.dart';
import 'package:app/features/checklist/domain/task.dart';
import 'package:app/features/dashboard/domain/dashboard_aggregator.dart';
import 'package:app/features/dashboard/domain/dashboard_range.dart';

/// Build a `count`-long contiguous window of empty completions ending at
/// `end` (inclusive).
List<DayCompletion> _emptyDays(DayKey end, int count) {
  final out = <DayCompletion>[];
  var cursor = end;
  for (var i = 0; i < count - 1; i++) {
    cursor = cursor.previousDay();
  }
  for (var i = 0; i < count; i++) {
    out.add(
      DayCompletion(
        day: cursor,
        completedPoints: 0,
        totalPoints: 74,
        completedTasks: 0,
        totalTasks: 34,
        fardMet: false,
      ),
    );
    cursor = cursor.nextDay();
  }
  return out;
}

/// Build a `count`-long window where every day completes the entire catalog.
List<DayCompletion> _fullDays(DayKey end, int count) {
  final allIds = {for (final t in staticTaskCatalog) t.id};
  final out = <DayCompletion>[];
  var cursor = end;
  for (var i = 0; i < count - 1; i++) {
    cursor = cursor.previousDay();
  }
  for (var i = 0; i < count; i++) {
    out.add(
      DayCompletion(
        day: cursor,
        completedPoints: 74,
        totalPoints: 74,
        completedTasks: 34,
        totalTasks: 34,
        fardMet: true,
        completedTaskIds: allIds,
      ),
    );
    cursor = cursor.nextDay();
  }
  return out;
}

void main() {
  const aggregator = DashboardAggregator();

  group('empty input', () {
    for (final range in DashboardRange.values) {
      test('${range.name} → zero everywhere', () {
        final today = DayKey(year: 2026, month: 5, day: 13);
        final days = _emptyDays(today, range.days);

        final data = aggregator.compute(
          days: days,
          catalog: staticTaskCatalog,
          range: range,
          today: today,
          firstDayOfWeekIndex: 0,
        );

        expect(
          data.heatmap.length,
          range.days,
          reason: 'heatmap is always per-day',
        );
        expect(
          data.categories.length,
          TaskCategory.values.length,
          reason: 'one slot per category',
        );
        expect(data.daysWithAnyActivity, 0);

        for (final bar in data.bars) {
          expect(bar.fraction, 0);
          expect(bar.fardMet, isFalse);
        }
        for (final cell in data.heatmap) {
          expect(cell.fraction, 0);
        }
        for (final c in data.categories) {
          expect(c.completedPoints, 0);
          expect(c.completedDayCount, 0);
          expect(c.fraction, 0);
        }
      });
    }
  });

  test('week7 fully complete → everything at 1.0', () {
    final today = DayKey(year: 2026, month: 5, day: 13);
    final days = _fullDays(today, 7);

    final data = aggregator.compute(
      days: days,
      catalog: staticTaskCatalog,
      range: DashboardRange.week7,
      today: today,
      firstDayOfWeekIndex: 0,
    );

    expect(data.bars.length, 7);
    expect(data.heatmap.length, 7);
    expect(data.daysWithAnyActivity, 7);

    for (final bar in data.bars) {
      expect(bar.fraction, 1.0);
      expect(bar.fardMet, isTrue);
    }
    for (final cell in data.heatmap) {
      expect(cell.fraction, 1.0);
      expect(cell.fardMet, isTrue);
    }
    for (final c in data.categories) {
      expect(c.fraction, 1.0, reason: '${c.category.name} should be 100%');
      expect(c.completedDayCount, 7);
      expect(c.totalDayCount, 7);
    }
  });

  test('month30 mixed → category fractions match hand-computed averages', () {
    final today = DayKey(year: 2026, month: 5, day: 31);
    // Build the 30-day list directly so we can interleave full/empty days
    // deterministically (15 full, 15 empty).
    final allIds = {for (final t in staticTaskCatalog) t.id};
    var cursor = today;
    for (var i = 0; i < 29; i++) {
      cursor = cursor.previousDay();
    }
    final days = <DayCompletion>[];
    for (var i = 0; i < 30; i++) {
      final isFull = i.isEven;
      days.add(
        DayCompletion(
          day: cursor,
          completedPoints: isFull ? 74 : 0,
          totalPoints: 74,
          completedTasks: isFull ? 34 : 0,
          totalTasks: 34,
          fardMet: isFull,
          completedTaskIds: isFull ? allIds : const <String>{},
        ),
      );
      cursor = cursor.nextDay();
    }

    final data = aggregator.compute(
      days: days,
      catalog: staticTaskCatalog,
      range: DashboardRange.month30,
      today: today,
      firstDayOfWeekIndex: 0,
    );

    expect(data.bars.length, 30, reason: 'one bar per day for month30');
    expect(data.heatmap.length, 30);
    expect(data.daysWithAnyActivity, 15);

    // Every category was either 100% complete (on the 15 full days) or
    // 0% (on the 15 empty days). The fraction across the window is
    // 15 full days × points / (30 days × points) = 0.5.
    for (final c in data.categories) {
      expect(
        c.fraction,
        closeTo(0.5, 1e-9),
        reason: '${c.category.name} expected 50%',
      );
      expect(c.completedDayCount, 15);
    }
  });

  test(
    'days90 first-week-only → 13 buckets, only the oldest has full coverage',
    () {
      // Pin today so the window starts on a Sunday (firstDayOfWeekIndex = 0
      // EN convention). 2026-01-04 is a Sunday; 89 days later is 2026-04-03.
      final today = DayKey(year: 2026, month: 4, day: 3);
      final start = DayKey(year: 2026, month: 1, day: 4);
      // Sanity check the test fixture itself.
      expect(start.toLocalDateTime().weekday, DateTime.sunday);
      expect(today.daysSince(start), 89);

      final full = _fullDays(start.previousDay(), 0); // dummy for type
      final days = <DayCompletion>[];
      final allIds = {for (final t in staticTaskCatalog) t.id};
      var cursor = start;
      for (var i = 0; i < 90; i++) {
        final isFull = i < 7;
        days.add(
          DayCompletion(
            day: cursor,
            completedPoints: isFull ? 74 : 0,
            totalPoints: 74,
            completedTasks: isFull ? 34 : 0,
            totalTasks: 34,
            fardMet: isFull,
            completedTaskIds: isFull ? allIds : const <String>{},
          ),
        );
        cursor = cursor.nextDay();
      }
      // Reference the unused helper output so analyzer doesn't flag it.
      expect(full, isEmpty);

      final data = aggregator.compute(
        days: days,
        catalog: staticTaskCatalog,
        range: DashboardRange.days90,
        today: today,
        firstDayOfWeekIndex: 0,
      );

      expect(data.bars.length, 13, reason: '90 days bucketed into ~13 weeks');
      expect(data.heatmap.length, 90, reason: 'heatmap stays per-day');

      // First bucket = first 7 days, all complete.
      expect(data.bars.first.fraction, 1.0);
      expect(data.bars.first.fardMet, isTrue);

      // All subsequent buckets are empty.
      for (final bar in data.bars.skip(1)) {
        expect(bar.fraction, 0.0);
        expect(bar.fardMet, isFalse);
      }
    },
  );

  test('locale-aware bucketing — Sunday vs Saturday start produces different '
      'bucket counts', () {
    // Window: Mon 2026-01-05 → Sat 2026-04-04 (90 days). Sundays and
    // Saturdays fall at known offsets so bucket counts diverge.
    final today = DayKey(year: 2026, month: 4, day: 4);
    final start = DayKey(year: 2026, month: 1, day: 5);
    expect(start.toLocalDateTime().weekday, DateTime.monday);
    expect(today.toLocalDateTime().weekday, DateTime.saturday);

    final allIds = {for (final t in staticTaskCatalog) t.id};
    final days = <DayCompletion>[];
    var cursor = start;
    for (var i = 0; i < 90; i++) {
      days.add(
        DayCompletion(
          day: cursor,
          completedPoints: 74,
          totalPoints: 74,
          completedTasks: 34,
          totalTasks: 34,
          fardMet: true,
          completedTaskIds: allIds,
        ),
      );
      cursor = cursor.nextDay();
    }

    final sundayStart = aggregator.compute(
      days: days,
      catalog: staticTaskCatalog,
      range: DashboardRange.days90,
      today: today,
      firstDayOfWeekIndex: 0,
    );
    final saturdayStart = aggregator.compute(
      days: days,
      catalog: staticTaskCatalog,
      range: DashboardRange.days90,
      today: today,
      firstDayOfWeekIndex: 6,
    );

    expect(
      sundayStart.bars.length,
      isNot(equals(saturdayStart.bars.length)),
      reason: 'bucketing should respect firstDayOfWeekIndex',
    );
  });
}
