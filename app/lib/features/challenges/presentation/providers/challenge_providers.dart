import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../../checklist/presentation/providers/calendar_today_provider.dart';
import '../../../checklist/presentation/providers/checklist_state_provider.dart';
import '../../../customization/presentation/providers/catalog_providers.dart';
import '../../../settings/data/app_settings_repository.dart';
import '../../data/challenge_progress_engine.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge_models.dart';
import '../../domain/week_boundary.dart';

const weekStartDowKey = 'week_start_dow';

final weekStartDowProvider =
    AsyncNotifierProvider<WeekStartDowNotifier, WeekStartDow>(
  WeekStartDowNotifier.new,
);

class WeekStartDowNotifier extends AsyncNotifier<WeekStartDow> {
  @override
  Future<WeekStartDow> build() async {
    final raw =
        await ref.read(appSettingsRepositoryProvider).readRaw(weekStartDowKey);
    return weekStartDowFromStorage(raw);
  }

  Future<void> set(WeekStartDow dow) async {
    await ref
        .read(appSettingsRepositoryProvider)
        .writeRaw(weekStartDowKey, weekStartDowToStorage(dow));
    state = AsyncData(dow);
  }
}

final challengeTemplatesProvider = StreamProvider<List<ChallengeTemplate>>((ref) {
  return ref.watch(challengeRepositoryProvider).watchTemplates();
});

final activeUserChallengesProvider =
    StreamProvider<List<UserChallenge>>((ref) {
  return ref.watch(challengeRepositoryProvider).watchActiveChallenges();
});

/// Strip layout from active challenge count only (not checklist progress).
enum WeeklyChallengeStripLayout { zero, single, multi }

final weeklyChallengeStripLayoutProvider =
    Provider<WeeklyChallengeStripLayout>((ref) {
  final catalog = ref.watch(effectiveCatalogProvider);
  if (catalog.isLoading || catalog.hasError) {
    return WeeklyChallengeStripLayout.zero;
  }
  final challenges = ref.watch(activeUserChallengesProvider);
  return challenges.when(
    data: (list) {
      if (list.isEmpty) {
        return WeeklyChallengeStripLayout.zero;
      }
      if (list.length == 1) {
        return WeeklyChallengeStripLayout.single;
      }
      return WeeklyChallengeStripLayout.multi;
    },
    loading: () => WeeklyChallengeStripLayout.zero,
    error: (_, __) => WeeklyChallengeStripLayout.zero,
  );
});

final _progressEngine = ChallengeProgressEngine();

final currentWeekProgressProvider =
    FutureProvider<List<ChallengeWithWeek>>((ref) async {
  ref.watch(checklistStateProvider);
  final challenges = await ref.watch(activeUserChallengesProvider.future);
  final repo = ref.watch(challengeRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  final dow = await ref.watch(weekStartDowProvider.future);
  final today = ref.watch(calendarTodayProvider).toLocalDateTime();
  final catalog = ref.watch(effectiveCatalogProvider).asData?.value;
  final weekStart = weekStartFor(today, dow);
  final weekEnd = weekEndFor(weekStart);
  final weekStartIso = isoDate(weekStart);
  final weekEndIso = isoDate(weekEnd);

  final allLogs = await db.select(db.dailyLogs).get();
  final logs = allLogs
      .where(
        (l) =>
            l.date.compareTo(weekStartIso) >= 0 &&
            l.date.compareTo(weekEndIso) <= 0,
      )
      .toList();

  final out = <ChallengeWithWeek>[];
  for (final c in challenges) {
    final existing = await repo.getWeek(c.id, weekStartIso);
    final derived = _progressEngine.compute(
      challenge: c,
      weekStart: weekStart,
      weekEnd: weekEnd,
      logs: logs,
      catalog: catalog,
    );

    final achieved = derived.achievedCount;
    final status = achieved >= c.goalCount ? 'COMPLETED' : 'IN_PROGRESS';

    final week = await repo.upsertWeek(
      challengeId: c.id,
      weekStart: weekStartIso,
      weekEnd: weekEndIso,
      goalCount: c.goalCount,
      achievedCount: achieved,
      status: status,
      completedAt: status == 'COMPLETED'
          ? (existing?.completedAt ?? DateTime.now().toUtc())
          : null,
      celebrationSeenAt: existing?.celebrationSeenAt,
    );
    out.add(ChallengeWithWeek(challenge: c, week: week));
  }
  return out;
});

/// Achieved/goal for one challenge; rebuilds when counts change, not strip layout.
final challengeWeekProgressProvider =
    Provider.family<({int achieved, int goal})?, String>((ref, challengeId) {
  return ref.watch(
    currentWeekProgressProvider.select(
      (async) {
        final items = async.value;
        if (items == null) {
          return null;
        }
        for (final item in items) {
          if (item.challenge.id == challengeId) {
            return (
              achieved: item.week?.achievedCount ?? 0,
              goal: item.challenge.goalCount,
            );
          }
        }
        return null;
      },
    ),
  );
});

/// Task ids and category keys with a COMPLETED challenge this week.
class CompletedChallengeWeekBadges {
  const CompletedChallengeWeekBadges({
    required this.taskIds,
    required this.categoryKeys,
  });

  final Set<String> taskIds;
  final Set<String> categoryKeys;

  static const empty = CompletedChallengeWeekBadges(
    taskIds: {},
    categoryKeys: {},
  );

  bool showsForTask(String taskId, String categoryKey) =>
      taskIds.contains(taskId) || categoryKeys.contains(categoryKey);
}

final completedChallengeWeekBadgesProvider =
    Provider<CompletedChallengeWeekBadges>((ref) {
  final progress = ref.watch(currentWeekProgressProvider);
  return progress.maybeWhen(
    data: (items) {
      final taskIds = <String>{};
      final categoryKeys = <String>{};
      for (final item in items) {
        final w = item.week;
        if (w == null || !w.isCompleted) {
          continue;
        }
        if (item.challenge.sourceKind == 'TASK_WEEKLY_COUNT') {
          taskIds.add(item.challenge.sourceRef);
        } else {
          categoryKeys.add(item.challenge.sourceRef);
        }
      }
      return CompletedChallengeWeekBadges(
        taskIds: taskIds,
        categoryKeys: categoryKeys,
      );
    },
    orElse: () => CompletedChallengeWeekBadges.empty,
  );
});

/// Fires when a challenge newly completes and celebration not yet seen.
final challengeCelebrationProvider =
    Provider<ChallengeWithWeek?>((ref) {
  final items = ref.watch(currentWeekProgressProvider).value ?? [];
  for (final item in items) {
    final w = item.week;
    if (w != null &&
        w.isCompleted &&
        w.celebrationSeenAt == null) {
      return item;
    }
  }
  return null;
});
