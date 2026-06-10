import '../../../core/db/app_database.dart';
import '../../customization/domain/catalog_models.dart';
import '../domain/challenge_models.dart';
import '../domain/week_boundary.dart';

class ChallengeProgressResult {
  const ChallengeProgressResult({
    required this.achievedCount,
    required this.status,
  });

  final int achievedCount;
  final String status;
}

class ChallengeProgressEngine {
  ChallengeProgressResult compute({
    required UserChallenge challenge,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<DbDailyLog> logs,
    required EffectiveCatalog? catalog,
  }) {
    final goal = challenge.goalCount;
    final rangeStart = challenge.usesCumulativeProgress
        ? dateOnly(challenge.startedAt.toLocal())
        : dateOnly(weekStart);
    final dates = datesInWeek(rangeStart, weekEnd);
    final completedDates = <String>{};

    if (challenge.sourceKind == 'TASK_WEEKLY_COUNT') {
      final ref = challenge.sourceRef;
      for (final date in dates) {
        final hit = logs.any(
          (l) =>
              l.date == date &&
              l.completed &&
              (l.taskId == ref || l.userTaskId == ref),
        );
        if (hit) {
          completedDates.add(date);
        }
      }
    } else {
      for (final date in dates) {
        if (_isCategoryPerfect(catalog, logs, date, challenge.sourceRef)) {
          completedDates.add(date);
        }
      }
    }

    final achieved = completedDates.length.clamp(0, goal);
    final status = achieved >= goal ? 'COMPLETED' : 'IN_PROGRESS';
    return ChallengeProgressResult(
      achievedCount: achieved,
      status: status,
    );
  }

  bool _isCategoryPerfect(
    EffectiveCatalog? catalog,
    List<DbDailyLog> logs,
    String date,
    String categoryCode,
  ) {
    if (catalog == null) {
      return false;
    }
    final tasks =
        catalog.tasks.where((t) => t.categoryKey == categoryCode).toList();
    if (tasks.isEmpty) {
      return false;
    }
    for (final t in tasks) {
      final done = logs.any(
        (l) =>
            l.date == date &&
            l.completed &&
            (l.taskId == t.id || l.userTaskId == t.id),
      );
      if (!done) {
        return false;
      }
    }
    return true;
  }
}
