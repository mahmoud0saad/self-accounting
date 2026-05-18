import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/time/day_key.dart';
import '../../sync/data/sync_service.dart';

abstract class ChecklistRepository {
  Future<Map<String, bool>> readDay(DayKey day);

  Future<void> setCompletion({
    required DayKey day,
    required String taskId,
    required bool completed,
  });

  Future<void> resetDay(DayKey day);

  Stream<Map<String, bool>> watchDay(DayKey day);
}

class DriftChecklistRepository implements ChecklistRepository {
  DriftChecklistRepository(this._db, {SyncService? sync}) : _sync = sync;

  final AppDatabase _db;
  final SyncService? _sync;

  @override
  Future<Map<String, bool>> readDay(DayKey day) async {
    final rows = await (_db.select(
      _db.dailyLogs,
    )..where((r) => r.date.equals(day.toIsoDate()))).get();
    return {for (final r in rows) r.taskId: r.completed};
  }

  @override
  Future<void> setCompletion({
    required DayKey day,
    required String taskId,
    required bool completed,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.dailyLogs).insertOnConflictUpdate(
      DailyLogsCompanion.insert(
        date: day.toIsoDate(),
        taskId: taskId,
        completed: Value(completed),
        updatedAt: Value(now),
      ),
    );
    await _sync?.enqueueLogOp(
      date: day.toIsoDate(),
      taskId: taskId,
      completed: completed,
      clientUpdatedAt: now,
    );
    await _sync?.syncNow();
  }

  @override
  Future<void> resetDay(DayKey day) {
    return (_db.delete(
      _db.dailyLogs,
    )..where((r) => r.date.equals(day.toIsoDate()))).go();
  }

  @override
  Stream<Map<String, bool>> watchDay(DayKey day) {
    return (_db.select(_db.dailyLogs)
          ..where((r) => r.date.equals(day.toIsoDate())))
        .watch()
        .map((rows) => {for (final r in rows) r.taskId: r.completed});
  }
}
