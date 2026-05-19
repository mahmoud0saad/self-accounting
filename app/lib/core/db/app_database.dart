import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/checklist/data/static_task_catalog.dart';
import 'tables/app_settings_table.dart';
import 'tables/category_notification_schedules_table.dart';
import 'tables/daily_logs_table.dart';
import 'tables/task_notification_toggles_table.dart';
import 'tables/pending_sync_ops_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    DailyLogs,
    AppSettings,
    CategoryNotificationSchedules,
    TaskNotificationToggles,
    PendingSyncOps,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const Map<String, (int, int)> _defaultNotificationTimes = {
    'fajr': (5, 0),
    'dhuhr': (13, 0),
    'asr': (16, 0),
    'maghrib': (18, 30),
    'isha': (20, 0),
    'qiyamEvening': (21, 0),
    'quranFasting': (6, 0),
    'miscAdhkar': (7, 30),
  };

  static Future<AppDatabase> open() async {
    final executor = driftDatabase(
      name: 'muhasabah',
      native: const DriftNativeOptions(),
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            )
          : null,
    );
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedNotificationDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(categoryNotificationSchedules);
        await m.createTable(taskNotificationToggles);
        await _seedNotificationDefaults();
      }
      if (from < 3) {
        await m.createTable(pendingSyncOps);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  /// Upserts catalog rows; never deletes orphan task ids (Phase 2 spec D7).
  Future<void> seedAndReconcile() async {
    await transaction(() async {
      var index = 0;
      for (final t in staticTaskCatalog) {
        await into(tasks).insertOnConflictUpdate(
          TasksCompanion.insert(
            id: t.id,
            points: t.points,
            category: t.category.name,
            sortOrder: index,
          ),
        );
        index++;
      }
    });

    if (kDebugMode) {
      final ids = staticTaskCatalog.map((e) => e.id).toList();
      final rows = await (select(tasks)..where((r) => r.id.isIn(ids))).get();
      final sum = rows.fold<int>(0, (s, r) => s + r.points);
      assert(sum == 74, 'static catalog sum drifted from 74');
      assertFardAnchorIntegrity();
    }
  }

  Future<void> clearUserData() async {
    await delete(dailyLogs).go();
    await delete(pendingSyncOps).go();
    await delete(categoryNotificationSchedules).go();
    await delete(taskNotificationToggles).go();
    await delete(appSettings).go();
    await _seedNotificationDefaults();
  }

  Future<void> _seedNotificationDefaults() async {
    await transaction(() async {
      for (final entry in _defaultNotificationTimes.entries) {
        await into(categoryNotificationSchedules).insertOnConflictUpdate(
          CategoryNotificationSchedulesCompanion.insert(
            category: entry.key,
            enabled: const Value(true),
            hour: entry.value.$1,
            minute: entry.value.$2,
          ),
        );
      }

      for (final task in staticTaskCatalog) {
        await into(taskNotificationToggles).insertOnConflictUpdate(
          TaskNotificationTogglesCompanion.insert(
            taskId: task.id,
            notificationsEnabled: const Value(true),
          ),
        );
      }

      const defaults = {
        'notifications_enabled': 'true',
        'eod_enabled': 'true',
        'eod_hour': '21',
        'eod_minute': '30',
      };
      for (final entry in defaults.entries) {
        await into(appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: entry.key,
            value: Value(entry.value),
          ),
        );
      }
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: ['notification', 'onboarding', 'done'].join('_'),
          value: const Value('false'),
        ),
      );
    });
  }
}
