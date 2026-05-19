import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../settings/data/app_settings_repository.dart';
import 'sync_api.dart';
import 'sync_constants.dart';

enum CustomizationRestoreState {
  idle,
  checking,
  pushing,
  restoring,
  done,
  cancelledByUser,
  error,
}

class CustomizationRestoreEvent {
  const CustomizationRestoreEvent({
    required this.state,
    this.restoredCount = 0,
    this.message,
  });

  final CustomizationRestoreState state;
  final int restoredCount;
  final String? message;
}

class CustomizationRestoreService {
  CustomizationRestoreService({
    required this.db,
    required this.api,
    required this.storage,
    required this.settings,
    required this.ref,
    required this.drainOutbound,
  });

  final AppDatabase db;
  final SyncApi api;
  final TokenStorage storage;
  final AppSettingsRepository settings;
  final Ref ref;
  final Future<void> Function() drainOutbound;

  final _events = StreamController<CustomizationRestoreEvent>.broadcast();
  DateTime? _lastErrorAt;

  Stream<CustomizationRestoreEvent> get events => _events.stream;

  bool get _canRun {
    final auth = ref.read(authNotifierProvider);
    return auth.status == AuthStatus.authenticated &&
        auth.user != null &&
        auth.user!.isEmailConfirmed;
  }

  Future<void> restoreIfNeeded({
    bool force = false,
    required Future<bool> Function(int totalItems) confirmReplacePrompt,
  }) async {
    if (!_canRun) {
      _emit(const CustomizationRestoreEvent(state: CustomizationRestoreState.idle));
      return;
    }
    final userId = ref.read(authNotifierProvider).user!.id;
    if (!force && await storage.isCustomizationFirstSyncDone(userId)) {
      _emit(const CustomizationRestoreEvent(state: CustomizationRestoreState.idle));
      return;
    }
    if (_lastErrorAt != null &&
        DateTime.now().difference(_lastErrorAt!) < const Duration(minutes: 5)) {
      return;
    }

    try {
      _emit(
        const CustomizationRestoreEvent(
          state: CustomizationRestoreState.checking,
        ),
      );
      final snapshot = await api.fetchSnapshotState();
      final lastUpdatedAt = snapshot['lastUpdatedAt'] as String?;
      if (lastUpdatedAt != null) {
        await storage.writeCustomizationServerLastSeen(userId, lastUpdatedAt);
      }

      final hasSnapshot = snapshot['hasSnapshot'] as bool? ?? false;
      final totals = snapshot['totals'] as Map<String, dynamic>? ?? {};
      final totalItems = (totals['userCategories'] as int? ?? 0) +
          (totals['userTasks'] as int? ?? 0) +
          (totals['categoryOverrides'] as int? ?? 0) +
          (totals['taskOverrides'] as int? ?? 0);

      if (hasSnapshot) {
        final confirmed = await confirmReplacePrompt(totalItems);
        if (!confirmed) {
          await storage.markCustomizationFirstSyncDone(userId);
          _emit(
            const CustomizationRestoreEvent(
              state: CustomizationRestoreState.cancelledByUser,
            ),
          );
          return;
        }
        _emit(
          const CustomizationRestoreEvent(
            state: CustomizationRestoreState.restoring,
          ),
        );
        final count = await _pullServerSnapshot();
        await settings.setCustomizationLastRestoredAt(DateTime.now().toUtc());
        await storage.markCustomizationFirstSyncDone(userId);
        _emit(
          CustomizationRestoreEvent(
            state: CustomizationRestoreState.done,
            restoredCount: count,
          ),
        );
        return;
      }

      _emit(
        const CustomizationRestoreEvent(
          state: CustomizationRestoreState.pushing,
        ),
      );
      final pushed = await _pushLocalToServer();
      await drainOutbound();
      await _pullServerSnapshot();
      await settings.setCustomizationLastRestoredAt(DateTime.now().toUtc());
      await storage.markCustomizationFirstSyncDone(userId);
      _emit(
        CustomizationRestoreEvent(
          state: CustomizationRestoreState.done,
          restoredCount: pushed,
        ),
      );
    } on Object catch (e) {
      _lastErrorAt = DateTime.now();
      _emit(
        CustomizationRestoreEvent(
          state: CustomizationRestoreState.error,
          message: e.toString(),
        ),
      );
    }
  }

  Future<int> _pullServerSnapshot() async {
    final catalog = await api.fetchCatalog();
    return db.transaction(() async {
      final pending = await db.select(db.pendingSyncOps).get();
      for (final op in pending) {
        if (isCustomizationOpType(op.opType)) {
          await (db.delete(db.pendingSyncOps)..where((t) => t.id.equals(op.id)))
              .go();
        }
      }

      await db.delete(db.userCategoryOverrides).go();
      await db.delete(db.userTaskOverrides).go();
      await db.delete(db.userTasks).go();
      await db.delete(db.userCategories).go();

      final userTasks =
          (catalog['userTasks'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final serverTaskIds = userTasks.map((t) => t['id'] as String).toSet();

      final orphanLogs = await (db.select(db.dailyLogs)
            ..where((r) => r.userTaskId.isNotNull()))
          .get();
      for (final log in orphanLogs) {
        if (!serverTaskIds.contains(log.userTaskId)) {
          await (db.delete(db.dailyLogs)..where((r) => r.id.equals(log.id))).go();
        }
      }

      for (final c in (catalog['userCategories'] as List<dynamic>? ?? [])) {
        final m = c as Map<String, dynamic>;
        await db.into(db.userCategories).insert(
              UserCategoriesCompanion.insert(
                id: m['id'] as String,
                name: m['name'] as String,
                icon: m['icon'] as String,
                sortOrder: m['sortOrder'] as int,
                archivedAt: Value(
                  m['archivedAt'] != null
                      ? DateTime.parse(m['archivedAt'] as String).toUtc()
                      : null,
                ),
                updatedAt: Value(
                  DateTime.parse(m['updatedAt'] as String).toUtc(),
                ),
              ),
            );
      }

      for (final t in userTasks) {
        await db.into(db.userTasks).insert(
              UserTasksCompanion.insert(
                id: t['id'] as String,
                categoryRef: t['categoryRef'] as String,
                name: t['name'] as String,
                points: t['points'] as int,
                icon: t['icon'] as String,
                sortOrder: t['sortOrder'] as int,
                archivedAt: Value(
                  t['archivedAt'] != null
                      ? DateTime.parse(t['archivedAt'] as String).toUtc()
                      : null,
                ),
                updatedAt: Value(
                  DateTime.parse(t['updatedAt'] as String).toUtc(),
                ),
              ),
            );
      }

      for (final o
          in (catalog['userCategoryOverrides'] as List<dynamic>? ?? [])) {
        final m = o as Map<String, dynamic>;
        await db.into(db.userCategoryOverrides).insert(
              UserCategoryOverridesCompanion.insert(
                categoryCode: m['categoryCode'] as String,
                hidden: Value(m['hidden'] as bool? ?? false),
                customName: Value(m['customName'] as String?),
                customIcon: Value(m['customIcon'] as String?),
                sortOrder: Value(m['sortOrder'] as int?),
                updatedAt: Value(
                  DateTime.parse(m['updatedAt'] as String).toUtc(),
                ),
              ),
            );
      }

      for (final o in (catalog['userTaskOverrides'] as List<dynamic>? ?? [])) {
        final m = o as Map<String, dynamic>;
        await db.into(db.userTaskOverrides).insert(
              UserTaskOverridesCompanion.insert(
                taskCode: m['taskCode'] as String,
                hidden: Value(m['hidden'] as bool? ?? false),
                customName: Value(m['customName'] as String?),
                customPoints: Value(m['customPoints'] as int?),
                customIcon: Value(m['customIcon'] as String?),
                customCategoryRef: Value(m['customCategoryRef'] as String?),
                sortOrder: Value(m['sortOrder'] as int?),
                updatedAt: Value(
                  DateTime.parse(m['updatedAt'] as String).toUtc(),
                ),
              ),
            );
      }

      return userTasks.length +
          (catalog['userCategories'] as List<dynamic>? ?? []).length +
          (catalog['userCategoryOverrides'] as List<dynamic>? ?? []).length +
          (catalog['userTaskOverrides'] as List<dynamic>? ?? []).length;
    });
  }

  Future<int> _pushLocalToServer() async {
    final pending = await db.select(db.pendingSyncOps).get();
    for (final op in pending) {
      if (isCustomizationOpType(op.opType)) {
        await (db.delete(db.pendingSyncOps)..where((t) => t.id.equals(op.id)))
            .go();
      }
    }

    var count = 0;
    final categoryIdMap = <String, String>{};

    final categories = await db.select(db.userCategories).get();
    for (final c in categories) {
      if (c.archivedAt != null) {
        continue;
      }
      final created = await api.createUserCategory(
        name: c.name,
        icon: c.icon,
        sortOrder: c.sortOrder,
      );
      categoryIdMap[c.id] = created['id'] as String;
      count++;
    }

    final tasks = await db.select(db.userTasks).get();
    for (final t in tasks) {
      var categoryRef = t.categoryRef;
      if (categoryRef.startsWith('userCategory:')) {
        final localId = categoryRef.substring('userCategory:'.length);
        final mapped = categoryIdMap[localId];
        if (mapped != null) {
          categoryRef = 'userCategory:$mapped';
        }
      }
      final created = await api.createUserTask(
        name: t.name,
        categoryRef: categoryRef,
        points: t.points,
        icon: t.icon,
        sortOrder: t.sortOrder,
      );
      final serverId = created['id'] as String;
      if (t.archivedAt != null) {
        await api.deleteUserTask(serverId, archive: true);
      }
      count++;
    }

    final catOverrides = await db.select(db.userCategoryOverrides).get();
    for (final o in catOverrides) {
      await api.upsertCategoryOverride(
        o.categoryCode,
        hidden: o.hidden,
        customName: o.customName,
        customIcon: o.customIcon,
        sortOrder: o.sortOrder,
      );
      count++;
    }

    final taskOverrides = await db.select(db.userTaskOverrides).get();
    for (final o in taskOverrides) {
      await api.upsertTaskOverride(
        o.taskCode,
        hidden: o.hidden,
        customName: o.customName,
        customPoints: o.customPoints,
        customIcon: o.customIcon,
        customCategoryRef: o.customCategoryRef,
        sortOrder: o.sortOrder,
      );
      count++;
    }

    return count;
  }

  void _emit(CustomizationRestoreEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  void dispose() {
    _events.close();
  }
}
