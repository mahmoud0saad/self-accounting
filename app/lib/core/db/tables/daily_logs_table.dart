import 'package:drift/drift.dart';

import 'tasks_table.dart';
import 'user_tasks_table.dart';

@DataClassName('DbDailyLog')
class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get date => text()();

  /// Default catalog task code; null when [userTaskId] is set.
  TextColumn get taskId =>
      text().named('task_id').nullable().references(Tasks, #id)();

  /// User-owned task id (`ut_…`); null when [taskId] is set.
  TextColumn get userTaskId =>
      text().named('user_task_id').nullable().references(UserTasks, #id)();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}
