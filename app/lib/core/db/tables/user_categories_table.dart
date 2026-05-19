import 'package:drift/drift.dart';

@DataClassName('DbUserCategory')
class UserCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().named('sort_order')();
  DateTimeColumn get archivedAt => dateTime().named('archived_at').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
