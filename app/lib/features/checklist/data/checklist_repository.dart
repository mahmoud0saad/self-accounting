import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/time/day_key.dart';
import '../../sync/data/sync_service.dart';

/// Fast-path hint for locally created ids; not sufficient on its own after sync.
bool isUserOwnedTaskLogId(String taskId) => taskId.startsWith('ut_');

/// Resolves whether [taskId] belongs to [UserTasks], including server-restored ids.
Future<bool> resolveIsUserOwnedTask(AppDatabase db, String taskId) async {
  if (isUserOwnedTaskLogId(taskId)) {
    return true;
  }
  final row = await (db.select(db.userTasks)
        ..where((r) => r.id.equals(taskId)))
      .getSingleOrNull();
  return row != null;
}

String effectiveTaskIdFromLog(DbDailyLog row) =>
    row.userTaskId ?? row.taskId!;

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
    return {
      for (final r in rows)
        if (r.userTaskId != null || r.taskId != null)
          effectiveTaskIdFromLog(r): r.completed,
    };
  }

  @override
  Future<void> setCompletion({
    required DayKey day,
    required String taskId,
    required bool completed,
  }) async {
    final now = DateTime.now().toUtc();
    final dateIso = day.toIsoDate();
    final isUserTask = await resolveIsUserOwnedTask(_db, taskId);
    await _db.transaction(() async {
      await _upsertDailyLog(
        dateIso: dateIso,
        taskId: taskId,
        isUserTask: isUserTask,
        completed: completed,
        updatedAt: now,
      );
      if (!isUserTask) {
        await _sync?.enqueueLogOp(
          date: dateIso,
          taskId: taskId,
          completed: completed,
          clientUpdatedAt: now,
        );
      }
    });
  }

  Future<void> _upsertDailyLog({
    required String dateIso,
    required String taskId,
    required bool isUserTask,
    required bool completed,
    required DateTime updatedAt,
  }) async {
    final existing = await (_db.select(_db.dailyLogs)
          ..where((r) {
            final dateMatch = r.date.equals(dateIso);
            if (isUserTask) {
              return dateMatch & r.userTaskId.equals(taskId);
            }
            return dateMatch & r.taskId.equals(taskId);
          }))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.dailyLogs)..where((r) => r.id.equals(existing.id)))
          .write(
        DailyLogsCompanion(
          completed: Value(completed),
          updatedAt: Value(updatedAt),
        ),
      );
      return;
    }

    await _db.into(_db.dailyLogs).insert(
          DailyLogsCompanion.insert(
            date: dateIso,
            taskId: isUserTask ? const Value.absent() : Value(taskId),
            userTaskId: isUserTask ? Value(taskId) : const Value.absent(),
            completed: Value(completed),
            updatedAt: Value(updatedAt),
          ),
        );
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
        .map(
          (rows) => {
            for (final r in rows)
              if (r.userTaskId != null || r.taskId != null)
                effectiveTaskIdFromLog(r): r.completed,
          },
        );
  }
}
