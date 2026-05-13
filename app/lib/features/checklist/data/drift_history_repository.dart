import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/time/day_key.dart';
import '../domain/day_completion.dart';
import '../domain/fard_anchor_set.dart';
import '../domain/task.dart';
import 'history_repository.dart';
import 'static_task_catalog.dart';

class DriftHistoryRepository implements HistoryRepository {
  DriftHistoryRepository(this._db);

  final AppDatabase _db;

  static final Map<String, Task> _catalogById = {
    for (final t in staticTaskCatalog) t.id: t,
  };

  static final int _catalogTotalPoints = staticTaskCatalog.fold<int>(
    0,
    (sum, t) => sum + t.points,
  );

  static final int _catalogTotalTasks = staticTaskCatalog.length;

  @override
  Future<List<DayCompletion>> readRange(DayKey start, DayKey end) async {
    final rows = await _query(start, end).get();
    return _summarize(rows, start, end);
  }

  @override
  Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end) {
    return _query(
      start,
      end,
    ).watch().map((rows) => _summarize(rows, start, end));
  }

  SimpleSelectStatement<$DailyLogsTable, DbDailyLog> _query(
    DayKey start,
    DayKey end,
  ) {
    return _db.select(_db.dailyLogs)
      ..where((r) => r.date.isBetweenValues(start.toIsoDate(), end.toIsoDate()))
      ..where((r) => r.completed.equals(true));
  }

  List<DayCompletion> _summarize(
    List<DbDailyLog> rows,
    DayKey start,
    DayKey end,
  ) {
    final byDate = <String, List<DbDailyLog>>{};
    for (final r in rows) {
      byDate.putIfAbsent(r.date, () => <DbDailyLog>[]).add(r);
    }

    final out = <DayCompletion>[];
    final spanDays = end.daysSince(start);
    if (spanDays < 0) {
      return const <DayCompletion>[];
    }

    var cursor = start;
    for (var i = 0; i <= spanDays; i++) {
      final iso = cursor.toIsoDate();
      final logs = byDate[iso] ?? const <DbDailyLog>[];

      var completedPoints = 0;
      var completedTasks = 0;
      final completedIds = <String>{};
      for (final log in logs) {
        final task = _catalogById[log.taskId];
        if (task == null) {
          continue; // Phase 2 D7: filter orphans, don't count them.
        }
        completedPoints += task.points;
        completedTasks += 1;
        completedIds.add(log.taskId);
      }
      final fardMet = fardAnchorTaskIds.every(completedIds.contains);

      out.add(
        DayCompletion(
          day: cursor,
          completedPoints: completedPoints,
          totalPoints: _catalogTotalPoints,
          completedTasks: completedTasks,
          totalTasks: _catalogTotalTasks,
          fardMet: fardMet,
        ),
      );
      cursor = cursor.nextDay();
    }

    return out;
  }
}
