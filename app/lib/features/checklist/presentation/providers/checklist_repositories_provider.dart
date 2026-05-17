import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../../../core/time/day_key.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/api/remote_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../data/caching_remote_task_repository.dart';
import '../../data/checklist_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/synced_checklist_repository.dart';
import '../../data/task_repository.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final local = DriftChecklistRepository(ref.watch(appDatabaseProvider));
  if (!ref.watch(authStateProvider).isSignedIn) {
    return local;
  }
  return SyncedChecklistRepository(local, ref.watch(syncServiceProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final local = DriftTaskRepository(ref.watch(appDatabaseProvider));
  if (!ref.watch(authStateProvider).isSignedIn) {
    return local;
  }
  return CachingRemoteTaskRepository(
    local,
    ref.watch(remoteTaskRepositoryProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Phase 4 D3: bumped from 30 → 90 to power the Dashboard's 90-day range
/// option. The day picker, streak window, and dashboard window all read from
/// this single source of truth.
const kMaxHistoryDays = 90;

/// How far back from today task completions remain editable (Phase 3 D2).
/// `0` = today only, `1` = today only too (semantic: editable when
/// `today.daysSince(activeDay) < kMaxEditableDays`). Phase 3 sets this to 2
/// → today + yesterday editable; older days remain read-only.
const kMaxEditableDays = 2;

class ActiveDayNotifier extends Notifier<DayKey> {
  @override
  DayKey build() => DayKey.today();

  DayKey get _today => DayKey.today();

  void goToPreviousDay() {
    final next = state.previousDay();
    if (next.daysSince(_today) < -kMaxHistoryDays) {
      return;
    }
    state = next;
  }

  void goToNextDay() {
    final next = state.nextDay();
    if (next.compareTo(_today) > 0) {
      return;
    }
    state = next;
  }

  void goToToday() {
    state = _today;
  }

  void goToDay(DayKey day) {
    if (day.compareTo(_today) > 0) {
      return;
    }
    if (day.daysSince(_today) < -kMaxHistoryDays) {
      return;
    }
    state = day;
  }

  /// When the calendar rolls past local midnight, move off "yesterday's today"
  /// only if the user was still on that calendar day.
  void onCalendarDayAdvanced(DayKey newToday) {
    final previousCalendarToday = newToday.previousDay();
    if (state == previousCalendarToday) {
      state = newToday;
    }
  }
}

final activeDayProvider = NotifierProvider<ActiveDayNotifier, DayKey>(
  ActiveDayNotifier.new,
);
