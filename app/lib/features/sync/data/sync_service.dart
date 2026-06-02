import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../../../core/time/day_key.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'sync_api.dart';
import 'sync_constants.dart';
import 'sync_log_enqueue.dart';

class SyncService implements SyncLogEnqueue {
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
    String? taskId,
    String? userTaskId,
    required bool completed,
    required DateTime clientUpdatedAt,
  }) async {
    assert(
      (taskId != null) != (userTaskId != null),
      'Exactly one of taskId or userTaskId must be set',
    );
    final payload = <String, dynamic>{
      'date': date,
      'completed': completed,
      'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
    };
    if (userTaskId != null) {
      payload['userTaskId'] = userTaskId;
    } else {
      payload['taskId'] = taskId;
    }
    final payloadJson = jsonEncode(payload);
    await db.into(db.pendingSyncOps).insert(
      PendingSyncOpsCompanion.insert(
        opType: 'batch_log',
        payloadJson: payloadJson,
        clientUpdatedAt: clientUpdatedAt.toUtc(),
      ),
    );
  }

  Future<void> enqueueCustomizationOp({
    required String opType,
    required Map<String, dynamic> payload,
    required DateTime clientUpdatedAt,
  }) async {
    await _coalesceCustomizationOp(opType, payload, clientUpdatedAt);
  }

  Future<void> enqueueChallengeOp({
    required String opType,
    required Map<String, dynamic> payload,
    required DateTime clientUpdatedAt,
  }) async {
    await _coalesceChallengeOp(opType, payload, clientUpdatedAt);
  }

  Future<void> _coalesceChallengeOp(
    String opType,
    Map<String, dynamic> payload,
    DateTime clientUpdatedAt,
  ) async {
    final targetId = _challengeCoalesceKey(opType, payload);
    if (targetId != null) {
      final pending = await db.select(db.pendingSyncOps).get();
      for (final op in pending) {
        if (op.opType != opType) {
          continue;
        }
        final existing = jsonDecode(op.payloadJson) as Map<String, dynamic>;
        if (_challengeCoalesceKey(opType, existing) == targetId) {
          await (db.delete(db.pendingSyncOps)..where((t) => t.id.equals(op.id)))
              .go();
        }
      }
    }
    await db.into(db.pendingSyncOps).insert(
      PendingSyncOpsCompanion.insert(
        opType: opType,
        payloadJson: jsonEncode(payload),
        clientUpdatedAt: clientUpdatedAt.toUtc(),
      ),
    );
  }

  String? _challengeCoalesceKey(String opType, Map<String, dynamic> payload) {
    return switch (opType) {
      'upsert_user_challenge' || 'delete_user_challenge' => payload['id'] as String?,
      'upsert_user_challenge_week' =>
        '${payload['userChallengeId']}:${payload['weekStart']}',
      _ => null,
    };
  }

  Future<void> _coalesceCustomizationOp(
    String opType,
    Map<String, dynamic> payload,
    DateTime clientUpdatedAt,
  ) async {
    final entityId = _customizationEntityId(opType, payload);
    if (entityId != null) {
      final pending = await db.select(db.pendingSyncOps).get();
      for (final op in pending) {
        if (op.opType != opType) {
          continue;
        }
        final existing = jsonDecode(op.payloadJson) as Map<String, dynamic>;
        if (_customizationEntityId(opType, existing) == entityId) {
          await (db.delete(db.pendingSyncOps)
                ..where((t) => t.id.equals(op.id)))
              .go();
        }
      }
    }
    await db.into(db.pendingSyncOps).insert(
      PendingSyncOpsCompanion.insert(
        opType: opType,
        payloadJson: jsonEncode(payload),
        clientUpdatedAt: clientUpdatedAt.toUtc(),
      ),
    );
  }

  String? _customizationEntityId(
    String opType,
    Map<String, dynamic> payload,
  ) {
    return switch (opType) {
      'upsert_user_category_override' => payload['categoryCode'] as String?,
      'upsert_user_task_override' => payload['taskCode'] as String?,
      'update_user_category' || 'delete_user_category' => payload['id'] as String?,
      'update_user_task' || 'delete_user_task' => payload['id'] as String?,
      _ => null,
    };
  }

  Future<void> syncNow() async {
    if (!canSync) {
      return;
    }
    if (_inflight != null) {
      // Re-arm a trailing pass so ops enqueued during this run are not missed.
      _pending = true;
      await _inflight;
      if (_pending) {
        _pending = false;
        await syncNow();
      }
      return;
    }
    await _runExclusive(_runSyncCycle);
  }

  /// Waits until no sync operation is in flight, then runs a trailing cycle if
  /// one was re-armed during the wait.
  Future<void> waitForIdle() async {
    while (_inflight != null) {
      await _inflight;
    }
    if (_pending) {
      await syncNow();
    }
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) async {
    while (_inflight != null) {
      await _inflight;
    }
    late final Future<T> work;
    work = action();
    _inflight = work.then((_) {}, onError: (_) {});
    try {
      return await work;
    } finally {
      _inflight = null;
    }
  }

  Future<void> _runSyncCycle() async {
    do {
      _pending = false;
      await _drainOutbound();
      await _pullDeltas();
    } while (_pending);
  }

  Future<void> drainOutbound() =>
      _runExclusive(_drainOutbound);

  Future<void> pullDeltas() => _runExclusive(_pullDeltas);

  Future<void> _drainOutbound() async {
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
      final logItems = <Map<String, dynamic>>[];
      final customizationOps = <Map<String, dynamic>>[];
      final challengeOps = <Map<String, dynamic>>[];
      for (final o in ops) {
        if (o.opType == 'batch_log') {
          logItems.add(jsonDecode(o.payloadJson) as Map<String, dynamic>);
        } else if (isChallengeOpType(o.opType)) {
          challengeOps.add({
            'opId': '${o.id}',
            'opType': o.opType,
            'payload': jsonDecode(o.payloadJson),
            'clientUpdatedAt': o.clientUpdatedAt.toUtc().toIso8601String(),
          });
        } else {
          customizationOps.add({
            'opId': '${o.id}',
            'opType': o.opType,
            'payload': jsonDecode(o.payloadJson),
            'clientUpdatedAt': o.clientUpdatedAt.toUtc().toIso8601String(),
          });
        }
      }
      try {
        final appliedOpIds = <String>{};
        if (customizationOps.isNotEmpty) {
          final outcomes = await api.batchCustomizations(customizationOps);
          for (final outcome in outcomes) {
            if (outcome['applied'] == true) {
              appliedOpIds.add(outcome['opId'] as String);
            }
          }
        }
        if (challengeOps.isNotEmpty) {
          final outcomes = await api.batchChallenges(challengeOps);
          for (final outcome in outcomes) {
            if (outcome['applied'] == true) {
              appliedOpIds.add(outcome['opId'] as String);
            }
          }
        }
        if (logItems.isNotEmpty) {
          await api.batchUpsert(logItems);
        }
        final batchOpIds = {...customizationOps, ...challengeOps}
            .map((o) => o['opId'] as String)
            .toSet();
        if (batchOpIds.isNotEmpty || logItems.isNotEmpty) {
          final idsToDelete = ops
              .where(
                (o) =>
                    o.opType == 'batch_log' ||
                    !batchOpIds.contains('${o.id}') ||
                    appliedOpIds.contains('${o.id}'),
              )
              .map((o) => o.id)
              .toList();
          if (idsToDelete.isNotEmpty) {
            await (db.delete(db.pendingSyncOps)
                  ..where((t) => t.id.isIn(idsToDelete)))
                .go();
          }
        } else if (logItems.isEmpty) {
          final ids = ops.map((o) => o.id).toList();
          await (db.delete(db.pendingSyncOps)
                ..where((t) => t.id.isIn(ids)))
              .go();
        }
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

  Future<void> _pullDeltas() async {
    if (!canSync) {
      return;
    }
    final userId = ref.read(authNotifierProvider).user!.id;
    final cursor =
        await storage.readSyncCursor(userId) ?? '2000-01-01';
    final today = DayKey.today().toIsoDate();
    final remote = await api.fetchLogs(from: cursor, to: today);
    final localUserTaskIds = (await db.select(db.userTasks).get())
        .map((t) => t.id)
        .toSet();
    final localTaskIds =
        (await db.select(db.tasks).get()).map((t) => t.id).toSet();
    var skippedOrphans = false;

    for (final row in remote) {
      final date = row['date'] as String;
      final taskId = row['taskId'] as String?;
      final userTaskId = row['userTaskId'] as String?;
      final completed = row['completed'] as bool;
      final remoteAt =
          DateTime.parse(row['updatedAt'] as String).toUtc();

      if (userTaskId != null && !localUserTaskIds.contains(userTaskId)) {
        skippedOrphans = true;
        continue;
      }
      if (taskId != null && !localTaskIds.contains(taskId)) {
        skippedOrphans = true;
        continue;
      }
      if (userTaskId == null && taskId == null) {
        continue;
      }

      final local = await (db.select(db.dailyLogs)
            ..where((r) {
              final dateMatch = r.date.equals(date);
              if (userTaskId != null) {
                return dateMatch & r.userTaskId.equals(userTaskId);
              }
              if (taskId != null) {
                return dateMatch & r.taskId.equals(taskId);
              }
              return dateMatch;
            }))
          .getSingleOrNull();
      if (local != null && local.updatedAt.isAfter(remoteAt)) {
        continue;
      }
      if (local != null) {
        await (db.update(db.dailyLogs)..where((r) => r.id.equals(local.id)))
            .write(
          DailyLogsCompanion(
            completed: Value(completed),
            updatedAt: Value(remoteAt),
          ),
        );
      } else {
        await db.into(db.dailyLogs).insert(
          DailyLogsCompanion.insert(
            date: date,
            taskId: userTaskId != null
                ? const Value.absent()
                : Value(taskId),
            userTaskId: userTaskId != null
                ? Value(userTaskId)
                : const Value.absent(),
            completed: Value(completed),
            updatedAt: Value(remoteAt),
          ),
        );
      }
    }
    if (!skippedOrphans) {
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

    return _runExclusive(() async {
      await _pullDeltas();

      final allLogs = await db.select(db.dailyLogs).get();
      for (final log in allLogs) {
        if (log.userTaskId != null) {
          await enqueueLogOp(
            date: log.date,
            userTaskId: log.userTaskId,
            completed: log.completed,
            clientUpdatedAt: log.updatedAt.toUtc(),
          );
          continue;
        }
        final taskId = log.taskId;
        if (taskId == null) {
          continue;
        }
        await enqueueLogOp(
          date: log.date,
          taskId: taskId,
          completed: log.completed,
          clientUpdatedAt: log.updatedAt.toUtc(),
        );
      }
      await _drainOutbound();
      await storage.markFirstSyncDone(userId);

      final today = DayKey.today().toIsoDate();
      await storage.writeSyncCursor(userId, today);

      return allLogs.map((l) => l.date).toSet().length;
    });
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
