import 'package:drift/drift.dart';

@DataClassName('DbUserChallengeWeek')
class UserChallengeWeeks extends Table {
  TextColumn get id => text()();
  TextColumn get userChallengeId => text().named('user_challenge_id')();
  TextColumn get weekStart => text().named('week_start')();
  TextColumn get weekEnd => text().named('week_end')();
  IntColumn get goalCount => integer().named('goal_count')();
  IntColumn get achievedCount =>
      integer().named('achieved_count').withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('IN_PROGRESS'))();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  DateTimeColumn get celebrationSeenAt =>
      dateTime().named('celebration_seen_at').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userChallengeId, weekStart},
      ];
}
