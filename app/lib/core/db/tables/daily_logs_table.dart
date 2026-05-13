import 'package:drift/drift.dart';

import 'tasks_table.dart';

@DataClassName('DbDailyLog')
class DailyLogs extends Table {
  TextColumn get date => text()();
  TextColumn get taskId => text().named('task_id').references(Tasks, #id)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {date, taskId};
}
