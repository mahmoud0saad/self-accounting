import '../../../core/time/day_key.dart';
import 'day_completion.dart';
import 'streak.dart';

/// Pure-Dart streak math over a list of [DayCompletion] entries.
///
/// `current` counts back from today (if today.fardMet) or yesterday (grace
/// window, D4 — today's pending fard does not break the streak yet).
/// `longest` is the longest run of consecutive fard-met days anywhere in the
/// supplied window.
class StreakCalculator {
  const StreakCalculator();

  Streak compute(List<DayCompletion> days, {required DayKey today}) {
    if (days.isEmpty) {
      return Streak.empty;
    }

    final byKey = <DayKey, DayCompletion>{for (final d in days) d.day: d};
    final sorted = byKey.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    var longest = 0;
    var run = 0;
    for (final d in sorted) {
      if (d.fardMet) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }

    DayKey? anchor;
    final todayDc = byKey[today];
    if (todayDc?.fardMet == true) {
      anchor = today;
    } else {
      final yesterday = today.previousDay();
      final yesterdayDc = byKey[yesterday];
      if (yesterdayDc?.fardMet == true) {
        anchor = yesterday;
      }
    }

    var current = 0;
    if (anchor != null) {
      var cursor = anchor;
      while (byKey[cursor]?.fardMet == true) {
        current += 1;
        cursor = cursor.previousDay();
      }
    }

    return Streak(
      current: current,
      longest: longest,
      windowDays: sorted.length,
    );
  }
}
