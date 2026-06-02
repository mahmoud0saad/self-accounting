/// Minimal surface for enqueueing daily-log sync ops (catalog or user-owned tasks).
abstract class SyncLogEnqueue {
  Future<void> enqueueLogOp({
    required String date,
    String? taskId,
    String? userTaskId,
    required bool completed,
    required DateTime clientUpdatedAt,
  });
}
