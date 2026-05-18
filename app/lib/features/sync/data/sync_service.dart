import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/time/day_key.dart';
import '../../checklist/data/remote_log_repository.dart';

class SyncService {
  SyncService({
    required this.db,
    required this.logs,
    required this.isSignedIn,
  });

  final AppDatabase db;
  final RemoteLogRepository logs;
  final bool Function() isSignedIn;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushing = false;

  void start() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((_) {
      unawaited(flush());
    });
    unawaited(flush());
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> enqueueLogUpsert({
    required DayKey day,
    required String taskId,
    required bool completed,
    required DateTime updatedAt,
  }) async {
    if (!isSignedIn()) {
      return;
    }

    final payload = jsonEncode({
      'date': day.toIsoDate(),
      'taskId': taskId,
      'completed': completed,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    });

    await db.into(db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entity: 'log',
        entityId: '${day.toIsoDate()}:$taskId',
        action: 'upsert',
        payload: payload,
      ),
    );

    await flush();
  }

  Future<void> flush() async {
    if (_flushing || !isSignedIn()) {
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return;
    }

    _flushing = true;
    try {
      final pending = await (db.select(db.syncQueue)
            ..where((q) => q.synced.equals(false))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

      for (final entry in pending) {
        if (entry.entity == 'log' && entry.action == 'upsert') {
          final map = jsonDecode(entry.payload) as Map<String, dynamic>;
          await logs.upsert(
            day: DayKey.parseIso(map['date'] as String),
            taskId: map['taskId'] as String,
            completed: map['completed'] as bool,
            updatedAt: DateTime.parse(map['updatedAt'] as String).toUtc(),
          );
        }
        await (db.update(db.syncQueue)..where((q) => q.id.equals(entry.id)))
            .write(SyncQueueCompanion(synced: const Value(true)));
      }
    } catch (_) {
      // Leave entries unsynced for a later retry.
    } finally {
      _flushing = false;
    }
  }
}
