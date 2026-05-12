import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_catalog_provider.dart';

class ChecklistNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final tasks = ref.read(taskCatalogProvider);
    return {for (final t in tasks) t.id: false};
  }

  void toggle(String taskId) {
    final next = Map<String, bool>.from(state);
    next[taskId] = !(next[taskId] ?? false);
    state = next;
  }
}

final checklistStateProvider =
    NotifierProvider<ChecklistNotifier, Map<String, bool>>(
      ChecklistNotifier.new,
    );
