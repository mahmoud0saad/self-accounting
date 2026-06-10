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

  test('cumulative custom goal counts distinct days since startedAt', () {
    final challenge = UserChallenge(
      id: 'c3',
      customTitle: 'Long run',
      customSourceKind: 'TASK_WEEKLY_COUNT',
      customSourceRef: 'fajr_first_congregation',
      customGoalCount: 14,
      startedAt: DateTime(2026, 5, 9),
      updatedAt: DateTime.utc(2026, 5, 9),
    );
    final logs = [
      for (var i = 0; i < 8; i++)
        DbDailyLog(
          id: i + 1,
          date: isoDate(DateTime(2026, 5, 10 + i)),
          taskId: 'fajr_first_congregation',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 10 + i),
        ),
    ];

    final inProgress = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: logs,
      catalog: null,
    );
    expect(inProgress.achievedCount, 8);
    expect(inProgress.status, 'IN_PROGRESS');

    final completedLogs = [
      for (var i = 0; i < 14; i++)
        DbDailyLog(
          id: 100 + i,
          date: isoDate(DateTime(2026, 5, 9 + i)),
          taskId: 'fajr_first_congregation',
          userTaskId: null,
          completed: true,
          updatedAt: DateTime.utc(2026, 5, 9 + i),
        ),
    ];
    final completed = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: completedLogs,
      catalog: null,
    );
    expect(completed.achievedCount, 14);
    expect(completed.status, 'COMPLETED');
  });

  test('custom goal at 7 uses weekly window only', () {
    final challenge = UserChallenge(
      id: 'c4',
      customTitle: 'Week only',
      customSourceKind: 'TASK_WEEKLY_COUNT',
      customSourceRef: 'fajr_first_congregation',
      customGoalCount: 7,
      startedAt: DateTime(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    );
    final logs = [
      DbDailyLog(
        id: 1,
        date: '2026-05-10',
        taskId: 'fajr_first_congregation',
        userTaskId: null,
        completed: true,
        updatedAt: DateTime.utc(2026, 5, 10),
      ),
    ];

    final result = engine.compute(
      challenge: challenge,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: logs,
      catalog: null,
    );
    expect(result.achievedCount, 0);
    expect(challenge.usesCumulativeProgress, isFalse);
  });
}
