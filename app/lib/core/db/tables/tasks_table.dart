import 'package:drift/drift.dart';

@DataClassName('DbTask')
class Tasks extends Table {
  TextColumn get id => text()();
  IntColumn get points => integer()();
  TextColumn get category => text()();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
