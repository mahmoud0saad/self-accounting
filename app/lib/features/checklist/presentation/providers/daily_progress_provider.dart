import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_progress.dart';
import '../../domain/task.dart';
import 'checklist_state_provider.dart';
import 'task_catalog_provider.dart';

final dailyProgressProvider = Provider<AsyncValue<DailyProgress>>((ref) {
  final tasks = ref.watch(taskCatalogProvider);
  final checklist = ref.watch(checklistStateProvider);
  return tasks.when(
    data: (List<Task> taskList) {
      return checklist.when(
        data: (map) => AsyncValue.data(DailyProgress.from(taskList, map)),
        loading: () => const AsyncValue<DailyProgress>.loading(),
        error: (e, s) => AsyncValue<DailyProgress>.error(e, s),
      );
    },
    loading: () => const AsyncValue<DailyProgress>.loading(),
    error: (e, s) => AsyncValue<DailyProgress>.error(e, s),
  );
});
