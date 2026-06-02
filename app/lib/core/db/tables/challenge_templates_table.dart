import 'package:drift/drift.dart';

@DataClassName('DbChallengeTemplate')
class ChallengeTemplates extends Table {
  TextColumn get code => text()();
  TextColumn get defaultTitle => text().named('default_title')();
  TextColumn get defaultIcon => text().named('default_icon')();
  TextColumn get sourceKind => text().named('source_kind')();
  TextColumn get sourceRef => text().named('source_ref')();
  IntColumn get goalCount => integer().named('goal_count')();
  IntColumn get defaultSortOrder =>
      integer().named('default_sort_order').withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
