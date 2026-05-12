import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/static_task_catalog.dart';
import '../../domain/task.dart';

final taskCatalogProvider = Provider<List<Task>>((ref) {
  assert(() {
    final sum = staticTaskCatalog.fold<int>(0, (s, t) => s + t.points);
    return sum == 74;
  }(), 'Catalog must sum to 74 points');
  return staticTaskCatalog;
});
