import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import '../domain/task.dart';
import 'static_task_catalog.dart';
import 'task_repository.dart';

class RemoteTaskRepository {
  RemoteTaskRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  static final Map<String, Task> _catalogById = {
    for (final t in staticTaskCatalog) t.id: t,
  };

  Future<List<Task>> fetchAndCache() async {
    final response = await _dio.get<List<dynamic>>('/tasks');
    final rows = response.data ?? [];
    await _db.transaction(() async {
      var index = 0;
      for (final raw in rows) {
        final json = raw as Map<String, dynamic>;
        final id = json['id'] as String;
        final domain = _catalogById[id];
        if (domain == null) {
          continue;
        }
        await _db.into(_db.tasks).insertOnConflictUpdate(
          TasksCompanion.insert(
            id: id,
            points: (json['points'] as num).toInt(),
            category: json['category'] as String,
            sortOrder: index,
          ),
        );
        index++;
      }
    });
    return DriftTaskRepository(_db).readAll();
  }
}
