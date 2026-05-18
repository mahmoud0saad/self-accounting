import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/time/day_key.dart';
import '../../checklist/data/remote_log_repository.dart';
import '../../settings/data/app_settings_repository.dart';

class MergeService {
  MergeService(this._db, this._logs, this._settings);

  final AppDatabase _db;
  final RemoteLogRepository _logs;
  final AppSettingsRepository _settings;

  String _mergeKey(String accountKey) => 'merge_done_$accountKey';

  Future<void> mergeOnFirstSignIn(String accountKey) async {
    final key = _mergeKey(accountKey);
    final done = await _settings.getBool(key);
    if (done == true) {
      return;
    }

    final rows = await _db.select(_db.dailyLogs).get();
    for (final row in rows) {
      await _logs.upsert(
        day: DayKey.parseIso(row.date),
        taskId: row.taskId,
        completed: row.completed,
        updatedAt: row.updatedAt.toUtc(),
      );
    }

    await _settings.setBool(key, true);
  }

  Future<void> pullLogsIntoLocal({
    required DayKey from,
    required DayKey to,
  }) async {
    final remote = await _logs.fetchRange(from: from, to: to);
    await _db.transaction(() async {
      for (final record in remote) {
        final existing = await (_db.select(_db.dailyLogs)..where(
          (r) =>
              r.date.equals(record.date) & r.taskId.equals(record.taskId),
        )).getSingleOrNull();

        if (existing != null && !record.updatedAt.isAfter(existing.updatedAt)) {
          continue;
        }

        await _db.into(_db.dailyLogs).insertOnConflictUpdate(
          DailyLogsCompanion.insert(
            date: record.date,
            taskId: record.taskId,
            completed: Value(record.completed),
            updatedAt: Value(record.updatedAt),
          ),
        );
      }
    });
  }
}
