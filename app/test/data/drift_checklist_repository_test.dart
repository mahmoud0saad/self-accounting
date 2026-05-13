import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';

void main() {
  test('Fajr completions persist across database close and reopen', () async {
    final dir = await Directory.systemTemp.createTemp('checklist_persist_');
    final file = File('${dir.path}/muhasabah_test.sqlite');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Windows may briefly hold handles; temp cleanup is best-effort.
      }
    });

    final day = DayKey(year: 2026, month: 5, day: 13);

    var db = AppDatabase(NativeDatabase(file));
    await db.seedAndReconcile();
    var repo = DriftChecklistRepository(db);
    await repo.setCompletion(
      day: day,
      taskId: 'fajr_waking_up_adhkar',
      completed: true,
    );
    expect(await repo.readDay(day), {'fajr_waking_up_adhkar': true});
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    repo = DriftChecklistRepository(db);
    expect(await repo.readDay(day), {'fajr_waking_up_adhkar': true});
    await db.close();
  });

  test('non-active calendar day persists across reopen (picker day)', () async {
    final dir = await Directory.systemTemp.createTemp('checklist_persist_day_');
    final file = File('${dir.path}/muhasabah_test.sqlite');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Best-effort cleanup on Windows.
      }
    });

    final pickedDay = DayKey(year: 2026, month: 5, day: 12);
    final otherDay = DayKey(year: 2026, month: 5, day: 13);

    var db = AppDatabase(NativeDatabase(file));
    await db.seedAndReconcile();
    var repo = DriftChecklistRepository(db);
    await repo.setCompletion(
      day: pickedDay,
      taskId: 'fajr_first_congregation',
      completed: true,
    );
    expect(await repo.readDay(pickedDay), {'fajr_first_congregation': true});
    expect(await repo.readDay(otherDay), isEmpty);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    repo = DriftChecklistRepository(db);
    expect(await repo.readDay(pickedDay), {'fajr_first_congregation': true});
    expect(await repo.readDay(otherDay), isEmpty);
    await db.close();
  });

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
