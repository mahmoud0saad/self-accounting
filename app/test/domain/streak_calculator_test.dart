import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/domain/day_completion.dart';
import 'package:app/features/checklist/domain/streak_calculator.dart';

void main() {
  const calc = StreakCalculator();
  final today = DayKey(year: 2026, month: 5, day: 13);

  DayCompletion dc(DayKey day, {required bool fardMet, double fraction = 0.5}) {
    const totalPoints = 74;
    final completedPoints = (totalPoints * fraction).round();
    return DayCompletion(
      day: day,
      completedPoints: completedPoints,
      totalPoints: totalPoints,
      completedTasks: (completedPoints / 2).round(),
      totalTasks: 34,
      fardMet: fardMet,
    );
  }

  test('empty window → 0/0', () {
    final r = calc.compute(const [], today: today);
    expect(r.current, 0);
    expect(r.longest, 0);
    expect(r.windowDays, 0);
  });

  test('3 fard-met days ending today → current=3, longest=3', () {
    final days = [
      dc(today.previousDay().previousDay(), fardMet: true),
      dc(today.previousDay(), fardMet: true),
      dc(today, fardMet: true),
    ];
    final r = calc.compute(days, today: today);
    expect(r.current, 3);
    expect(r.longest, 3);
  });

  test(
    '5 fard-met days ending yesterday + empty today → grace gives current=5',
    () {
      var cursor = today.previousDay();
      final days = <DayCompletion>[];
      for (var i = 0; i < 5; i++) {
        days.add(dc(cursor, fardMet: true));
        cursor = cursor.previousDay();
      }
      days.add(dc(today, fardMet: false, fraction: 0.0));
      final r = calc.compute(days, today: today);
      expect(r.current, 5);
      expect(r.longest, 5);
    },
  );

  test('2 fard, 1 gap, then 4 fard ending today → current=4, longest=4', () {
    final d6 = today
        .previousDay()
        .previousDay()
        .previousDay()
        .previousDay()
        .previousDay()
        .previousDay(); // today - 6
    final d5 = d6.nextDay();
    final d4 = d5.nextDay();
    final d3 = d4.nextDay();
    final d2 = d3.nextDay();
    final d1 = d2.nextDay();
    final days = [
      dc(d6, fardMet: true),
      dc(d5, fardMet: true),
      dc(d4, fardMet: false, fraction: 0.5),
      dc(d3, fardMet: true),
      dc(d2, fardMet: true),
      dc(d1, fardMet: true),
      dc(today, fardMet: true),
    ];
    final r = calc.compute(days, today: today);
    expect(r.current, 4);
    expect(r.longest, 4);
  });

  test(
    '7 fard days but NOT today and NOT yesterday → current=0, longest=7',
    () {
      var cursor = today.previousDay().previousDay(); // today - 2
      final days = <DayCompletion>[];
      for (var i = 0; i < 7; i++) {
        days.add(dc(cursor, fardMet: true));
        cursor = cursor.previousDay();
      }
      days.add(dc(today.previousDay(), fardMet: false, fraction: 0.3));
      days.add(dc(today, fardMet: false, fraction: 0.0));
      final r = calc.compute(days, today: today);
      expect(r.current, 0);
      expect(r.longest, 7);
    },
  );

  test('partial completion (75% but no fard) does not advance streak', () {
    final days = [
      dc(today.previousDay(), fardMet: false, fraction: 0.78),
      dc(today, fardMet: false, fraction: 0.78),
    ];
    final r = calc.compute(days, today: today);
    expect(r.current, 0);
    expect(r.longest, 0);
  });
}
