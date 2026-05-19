import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/icons/curated_icons.dart';
import 'package:app/l10n/app_localizations.dart';
import '../domain/catalog_models.dart';
import '../domain/effective_catalog.dart';
import 'default_catalog_seed.dart';
import '../../sync/data/sync_service.dart';

final _random = Random();

String _newLocalId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x7fffffff)}';

abstract class CatalogRepository {
  Stream<EffectiveCatalog> watchEffective(AppLocalizations l);

  Future<void> createUserCategory({
    required String name,
    required String icon,
    int sortOrder = 100,
  });

  Future<void> updateUserCategory(
    String id, {
    String? name,
    String? icon,
    int? sortOrder,
  });

  Future<void> deleteUserCategory(String id, {bool force = false});

  Future<void> upsertCategoryOverride({
    required String categoryCode,
    bool? hidden,
    String? customName,
    String? customIcon,
    int? sortOrder,
  });

  Future<void> createUserTask({
    required String name,
    required String categoryRef,
    required int points,
    required String icon,
    int sortOrder = 0,
  });

  Future<void> updateUserTask(
    String id, {
    String? name,
    String? categoryRef,
    int? points,
    String? icon,
    int? sortOrder,
  });

  Future<void> deleteUserTask(String id, {bool archive = false});

  Future<void> upsertTaskOverride({
    required String taskCode,
    bool? hidden,
    String? customName,
    int? customPoints,
    String? customIcon,
    String? customCategoryRef,
    int? sortOrder,
  });
}

class DriftCatalogRepository implements CatalogRepository {
  DriftCatalogRepository(this._db, {SyncService? sync}) : _sync = sync;

  final AppDatabase _db;
  final SyncService? _sync;

  @override
  Stream<EffectiveCatalog> watchEffective(AppLocalizations l) {
    final defaults = buildDefaultCategories(l);
    final defaultTasks = buildDefaultTasks(l);

    return _watchUserData().map(
      (userData) => effectiveCatalog(
        defaultCategories: defaults,
        userCategories: userData.categories,
        categoryOverrides: userData.categoryOverrides,
        defaultTasks: defaultTasks,
        userTasks: userData.tasks,
        taskOverrides: userData.taskOverrides,
      ),
    );
  }

  Stream<_UserCatalogData> _watchUserData() {
    Stream<void> watchTable<T>(TableInfo<Table, T> table) {
      return _db.select(table).watch().map((_) {});
    }

    return Stream.multi((controller) {
      final subs = [
        watchTable(_db.userCategories).listen((_) => controller.add(null)),
        watchTable(_db.userCategoryOverrides).listen((_) => controller.add(null)),
        watchTable(_db.userTasks).listen((_) => controller.add(null)),
        watchTable(_db.userTaskOverrides).listen((_) => controller.add(null)),
      ];
      controller.onCancel = () {
        for (final s in subs) {
          s.cancel();
        }
      };
    }).asyncMap((_) => _loadUserData());
  }

  Future<_UserCatalogData> _loadUserData() async {
    final catRows = await _db.select(_db.userCategories).get();
    final catOvRows = await _db.select(_db.userCategoryOverrides).get();
    final taskRows = await _db.select(_db.userTasks).get();
    final taskOvRows = await _db.select(_db.userTaskOverrides).get();

    return _UserCatalogData(
      categories: catRows
          .map(
            (r) => UserCategory(
              id: r.id,
              name: r.name,
              icon: r.icon,
              sortOrder: r.sortOrder,
              archivedAt: r.archivedAt,
            ),
          )
          .toList(),
      categoryOverrides: catOvRows
          .map(
            (r) => UserCategoryOverride(
              categoryCode: r.categoryCode,
              hidden: r.hidden,
              customName: r.customName,
              customIcon: r.customIcon,
              sortOrder: r.sortOrder,
            ),
          )
          .toList(),
      tasks: taskRows
          .map(
            (r) => UserTask(
              id: r.id,
              categoryRef: r.categoryRef,
              name: r.name,
              points: r.points,
              icon: r.icon,
              sortOrder: r.sortOrder,
              archivedAt: r.archivedAt,
            ),
          )
          .toList(),
      taskOverrides: taskOvRows
          .map(
            (r) => UserTaskOverride(
              taskCode: r.taskCode,
              hidden: r.hidden,
              customName: r.customName,
              customPoints: r.customPoints,
              customIcon: r.customIcon,
              customCategoryRef: r.customCategoryRef,
              sortOrder: r.sortOrder,
            ),
          )
          .toList(),
    );
  }

  void _assertIcon(String icon) {
    if (!isCuratedIcon(icon)) {
      throw ArgumentError('Icon not allowed: $icon');
    }
  }

  void _assertPoints(int points) {
    if (points < 1 || points > 20) {
      throw ArgumentError('Points must be 1–20');
    }
  }

  @override
  Future<void> createUserCategory({
    required String name,
    required String icon,
    int sortOrder = 100,
  }) async {
    _assertIcon(icon);
    final id = _newLocalId('uc');
    final now = DateTime.now().toUtc();
    await _db.into(_db.userCategories).insert(
          UserCategoriesCompanion.insert(
            id: id,
            name: name.trim(),
            icon: icon,
            sortOrder: sortOrder,
            updatedAt: Value(now),
          ),
        );
    await _enqueue('create_user_category', {
      'id': id,
      'name': name.trim(),
      'icon': icon,
      'sortOrder': sortOrder,
    }, now);
  }

  @override
  Future<void> updateUserCategory(
    String id, {
    String? name,
    String? icon,
    int? sortOrder,
  }) async {
    if (icon != null) {
      _assertIcon(icon);
    }
    final now = DateTime.now().toUtc();
    await (_db.update(_db.userCategories)..where((r) => r.id.equals(id))).write(
      UserCategoriesCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    await _enqueue('update_user_category', {
      'id': id,
      if (name != null) 'name': name.trim(),
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sortOrder': sortOrder,
    }, now);
  }

  @override
  Future<void> deleteUserCategory(String id, {bool force = false}) async {
    if (force) {
      await (_db.update(_db.userTasks)
            ..where((r) => r.categoryRef.equals('userCategory:$id')))
          .write(
        const UserTasksCompanion(
          categoryRef: Value('category:miscAdhkar'),
        ),
      );
    }
    await (_db.delete(_db.userCategories)..where((r) => r.id.equals(id))).go();
    final now = DateTime.now().toUtc();
    await _enqueue('delete_user_category', {'id': id, 'force': force}, now);
  }

  @override
  Future<void> upsertCategoryOverride({
    required String categoryCode,
    bool? hidden,
    String? customName,
    String? customIcon,
    int? sortOrder,
  }) async {
    assertValidCategoryOverride(
      categoryCode: categoryCode,
      hidden: hidden ?? false,
      customName: customName,
    );
    if (customIcon != null) {
      _assertIcon(customIcon);
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.userCategoryOverrides).insertOnConflictUpdate(
          UserCategoryOverridesCompanion.insert(
            categoryCode: categoryCode,
            hidden: Value(hidden ?? false),
            customName: Value(customName),
            customIcon: Value(customIcon),
            sortOrder: Value(sortOrder),
            updatedAt: Value(now),
          ),
        );
    await _enqueue(
      'upsert_user_category_override',
      {
        'categoryCode': categoryCode,
        'hidden': hidden ?? false,
        'customName': customName,
        'customIcon': customIcon,
        'sortOrder': sortOrder,
      },
      now,
    );
  }

  @override
  Future<void> createUserTask({
    required String name,
    required String categoryRef,
    required int points,
    required String icon,
    int sortOrder = 0,
  }) async {
    _assertIcon(icon);
    _assertPoints(points);
    final id = _newLocalId('ut');
    final now = DateTime.now().toUtc();
    await _db.into(_db.userTasks).insert(
          UserTasksCompanion.insert(
            id: id,
            categoryRef: categoryRef,
            name: name.trim(),
            points: points,
            icon: icon,
            sortOrder: sortOrder,
            updatedAt: Value(now),
          ),
        );
    await _enqueue('create_user_task', {
      'id': id,
      'name': name.trim(),
      'categoryRef': categoryRef,
      'points': points,
      'icon': icon,
      'sortOrder': sortOrder,
    }, now);
  }

  @override
  Future<void> updateUserTask(
    String id, {
    String? name,
    String? categoryRef,
    int? points,
    String? icon,
    int? sortOrder,
  }) async {
    if (icon != null) {
      _assertIcon(icon);
    }
    if (points != null) {
      _assertPoints(points);
    }
    final now = DateTime.now().toUtc();
    await (_db.update(_db.userTasks)..where((r) => r.id.equals(id))).write(
      UserTasksCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        categoryRef:
            categoryRef != null ? Value(categoryRef) : const Value.absent(),
        points: points != null ? Value(points) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    await _enqueue('update_user_task', {
      'id': id,
      if (name != null) 'name': name.trim(),
      if (categoryRef != null) 'categoryRef': categoryRef,
      if (points != null) 'points': points,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sortOrder': sortOrder,
    }, now);
  }

  @override
  Future<void> deleteUserTask(String id, {bool archive = false}) async {
    final now = DateTime.now().toUtc();
    if (archive) {
      await (_db.update(_db.userTasks)..where((r) => r.id.equals(id))).write(
        UserTasksCompanion(archivedAt: Value(now), updatedAt: Value(now)),
      );
    } else {
      await (_db.delete(_db.userTasks)..where((r) => r.id.equals(id))).go();
    }
    await _enqueue(
      'delete_user_task',
      {'id': id, 'archive': archive},
      now,
    );
  }

  @override
  Future<void> upsertTaskOverride({
    required String taskCode,
    bool? hidden,
    String? customName,
    int? customPoints,
    String? customIcon,
    String? customCategoryRef,
    int? sortOrder,
  }) async {
    if (customPoints != null) {
      _assertPoints(customPoints);
    }
    if (customIcon != null) {
      _assertIcon(customIcon);
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.userTaskOverrides).insertOnConflictUpdate(
          UserTaskOverridesCompanion.insert(
            taskCode: taskCode,
            hidden: Value(hidden ?? false),
            customName: Value(customName),
            customPoints: Value(customPoints),
            customIcon: Value(customIcon),
            customCategoryRef: Value(customCategoryRef),
            sortOrder: Value(sortOrder),
            updatedAt: Value(now),
          ),
        );
    await _enqueue(
      'upsert_user_task_override',
      {
        'taskCode': taskCode,
        'hidden': hidden ?? false,
        'customName': customName,
        'customPoints': customPoints,
        'customIcon': customIcon,
        'customCategoryRef': customCategoryRef,
        'sortOrder': sortOrder,
      },
      now,
    );
  }

  Future<void> _enqueue(
    String opType,
    Map<String, dynamic> payload,
    DateTime clientUpdatedAt,
  ) async {
    await _sync?.enqueueCustomizationOp(
      opType: opType,
      payload: payload,
      clientUpdatedAt: clientUpdatedAt,
    );
  }
}

class _UserCatalogData {
  _UserCatalogData({
    required this.categories,
    required this.categoryOverrides,
    required this.tasks,
    required this.taskOverrides,
  });

  final List<UserCategory> categories;
  final List<UserCategoryOverride> categoryOverrides;
  final List<UserTask> tasks;
  final List<UserTaskOverride> taskOverrides;
}
