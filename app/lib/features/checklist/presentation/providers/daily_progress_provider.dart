import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_progress.dart';
import 'checklist_state_provider.dart';
import 'task_catalog_provider.dart';

final dailyProgressProvider = Provider<DailyProgress>((ref) {
  final tasks = ref.watch(taskCatalogProvider);
  final checklist = ref.watch(checklistStateProvider);
  return DailyProgress.from(tasks, checklist);
});
