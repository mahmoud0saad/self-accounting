import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import 'checklist_repositories_provider.dart';

final checklistStateProvider = StreamProvider.autoDispose<Map<String, bool>>((
  ref,
) {
  final day = ref.watch(activeDayProvider);
  return ref.watch(checklistRepositoryProvider).watchDay(day);
});

final checklistControllerProvider = Provider<ChecklistController>((ref) {
  return ChecklistController(ref);
});

class ChecklistController {
  ChecklistController(this._ref);

  final Ref _ref;

  bool _isEditable(DayKey day) {
    final daysAgo = DayKey.today().daysSince(day);
    return daysAgo >= 0 && daysAgo < kMaxEditableDays;
  }

  Future<void> toggle(String taskId) async {
    final day = _ref.read(activeDayProvider);
    if (!_isEditable(day)) {
      return;
    }
    final cached = _ref.read(checklistStateProvider).maybeWhen(
          data: (m) => m,
          orElse: () => const <String, bool>{},
        );
    final next = !(cached[taskId] ?? false);
    await _ref.read(checklistRepositoryProvider).setCompletion(
          day: day,
          taskId: taskId,
          completed: next,
        );
  }

  /// Wipes completions for the currently active day. No-op when the active
  /// day is outside the [kMaxEditableDays] window.
  Future<void> resetActiveDay() async {
    final day = _ref.read(activeDayProvider);
    if (!_isEditable(day)) {
      return;
    }
    await _ref.read(checklistRepositoryProvider).resetDay(day);
  }

  /// Phase 2 callers (e.g., tests) may still reference the old name; route
  /// through [resetActiveDay] so the guard widens transparently.
  Future<void> resetToday() => resetActiveDay();
}
