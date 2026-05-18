import '../domain/task.dart';
import 'remote_task_repository.dart';
import 'task_repository.dart';

class CachingRemoteTaskRepository implements TaskRepository {
  CachingRemoteTaskRepository(this._local, this._remote);

  final TaskRepository _local;
  final RemoteTaskRepository _remote;

  @override
  Future<List<Task>> readAll() async {
    try {
      return await _remote.fetchAndCache();
    } catch (_) {
      return _local.readAll();
    }
  }
}
