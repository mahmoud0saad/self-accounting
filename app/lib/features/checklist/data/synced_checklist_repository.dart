import 'dart:async';

import '../../../core/time/day_key.dart';
import '../../sync/data/sync_service.dart';
import 'checklist_repository.dart';

class SyncedChecklistRepository implements ChecklistRepository {
  SyncedChecklistRepository(this._local, this._sync);

  final ChecklistRepository _local;
  final SyncService _sync;

  @override
  Future<Map<String, bool>> readDay(DayKey day) => _local.readDay(day);

  @override
  Future<void> setCompletion({
    required DayKey day,
    required String taskId,
    required bool completed,
  }) async {
    await _local.setCompletion(day: day, taskId: taskId, completed: completed);
    await _sync.enqueueLogUpsert(
      day: day,
      taskId: taskId,
      completed: completed,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> resetDay(DayKey day) => _local.resetDay(day);

  @override
  Stream<Map<String, bool>> watchDay(DayKey day) => _local.watchDay(day);
}
