import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../../checklist/domain/task.dart';
import '../domain/category_notification_schedule.dart';
import '../domain/task_notification_toggle.dart';

class NotificationSettingsRepository {
  const NotificationSettingsRepository(this._db);

  final AppDatabase _db;

  Stream<List<CategoryNotificationSchedule>> watchCategorySchedules() {
    return (_db.select(
      _db.categoryNotificationSchedules,
    )..orderBy([(r) => OrderingTerm.asc(r.category)])).watch().map((rows) {
      final byName = {for (final row in rows) row.category: row};
      return [
        for (final category in TaskCategory.values)
          _categoryScheduleFromRow(category, byName[category.name]),
      ];
    });
  }

  Future<void> setCategoryEnabled(TaskCategory category, bool enabled) async {
    final current = await (_db.select(
      _db.categoryNotificationSchedules,
    )..where((r) => r.category.equals(category.name))).getSingleOrNull();
    await _db
        .into(_db.categoryNotificationSchedules)
        .insertOnConflictUpdate(
          CategoryNotificationSchedulesCompanion.insert(
            category: category.name,
            enabled: Value(enabled),
            hour: current?.hour ?? _defaultHour(category),
            minute: current?.minute ?? _defaultMinute(category),
          ),
        );
  }

  Future<void> setCategoryTime(
    TaskCategory category,
    int hour,
    int minute,
  ) async {
    final current = await (_db.select(
      _db.categoryNotificationSchedules,
    )..where((r) => r.category.equals(category.name))).getSingleOrNull();
    await _db
        .into(_db.categoryNotificationSchedules)
        .insertOnConflictUpdate(
          CategoryNotificationSchedulesCompanion.insert(
            category: category.name,
            enabled: Value(current?.enabled ?? true),
            hour: hour,
            minute: minute,
          ),
        );
  }

  Stream<List<TaskNotificationToggle>> watchTaskToggles() {
    return _db
        .select(_db.taskNotificationToggles)
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              TaskNotificationToggle(
                taskId: row.taskId,
                notificationsEnabled: row.notificationsEnabled,
              ),
          ],
        );
  }

  Future<void> setTaskEnabled(String taskId, bool enabled) {
    return _db
        .into(_db.taskNotificationToggles)
        .insertOnConflictUpdate(
          TaskNotificationTogglesCompanion.insert(
            taskId: taskId,
            notificationsEnabled: Value(enabled),
          ),
        );
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
      return NotificationSettingsRepository(ref.watch(appDatabaseProvider));
    });

CategoryNotificationSchedule _categoryScheduleFromRow(
  TaskCategory category,
  DbCategoryNotificationSchedule? row,
) {
  return CategoryNotificationSchedule(
    category: category,
    enabled: row?.enabled ?? true,
    hour: row?.hour ?? _defaultHour(category),
    minute: row?.minute ?? _defaultMinute(category),
  );
}

int _defaultHour(TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => 5,
    TaskCategory.dhuhr => 13,
    TaskCategory.asr => 16,
    TaskCategory.maghrib => 18,
    TaskCategory.isha => 20,
    TaskCategory.qiyamEvening => 21,
    TaskCategory.quranFasting => 6,
    TaskCategory.miscAdhkar => 7,
  };
}

int _defaultMinute(TaskCategory category) {
  return switch (category) {
    TaskCategory.maghrib => 30,
    TaskCategory.miscAdhkar => 30,
    _ => 0,
  };
}
