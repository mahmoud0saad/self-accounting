import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/challenges/domain/week_boundary.dart';

void main() {
  test('weekStartFor defaults to Saturday when storage is null', () {
    expect(weekStartDowFromStorage(null), WeekStartDow.sat);
    expect(weekStartDowToStorage(WeekStartDow.sat), 'sat');
  });

  test('weekStartFor Saturday anchors on 2026-05-19 (Tuesday)', () {
    final tuesday = DateTime(2026, 5, 19);
    final start = weekStartFor(tuesday, WeekStartDow.sat);
    expect(isoDate(start), '2026-05-16');
    expect(isoDate(weekEndFor(start)), '2026-05-22');
  });

  test('datesInWeek returns seven distinct ISO dates', () {
    final start = DateTime(2026, 5, 16);
    final end = weekEndFor(start);
    final dates = datesInWeek(start, end);
    expect(dates.length, 7);
    expect(dates.toSet().length, 7);
  });
}
