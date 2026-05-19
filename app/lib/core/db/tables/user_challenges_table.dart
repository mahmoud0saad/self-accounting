import 'package:drift/drift.dart';

@DataClassName('DbUserChallenge')
class UserChallenges extends Table {
  TextColumn get id => text()();
  TextColumn get templateCode => text().named('template_code').nullable()();
  TextColumn get customTitle => text().named('custom_title').nullable()();
  TextColumn get customIcon => text().named('custom_icon').nullable()();
  TextColumn get customSourceKind =>
      text().named('custom_source_kind').nullable()();
  TextColumn get customSourceRef =>
      text().named('custom_source_ref').nullable()();
  IntColumn get customGoalCount =>
      integer().named('custom_goal_count').nullable()();
  DateTimeColumn get startedAt =>
      dateTime().named('started_at').withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().named('archived_at').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
