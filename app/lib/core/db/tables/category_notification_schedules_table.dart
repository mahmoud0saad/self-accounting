import 'package:drift/drift.dart';

@DataClassName('DbCategoryNotificationSchedule')
class CategoryNotificationSchedules extends Table {
  TextColumn get category => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  @override
  Set<Column<Object>> get primaryKey => {category};
}
