import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../../sync/data/sync_service.dart';
import '../domain/challenge_models.dart';

final _random = Random();

String _newLocalId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x7fffffff)}';

class ChallengeRepository {
  ChallengeRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Stream<List<ChallengeTemplate>> watchTemplates() {
    return (_db.select(_db.challengeTemplates)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.defaultSortOrder)]))
        .watch()
        .map((rows) => rows.map(_mapTemplate).toList());
  }

  Future<List<ChallengeTemplate>> listTemplates() async {
    final rows = await (_db.select(_db.challengeTemplates)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.defaultSortOrder)]))
        .get();
    return rows.map(_mapTemplate).toList();
  }

  Stream<List<UserChallenge>> watchActiveChallenges() {
    return (_db.select(_db.userChallenges)
          ..where((c) => c.archivedAt.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.startedAt)]))
        .watch()
        .asyncMap((rows) async => _hydrateChallenges(rows));
  }

  Future<UserChallenge?> getChallenge(String id) async {
    final row = await (_db.select(_db.userChallenges)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final list = await _hydrateChallenges([row]);
    return list.isEmpty ? null : list.first;
  }

  Future<UserChallenge> subscribeToTemplate(String templateCode) async {
    final existing = await (_db.select(_db.userChallenges)
          ..where(
            (c) =>
                c.templateCode.equals(templateCode) & c.archivedAt.isNull(),
          ))
        .getSingleOrNull();
    if (existing != null) {
      throw StateError('Already subscribed');
    }
    final id = _newLocalId('uch');
    final now = DateTime.now().toUtc();
    await _db.into(_db.userChallenges).insert(
          UserChallengesCompanion.insert(
            id: id,
            templateCode: Value(templateCode),
            startedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await _enqueueChallenge('upsert_user_challenge', {
      'id': id,
      'templateCode': templateCode,
      'archivedAt': null,
    }, now);
    final c = await getChallenge(id);
    return c!;
  }

  Future<UserChallenge> createCustom({
    required String title,
    required String icon,
    required String sourceKind,
    required String sourceRef,
    required int goalCount,
  }) async {
    final id = _newLocalId('uch');
    final now = DateTime.now().toUtc();
    await _db.into(_db.userChallenges).insert(
          UserChallengesCompanion.insert(
            id: id,
            customTitle: Value(title.trim()),
            customIcon: Value(icon),
            customSourceKind: Value(sourceKind),
            customSourceRef: Value(sourceRef),
            customGoalCount: Value(goalCount),
            startedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await _enqueueChallenge('upsert_user_challenge', {
      'id': id,
      'customTitle': title.trim(),
      'customIcon': icon,
      'customSourceKind': sourceKind,
      'customSourceRef': sourceRef,
      'customGoalCount': goalCount,
    }, now);
    final c = await getChallenge(id);
    return c!;
  }

  Future<void> setArchived(String challengeId, {required bool archived}) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.userChallenges)..where((c) => c.id.equals(challengeId)))
        .write(
      UserChallengesCompanion(
        archivedAt: Value(archived ? now : null),
        updatedAt: Value(now),
      ),
    );
    if (archived) {
      await (_db.update(_db.userChallengeWeeks)
            ..where(
              (w) =>
                  w.userChallengeId.equals(challengeId) &
                  w.status.isIn(['IN_PROGRESS', 'COMPLETED']),
            ))
          .write(
        UserChallengeWeeksCompanion(
          status: const Value('CANCELLED'),
          updatedAt: Value(now),
        ),
      );
    }
    await _enqueueChallenge('upsert_user_challenge', {
      'id': challengeId,
      'archivedAt': archived ? now.toUtc().toIso8601String() : null,
    }, now);
  }

  Future<ChallengeWeek?> getWeek(String challengeId, String weekStart) async {
    final row = await (_db.select(_db.userChallengeWeeks)
          ..where(
            (w) =>
                w.userChallengeId.equals(challengeId) &
                w.weekStart.equals(weekStart),
          ))
        .getSingleOrNull();
    return row == null ? null : _mapWeek(row);
  }

  Future<ChallengeWeek> upsertWeek({
    required String challengeId,
    required String weekStart,
    required String weekEnd,
    required int goalCount,
    required int achievedCount,
    required String status,
    DateTime? completedAt,
    DateTime? celebrationSeenAt,
    int? persistedAchievedFloor,
  }) async {
    final effectiveAchieved = persistedAchievedFloor != null
        ? achievedCount > persistedAchievedFloor
            ? achievedCount
            : persistedAchievedFloor
        : achievedCount;

    final effectiveStatus =
        effectiveAchieved >= goalCount ? 'COMPLETED' : status;

    final now = DateTime.now().toUtc();
    final existing = await getWeek(challengeId, weekStart);
    final id = existing?.id ?? _newLocalId('ucw');
    final completed =
        effectiveStatus == 'COMPLETED' ? (completedAt ?? now) : null;

    await _db.into(_db.userChallengeWeeks).insertOnConflictUpdate(
          UserChallengeWeeksCompanion(
            id: Value(id),
            userChallengeId: Value(challengeId),
            weekStart: Value(weekStart),
            weekEnd: Value(weekEnd),
            goalCount: Value(goalCount),
            achievedCount: Value(effectiveAchieved),
            status: Value(effectiveStatus),
            completedAt: Value(completed),
            celebrationSeenAt: Value(
              celebrationSeenAt ?? existing?.celebrationSeenAt,
            ),
            updatedAt: Value(now),
          ),
        );

    await _enqueueChallenge('upsert_user_challenge_week', {
      'id': id,
      'userChallengeId': challengeId,
      'weekStart': weekStart,
      'weekEnd': weekEnd,
      'goalCount': goalCount,
      'achievedCount': effectiveAchieved,
      'status': effectiveStatus,
      if (completed != null) 'completedAt': completed.toUtc().toIso8601String(),
      if (celebrationSeenAt != null)
        'celebrationSeenAt': celebrationSeenAt.toUtc().toIso8601String(),
    }, now);

    return (await getWeek(challengeId, weekStart))!;
  }

  Future<void> markCelebrationSeen(String challengeId, String weekStart) async {
    final week = await getWeek(challengeId, weekStart);
    if (week == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    await upsertWeek(
      challengeId: challengeId,
      weekStart: weekStart,
      weekEnd: week.weekEnd,
      goalCount: week.goalCount,
      achievedCount: week.achievedCount,
      status: week.status,
      completedAt: week.completedAt,
      celebrationSeenAt: now,
      persistedAchievedFloor: week.achievedCount,
    );
  }

  Future<void> replaceAllFromServer(List<Map<String, dynamic>> remote) async {
    await _db.transaction(() async {
      await _db.delete(_db.userChallengeWeeks).go();
      await _db.delete(_db.userChallenges).go();
      for (final c in remote) {
        final id = c['id'] as String;
        await _db.into(_db.userChallenges).insert(
              UserChallengesCompanion.insert(
                id: id,
                templateCode: Value(c['templateCode'] as String?),
                customTitle: Value(c['customTitle'] as String?),
                customIcon: Value(c['customIcon'] as String?),
                customSourceKind: Value(c['customSourceKind'] as String?),
                customSourceRef: Value(c['customSourceRef'] as String?),
                customGoalCount: Value(c['customGoalCount'] as int?),
                startedAt: Value(
                  DateTime.parse(c['startedAt'] as String).toUtc(),
                ),
                archivedAt: Value(
                  c['archivedAt'] != null
                      ? DateTime.parse(c['archivedAt'] as String).toUtc()
                      : null,
                ),
                updatedAt: Value(
                  DateTime.parse(c['updatedAt'] as String).toUtc(),
                ),
              ),
            );
        final weeks = (c['weeks'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final w in weeks) {
          await _db.into(_db.userChallengeWeeks).insert(
                UserChallengeWeeksCompanion.insert(
                  id: w['id'] as String,
                  userChallengeId: id,
                  weekStart: w['weekStart'] as String,
                  weekEnd: w['weekEnd'] as String,
                  goalCount: w['goalCount'] as int,
                  achievedCount: Value(w['achievedCount'] as int? ?? 0),
                  status: Value(w['status'] as String? ?? 'IN_PROGRESS'),
                  completedAt: Value(
                    w['completedAt'] != null
                        ? DateTime.parse(w['completedAt'] as String).toUtc()
                        : null,
                  ),
                  celebrationSeenAt: Value(
                    w['celebrationSeenAt'] != null
                        ? DateTime.parse(
                            w['celebrationSeenAt'] as String,
                          ).toUtc()
                        : null,
                  ),
                  updatedAt: Value(
                    DateTime.parse(w['updatedAt'] as String).toUtc(),
                  ),
                ),
              );
        }
      }
    });
  }

  Future<void> _enqueueChallenge(
    String opType,
    Map<String, dynamic> payload,
    DateTime clientUpdatedAt,
  ) async {
    await _sync.enqueueChallengeOp(
      opType: opType,
      payload: payload,
      clientUpdatedAt: clientUpdatedAt,
    );
  }

  Future<List<UserChallenge>> _hydrateChallenges(
    List<DbUserChallenge> rows,
  ) async {
    final templates = {
      for (final t in await listTemplates()) t.code: t,
    };
    return rows.map((r) {
      final template = r.templateCode != null
          ? templates[r.templateCode!]
          : null;
      return UserChallenge(
        id: r.id,
        templateCode: r.templateCode,
        customTitle: r.customTitle,
        customIcon: r.customIcon,
        customSourceKind: r.customSourceKind,
        customSourceRef: r.customSourceRef,
        customGoalCount: r.customGoalCount,
        startedAt: r.startedAt,
        archivedAt: r.archivedAt,
        updatedAt: r.updatedAt,
        template: template,
      );
    }).toList();
  }

  ChallengeTemplate _mapTemplate(DbChallengeTemplate r) => ChallengeTemplate(
        code: r.code,
        defaultTitle: r.defaultTitle,
        defaultIcon: r.defaultIcon,
        sourceKind: r.sourceKind,
        sourceRef: r.sourceRef,
        goalCount: r.goalCount,
        defaultSortOrder: r.defaultSortOrder,
        isActive: r.isActive,
      );

  ChallengeWeek _mapWeek(DbUserChallengeWeek r) => ChallengeWeek(
        id: r.id,
        userChallengeId: r.userChallengeId,
        weekStart: r.weekStart,
        weekEnd: r.weekEnd,
        goalCount: r.goalCount,
        achievedCount: r.achievedCount,
        status: r.status,
        completedAt: r.completedAt,
        celebrationSeenAt: r.celebrationSeenAt,
        updatedAt: r.updatedAt,
      );
}

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncServiceProvider),
  );
});
