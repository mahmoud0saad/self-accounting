import 'package:drift/drift.dart';

@DataClassName('DbUserTaskOverride')
class UserTaskOverrides extends Table {
  TextColumn get taskCode => text().named('task_code')();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get customName => text().named('custom_name').nullable()();
  IntColumn get customPoints => integer().named('custom_points').nullable()();
  TextColumn get customIcon => text().named('custom_icon').nullable()();
  TextColumn get customCategoryRef =>
      text().named('custom_category_ref').nullable()();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {taskCode};
}
