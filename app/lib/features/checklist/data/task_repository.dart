import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/task.dart';
import 'static_task_catalog.dart';

abstract class TaskRepository {
  Future<List<Task>> readAll();
}

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  static final Map<String, Task> _catalogById = {
    for (final t in staticTaskCatalog) t.id: t,
  };

  @override
  Future<List<Task>> readAll() async {
    final rows = await (_db.select(
      _db.tasks,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    final out = <Task>[];
    for (final row in rows) {
      final domain = _catalogById[row.id];
      if (domain != null) {
        out.add(domain);
      }
    }
    return out;
  }
}
