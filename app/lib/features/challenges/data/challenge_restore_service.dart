import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../sync/data/sync_api.dart';
import '../../sync/data/sync_constants.dart';
import '../../sync/data/sync_service.dart';
import 'challenge_repository.dart';

enum ChallengeRestoreState {
  idle,
  checking,
  pushing,
  restoring,
  done,
  cancelledByUser,
  error,
}

class ChallengeRestoreEvent {
  const ChallengeRestoreEvent({
    required this.state,
    this.restoredCount = 0,
    this.message,
  });

  final ChallengeRestoreState state;
  final int restoredCount;
  final String? message;
}

class ChallengeRestoreService {
  ChallengeRestoreService({
    required this.db,
    required this.api,
    required this.storage,
    required this.repo,
    required this.ref,
    required this.drainOutbound,
  });

  final AppDatabase db;
  final SyncApi api;
  final TokenStorage storage;
  final ChallengeRepository repo;
  final Ref ref;
  final Future<void> Function() drainOutbound;

  final _events = StreamController<ChallengeRestoreEvent>.broadcast();

  Stream<ChallengeRestoreEvent> get events => _events.stream;

  bool get _canRun {
    final auth = ref.read(authNotifierProvider);
    return auth.status == AuthStatus.authenticated &&
        auth.user != null &&
        auth.user!.isEmailConfirmed;
  }

  Future<void> restoreIfNeeded({
    bool force = false,
    Future<bool> Function(int totalItems)? confirmReplacePrompt,
  }) async {
    if (!_canRun) {
      _emit(const ChallengeRestoreEvent(state: ChallengeRestoreState.idle));
      return;
    }
    final userId = ref.read(authNotifierProvider).user!.id;
    if (!force && await storage.isChallengeFirstSyncDone(userId)) {
      _emit(const ChallengeRestoreEvent(state: ChallengeRestoreState.idle));
      return;
    }

    try {
      _emit(
        const ChallengeRestoreEvent(state: ChallengeRestoreState.checking),
      );
      final snapshot = await api.fetchChallengeSnapshotState();
      final hasSnapshot = snapshot['hasSnapshot'] as bool? ?? false;
      final totals = snapshot['totals'] as Map<String, dynamic>? ?? {};
      final totalItems = (totals['userChallenges'] as int? ?? 0) +
          (totals['userChallengeWeeks'] as int? ?? 0);

      if (hasSnapshot) {
        final ok = confirmReplacePrompt == null
            ? true
            : await confirmReplacePrompt(totalItems);
        if (!ok) {
          await storage.markChallengeFirstSyncDone(userId);
          _emit(
            const ChallengeRestoreEvent(
              state: ChallengeRestoreState.cancelledByUser,
            ),
          );
          return;
        }
        _emit(
          const ChallengeRestoreEvent(
            state: ChallengeRestoreState.restoring,
          ),
        );
        await db.transaction(() async {
          final pending = await db.select(db.pendingSyncOps).get();
          for (final op in pending) {
            if (isChallengeOpType(op.opType)) {
              await (db.delete(db.pendingSyncOps)
                    ..where((t) => t.id.equals(op.id)))
                  .go();
            }
          }
          await db.delete(db.userChallengeWeeks).go();
          await db.delete(db.userChallenges).go();
        });
        final remote = await api.fetchChallenges();
        await repo.replaceAllFromServer(remote);
        await storage.markChallengeFirstSyncDone(userId);
        _emit(
          ChallengeRestoreEvent(
            state: ChallengeRestoreState.done,
            restoredCount: remote.length,
          ),
        );
        return;
      }

      _emit(
        const ChallengeRestoreEvent(state: ChallengeRestoreState.pushing),
      );
      final challenges = await db.select(db.userChallenges).get();
      final weeks = await db.select(db.userChallengeWeeks).get();
      final sync = ref.read(syncServiceProvider);
      final now = DateTime.now().toUtc();
      for (final c in challenges) {
        await sync.enqueueChallengeOp(
          opType: 'upsert_user_challenge',
          payload: {
            'id': c.id,
            if (c.templateCode != null) 'templateCode': c.templateCode,
            if (c.customTitle != null) 'customTitle': c.customTitle,
            if (c.customIcon != null) 'customIcon': c.customIcon,
            if (c.customSourceKind != null)
              'customSourceKind': c.customSourceKind,
            if (c.customSourceRef != null) 'customSourceRef': c.customSourceRef,
            if (c.customGoalCount != null) 'customGoalCount': c.customGoalCount,
            if (c.archivedAt != null)
              'archivedAt': c.archivedAt!.toUtc().toIso8601String(),
          },
          clientUpdatedAt: c.updatedAt,
        );
      }
      for (final w in weeks) {
        await sync.enqueueChallengeOp(
          opType: 'upsert_user_challenge_week',
          payload: {
            'id': w.id,
            'userChallengeId': w.userChallengeId,
            'weekStart': w.weekStart,
            'weekEnd': w.weekEnd,
            'goalCount': w.goalCount,
            'achievedCount': w.achievedCount,
            'status': w.status,
            if (w.completedAt != null)
              'completedAt': w.completedAt!.toUtc().toIso8601String(),
            if (w.celebrationSeenAt != null)
              'celebrationSeenAt':
                  w.celebrationSeenAt!.toUtc().toIso8601String(),
          },
          clientUpdatedAt: w.updatedAt,
        );
      }
      await drainOutbound();
      await storage.markChallengeFirstSyncDone(userId);
      _emit(
        ChallengeRestoreEvent(
          state: ChallengeRestoreState.done,
          restoredCount: challenges.length + weeks.length,
        ),
      );
    } on Object catch (e) {
      _emit(
        ChallengeRestoreEvent(
          state: ChallengeRestoreState.error,
          message: e.toString(),
        ),
      );
    }
  }

  void _emit(ChallengeRestoreEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  void dispose() {
    _events.close();
  }
}

final challengeRestoreServiceProvider = Provider<ChallengeRestoreService>((ref) {
  final service = ChallengeRestoreService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(syncApiProvider),
    storage: ref.read(tokenStorageProvider),
    repo: ref.watch(challengeRepositoryProvider),
    ref: ref,
    drainOutbound: () => ref.read(syncServiceProvider).drainOutbound(),
  );
  ref.onDispose(service.dispose);
  return service;
});
