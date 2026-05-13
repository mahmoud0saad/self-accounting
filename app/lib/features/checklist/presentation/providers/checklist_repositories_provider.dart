import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../../../core/time/day_key.dart';
import '../../data/checklist_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/task_repository.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return DriftChecklistRepository(ref.watch(appDatabaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

const kMaxHistoryDays = 30;

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
