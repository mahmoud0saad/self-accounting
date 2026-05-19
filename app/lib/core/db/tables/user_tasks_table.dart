import 'package:drift/drift.dart';

@DataClassName('DbUserTask')
class UserTasks extends Table {
  TextColumn get id => text()();
  TextColumn get categoryRef => text().named('category_ref')();
  TextColumn get name => text()();
  IntColumn get points => integer()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().named('sort_order')();
  DateTimeColumn get archivedAt => dateTime().named('archived_at').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
