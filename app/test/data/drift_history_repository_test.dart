import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';
import 'package:app/features/checklist/data/drift_history_repository.dart';

void main() {
  test(
    'readRange covers every calendar day inclusively and summarizes per day',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.seedAndReconcile();
      final checklist = DriftChecklistRepository(db);
      final history = DriftHistoryRepository(db);

      // 2026-05-08 — full fard set + 2 non-fard rows.
      const fullFardDay = DayKey(year: 2026, month: 5, day: 8);
      const fardIds = <String>[
        'fajr_first_congregation',
        'dhuhr_first_congregation',
        'asr_first_congregation',
        'maghrib_first_congregation',
        'isha_first_congregation',
        'quran_read_six_quarters',
      ];
      for (final id in fardIds) {
        await checklist.setCompletion(
          day: fullFardDay,
          taskId: id,
          completed: true,
        );
      }
      await checklist.setCompletion(
        day: fullFardDay,
        taskId: 'fajr_waking_up_adhkar',
        completed: true,
      );
      await checklist.setCompletion(
        day: fullFardDay,
        taskId: 'fajr_morning_adhkar',
        completed: true,
      );

      // 2026-05-10 — only 3 fard ids (set incomplete).
      const partialFardDay = DayKey(year: 2026, month: 5, day: 10);
      for (final id in fardIds.take(3)) {
        await checklist.setCompletion(
          day: partialFardDay,
          taskId: id,
          completed: true,
        );
      }

      // 2026-05-12 — only non-fard rows.
      const nonFardDay = DayKey(year: 2026, month: 5, day: 12);
      await checklist.setCompletion(
        day: nonFardDay,
        taskId: 'misc_clothing_adhkar',
        completed: true,
      );
      await checklist.setCompletion(
        day: nonFardDay,
        taskId: 'misc_wudu_adhkar',
        completed: true,
      );
      await checklist.setCompletion(
        day: nonFardDay,
        taskId: 'misc_house_adhkar',
        completed: true,
      );
      await checklist.setCompletion(
        day: nonFardDay,
        taskId: 'misc_mosque_adhkar',
        completed: true,
      );

      final start = DayKey(year: 2026, month: 5, day: 7);
      final end = DayKey(year: 2026, month: 5, day: 13);
      final range = await history.readRange(start, end);

      expect(range.length, 7);
      expect(range.map((d) => d.day.toIsoDate()).toList(), const [
        '2026-05-07',
        '2026-05-08',
        '2026-05-09',
        '2026-05-10',
        '2026-05-11',
        '2026-05-12',
        '2026-05-13',
      ]);

      final byIso = {for (final d in range) d.day.toIsoDate(): d};

      // Untouched days → 0 / false.
      for (final iso in const [
        '2026-05-07',
        '2026-05-09',
        '2026-05-11',
        '2026-05-13',
      ]) {
        final dc = byIso[iso]!;
        expect(dc.completedPoints, 0, reason: '$iso completedPoints');
        expect(dc.completedTasks, 0, reason: '$iso completedTasks');
        expect(dc.fardMet, isFalse, reason: '$iso fardMet');
        expect(dc.totalPoints, 74);
        expect(dc.totalTasks, 34);
      }

      // 2026-05-08 — 6 fard (12 pts) + 2 non-fard (4 pts) = 16 pts, fard met.
      final d8 = byIso['2026-05-08']!;
      expect(d8.completedPoints, 16);
      expect(d8.completedTasks, 8);
      expect(d8.fardMet, isTrue);

      // 2026-05-10 — 3 fard ids only, set incomplete → fardMet false.
      final d10 = byIso['2026-05-10']!;
      expect(d10.completedPoints, 6);
      expect(d10.completedTasks, 3);
      expect(d10.fardMet, isFalse);

      // 2026-05-12 — 4 non-fard rows, fardMet false.
      final d12 = byIso['2026-05-12']!;
      expect(d12.completedPoints, 8);
      expect(d12.completedTasks, 4);
      expect(d12.fardMet, isFalse);

      await db.close();
    },
  );

  test('watchRange re-emits when a row in the range is inserted', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.seedAndReconcile();
    final checklist = DriftChecklistRepository(db);
    final history = DriftHistoryRepository(db);

    final start = DayKey(year: 2026, month: 5, day: 7);
    final end = DayKey(year: 2026, month: 5, day: 13);

    final stream = history.watchRange(start, end);
    final emissions = <int>[];
    final sub = stream.listen(
      (list) =>
          emissions.add(list.fold<int>(0, (s, d) => s + d.completedTasks)),
    );

    // Let the initial emission flush.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final initial = emissions.length;
    expect(initial, greaterThanOrEqualTo(1));
    expect(emissions.last, 0);

    await checklist.setCompletion(
      day: DayKey(year: 2026, month: 5, day: 9),
      taskId: 'fajr_first_congregation',
      completed: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, greaterThan(initial));
    expect(emissions.last, 1);

    await sub.cancel();
    await db.close();
  });
}
