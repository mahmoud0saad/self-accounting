import 'package:drift/drift.dart';

@DataClassName('DbCategory')
class Categories extends Table {
  TextColumn get code => text()();
  TextColumn get defaultName => text().named('default_name')();
  TextColumn get defaultIcon => text().named('default_icon')();
  IntColumn get defaultSortOrder => integer().named('default_sort_order')();
  BoolColumn get isFard => boolean().named('is_fard')();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
