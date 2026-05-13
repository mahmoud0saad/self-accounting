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

  Future<void> toggle(String taskId) async {
    final day = _ref.read(activeDayProvider);
    if (day != DayKey.today()) {
      return;
    }
    final repo = _ref.read(checklistRepositoryProvider);
    final current = await repo.readDay(day);
    final next = !(current[taskId] ?? false);
    await repo.setCompletion(day: day, taskId: taskId, completed: next);
  }

  Future<void> resetToday() async {
    final today = DayKey.today();
    await _ref.read(checklistRepositoryProvider).resetDay(today);
  }
}
