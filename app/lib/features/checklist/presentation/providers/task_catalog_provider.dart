import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/static_task_catalog.dart';
import '../../domain/task.dart';
import 'checklist_repositories_provider.dart';

final taskCatalogProvider = FutureProvider<List<Task>>((ref) async {
  assert(() {
    final sum = staticTaskCatalog.fold<int>(0, (s, t) => s + t.points);
    return sum == 74;
  }(), 'Catalog must sum to 74 points');
  return ref.watch(taskRepositoryProvider).readAll();
});
