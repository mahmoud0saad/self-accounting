import 'package:drift/drift.dart';

@DataClassName('DbUserCategoryOverride')
class UserCategoryOverrides extends Table {
  TextColumn get categoryCode => text().named('category_code')();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get customName => text().named('custom_name').nullable()();
  TextColumn get customIcon => text().named('custom_icon').nullable()();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {categoryCode};
}
