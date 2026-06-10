import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/checklist/data/static_task_catalog.dart';
import 'tables/app_settings_table.dart';
import 'tables/category_notification_schedules_table.dart';
import 'tables/daily_logs_table.dart';
import 'tables/task_notification_toggles_table.dart';
import 'tables/categories_table.dart';
import 'tables/pending_sync_ops_table.dart';
import 'tables/tasks_table.dart';
import 'tables/user_categories_table.dart';
import 'tables/user_category_overrides_table.dart';
import 'tables/user_task_overrides_table.dart';
import 'tables/user_tasks_table.dart';
import 'tables/challenge_templates_table.dart';
import 'tables/user_challenges_table.dart';
import 'tables/user_challenge_weeks_table.dart';
import '../../features/challenges/data/challenge_template_seed.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    DailyLogs,
    Categories,
    UserCategories,
    UserCategoryOverrides,
    UserTasks,
    UserTaskOverrides,
    AppSettings,
    CategoryNotificationSchedules,
    TaskNotificationToggles,
    PendingSyncOps,
    ChallengeTemplates,
    UserChallenges,
    UserChallengeWeeks,
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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCategoriesTable();
      await _seedNotificationDefaults();
      await _seedChallengeTemplates();
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
      if (from < 4) {
        await m.createTable(categories);
        await m.createTable(userCategories);
        await m.createTable(userCategoryOverrides);
        await m.createTable(userTasks);
        await m.createTable(userTaskOverrides);
        await _seedCategoriesTable();
      }
      if (from < 5) {
        await _migrateDailyLogsForUserTasks();
      }
      if (from < 6) {
        await m.createTable(challengeTemplates);
        await m.createTable(userChallenges);
        await m.createTable(userChallengeWeeks);
        await _seedChallengeTemplates();
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
      assert(sum == 69, 'static catalog sum drifted from 69');
      assertFardAnchorIntegrity();
    }
  }

  /// Rebuilds [daily_logs] so user-owned completions can reference [user_tasks].
  Future<void> _migrateDailyLogsForUserTasks() async {
    await customStatement('''
      CREATE TABLE daily_logs_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        task_id TEXT REFERENCES tasks(id),
        user_task_id TEXT REFERENCES user_tasks(id),
        completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0, 1)),
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
      );
    ''');
    await customStatement('''
      INSERT INTO daily_logs_new (date, task_id, completed, updated_at)
      SELECT date, task_id, completed, updated_at FROM daily_logs;
    ''');
    await customStatement('DROP TABLE daily_logs;');
    await customStatement(
      'ALTER TABLE daily_logs_new RENAME TO daily_logs;',
    );
    await customStatement('''
      CREATE UNIQUE INDEX uq_daily_logs_date_task
      ON daily_logs(date, task_id)
      WHERE task_id IS NOT NULL;
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX uq_daily_logs_date_user_task
      ON daily_logs(date, user_task_id)
      WHERE user_task_id IS NOT NULL;
    ''');
  }

  Future<void> _seedCategoriesTable() async {
    const rows = [
      ('fajr', 'Fajr', 'wb_twilight', 0, true),
      ('dhuhr', 'Dhuhr', 'wb_sunny', 1, true),
      ('asr', 'Asr', 'partly_cloudy_day', 2, true),
      ('maghrib', 'Maghrib', 'wb_twilight', 3, true),
      ('isha', 'Isha', 'nights_stay', 4, true),
      ('qiyamEvening', 'Qiyam & Evening', 'bedtime', 5, false),
      ('quranFasting', 'Quran & Fasting', 'menu_book', 6, false),
      ('miscAdhkar', 'Misc Adhkar', 'auto_awesome', 7, false),
    ];
    for (final r in rows) {
      await into(categories).insertOnConflictUpdate(
        CategoriesCompanion.insert(
          code: r.$1,
          defaultName: r.$2,
          defaultIcon: r.$3,
          defaultSortOrder: r.$4,
          isFard: r.$5,
        ),
      );
    }
  }

  Future<void> _seedChallengeTemplates() async {
    for (final t in kSeededChallengeTemplates) {
      await into(challengeTemplates).insertOnConflictUpdate(
        ChallengeTemplatesCompanion.insert(
          code: t.code,
          defaultTitle: t.defaultTitle,
          defaultIcon: t.defaultIcon,
          sourceKind: t.sourceKind,
          sourceRef: t.sourceRef,
          goalCount: t.goalCount,
          defaultSortOrder: Value(t.defaultSortOrder),
        ),
      );
    }
  }

  Future<void> clearUserData() async {
    await delete(dailyLogs).go();
    await delete(userChallengeWeeks).go();
    await delete(userChallenges).go();
    await delete(pendingSyncOps).go();
    await delete(userCategoryOverrides).go();
    await delete(userTaskOverrides).go();
    await delete(userTasks).go();
    await delete(userCategories).go();
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
        'eod_enabled': 'false',
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
