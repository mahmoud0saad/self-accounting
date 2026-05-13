import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/checklist/data/static_task_catalog.dart';
import 'tables/app_settings_table.dart';
import 'tables/daily_logs_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, DailyLogs, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      throw StateError(
        'No migration path defined yet; bump schemaVersion deliberately.',
      );
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
    }
  }
}
