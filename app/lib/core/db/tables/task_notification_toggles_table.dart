import 'package:drift/drift.dart';

@DataClassName('DbTaskNotificationToggle')
class TaskNotificationToggles extends Table {
  TextColumn get taskId => text().named('task_id')();
  BoolColumn get notificationsEnabled => boolean()
      .named('notifications_enabled')
      .withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {taskId};
}
