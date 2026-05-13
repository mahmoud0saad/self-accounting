import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';

void main() {
  test('resetDay deletes only the target date rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.seedAndReconcile();

    final repo = DriftChecklistRepository(db);
    final d11 = DayKey(year: 2026, month: 5, day: 11);
    final d12 = DayKey(year: 2026, month: 5, day: 12);

    await repo.setCompletion(
      day: d11,
      taskId: 'fajr_waking_up_adhkar',
      completed: true,
    );
    await repo.setCompletion(
      day: d11,
      taskId: 'fajr_sunnah_before_fajr',
      completed: true,
    );
    await repo.setCompletion(
      day: d11,
      taskId: 'fajr_first_congregation',
      completed: true,
    );

    await repo.setCompletion(
      day: d12,
      taskId: 'fajr_waking_up_adhkar',
      completed: true,
    );
    await repo.setCompletion(
      day: d12,
      taskId: 'fajr_sunnah_before_fajr',
      completed: true,
    );
    await repo.setCompletion(
      day: d12,
      taskId: 'fajr_first_congregation',
      completed: true,
    );

    await repo.resetDay(d12);

    final m11 = await repo.readDay(d11);
    final m12 = await repo.readDay(d12);

    expect(m11.length, 3);
    expect(m11['fajr_waking_up_adhkar'], isTrue);
    expect(m12, isEmpty);
  });
}
