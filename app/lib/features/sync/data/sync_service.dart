import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../../../core/time/day_key.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'sync_api.dart';

class SyncService {
  SyncService({
    required this.db,
    required this.api,
    required this.storage,
    required this.ref,
  });

  final AppDatabase db;
  final SyncApi api;
  final TokenStorage storage;
  final Ref ref;

  Future<void>? _inflight;
  bool _pending = false;

  bool get canSync {
    final auth = ref.read(authNotifierProvider);
    return auth.status == AuthStatus.authenticated &&
        auth.user != null &&
        auth.user!.isEmailConfirmed;
  }

  Future<void> enqueueLogOp({
    required String date,
    required String taskId,
    required bool completed,
    required DateTime clientUpdatedAt,
  }) async {
    final payload = jsonEncode({
      'date': date,
      'taskId': taskId,
      'completed': completed,
      'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
    });
    await db.into(db.pendingSyncOps).insert(
      PendingSyncOpsCompanion.insert(
        opType: 'batch_log',
        payloadJson: payload,
        clientUpdatedAt: clientUpdatedAt.toUtc(),
      ),
    );
  }

  Future<void> syncNow() async {
    if (!canSync) {
      return;
    }
    if (_inflight != null) {
      // Re-arm a trailing pass so ops enqueued during this run are not missed.
      _pending = true;
      return _inflight;
    }
    final future = _runSyncCycle();
    _inflight = future;
    try {
      await future;
    } finally {
      _inflight = null;
    }
  }

  Future<void> _runSyncCycle() async {
    do {
      _pending = false;
      await drainOutbound();
      await pullDeltas();
    } while (_pending);
  }

  Future<void> drainOutbound() async {
    if (!canSync) {
      return;
    }
    const batchSize = 100;
    while (true) {
      final ops = await (db.select(db.pendingSyncOps)
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(batchSize))
          .get();
      if (ops.isEmpty) {
        break;
      }
      final items = ops
          .map((o) => jsonDecode(o.payloadJson) as Map<String, dynamic>)
          .toList();
      try {
        await api.batchUpsert(items);
        final ids = ops.map((o) => o.id).toList();
        await (db.delete(db.pendingSyncOps)
              ..where((t) => t.id.isIn(ids)))
            .go();
      } on Object catch (e) {
        for (final op in ops) {
          await (db.update(db.pendingSyncOps)..where((t) => t.id.equals(op.id)))
              .write(
            PendingSyncOpsCompanion(
              attempts: Value(op.attempts + 1),
              lastError: Value(e.toString()),
            ),
          );
        }
        break;
      }
    }
  }

  Future<void> pullDeltas() async {
    if (!canSync) {
      return;
    }
    final userId = ref.read(authNotifierProvider).user!.id;
    final cursor =
        await storage.readSyncCursor(userId) ?? '2000-01-01';
    final today = DayKey.today().toIsoDate();
    final remote = await api.fetchLogs(from: cursor, to: today);
    for (final row in remote) {
      final date = row['date'] as String;
      final taskId = row['taskId'] as String;
      final completed = row['completed'] as bool;
      final remoteAt =
          DateTime.parse(row['updatedAt'] as String).toUtc();

      final local = await (db.select(db.dailyLogs)
            ..where((r) => r.date.equals(date) & r.taskId.equals(taskId)))
          .getSingleOrNull();
      if (local != null && local.updatedAt.isAfter(remoteAt)) {
        continue;
      }
      await db.into(db.dailyLogs).insertOnConflictUpdate(
        DailyLogsCompanion.insert(
          date: date,
          taskId: taskId,
          completed: Value(completed),
          updatedAt: Value(remoteAt),
        ),
      );
    }
    if (remote.isNotEmpty) {
      await storage.writeSyncCursor(userId, today);
    }
  }

  Future<int> runFirstSignInMigrationIfNeeded() async {
    if (!canSync) {
      return 0;
    }
    final userId = ref.read(authNotifierProvider).user!.id;
    if (await storage.isFirstSyncDone(userId)) {
      return 0;
    }

    await pullDeltas();

    final allLogs = await db.select(db.dailyLogs).get();
    for (final log in allLogs) {
      await enqueueLogOp(
        date: log.date,
        taskId: log.taskId,
        completed: log.completed,
        clientUpdatedAt: log.updatedAt.toUtc(),
      );
    }
    await drainOutbound();
    await storage.markFirstSyncDone(userId);

    final days = allLogs.map((l) => l.date).toSet().length;
    return days;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(syncApiProvider),
    storage: ref.read(tokenStorageProvider),
    ref: ref,
  );
});
