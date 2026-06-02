import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/db/app_database.dart';
import 'package:app/features/challenges/data/challenge_progress_engine.dart';
import 'package:app/features/challenges/domain/challenge_models.dart';
import 'package:app/features/challenges/domain/week_boundary.dart';
import 'package:app/features/customization/domain/catalog_models.dart';

UserChallenge _taskChallenge(String taskId) {
  return UserChallenge(
    id: 'c1',
    customTitle: 'Test',
    customSourceKind: 'TASK_WEEKLY_COUNT',
    customSourceRef: taskId,
    customGoalCount: 7,
    startedAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 1),
  );
}

EffectiveCatalog _catalogWithCategory(String categoryKey, List<String> taskIds) {
  return EffectiveCatalog(
    categories: [
      EffectiveCategory(
        key: categoryKey,
        displayName: categoryKey,
        icon: 'star',
        sortOrder: 0,
        isFard: false,
        isUserOwned: false,
        isVisible: true,
      ),
    ],
    tasks: [
      for (var i = 0; i < taskIds.length; i++)
        EffectiveTask(
          id: taskIds[i],
          displayName: taskIds[i],
          points: 1,
          icon: 'star',
          categoryKey: categoryKey,
          sortOrder: i,
          isUserOwned: false,
        ),
    ],
  );
}

void main() {
  final engine = ChallengeProgressEngine();
  final weekStart = DateTime(2026, 5, 16);
  final weekEnd = weekEndFor(weekStart);
  const date = '2026-05-16';

  test('TASK_WEEKLY_COUNT counts distinct dates when duplicate log rows exist', () {
    final challenge = _taskChallenge('fajr_first_congregation');
    final logs = [
      DbDailyLog(
        id: 1,
        date: date,
        taskId: 'fajr_first_congregation',
        userTaskId: null,
        completed: true,
        updatedAt: DateTime.utc(2026, 5, 16),
      ),
      DbDailyLog(
        id: 2,
        date: date,
        taskId: 'fajr_first_congregation',
        userTaskId: null,
        completed: true,
        updatedAt: DateTime.utc(2026, 5, 16, 1),
      ),
    ];

    final result = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: logs,
      catalog: null,
    );
    expect(result.achievedCount, 1);
  });

  test('CATEGORY_WEEKLY_COUNT requires all visible tasks on a day', () {
    final challenge = UserChallenge(
      id: 'c2',
      customTitle: 'Fajr block',
      customSourceKind: 'CATEGORY_WEEKLY_COUNT',
      customSourceRef: 'fajr',
      customGoalCount: 7,
      startedAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    );
    final catalog = _catalogWithCategory('fajr', ['t1', 't2', 't3']);

    final partial = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: [
        DbDailyLog(
          id: 1,
          date: date,
          taskId: 't1',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 16),
        ),
        DbDailyLog(
          id: 2,
          date: date,
          taskId: 't2',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 16),
        ),
      ],
      catalog: catalog,
    );
    expect(partial.achievedCount, 0);

    final full = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: [
        DbDailyLog(
          id: 1,
          date: date,
          taskId: 't1',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 16),
        ),
        DbDailyLog(
          id: 2,
          date: date,
          taskId: 't2',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 16),
        ),
        DbDailyLog(
          id: 3,
          date: date,
          taskId: 't3',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 16),
        ),
      ],
      catalog: catalog,
    );
    expect(full.achievedCount, 1);
  });
}
