import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/checklist/data/remote_log_repository.dart';
import '../../features/checklist/data/remote_task_repository.dart';
import '../db/app_database_provider.dart';
import 'dio_provider.dart';

final remoteLogRepositoryProvider = Provider<RemoteLogRepository>((ref) {
  return RemoteLogRepository(ref.watch(dioProvider));
});

final remoteTaskRepositoryProvider = Provider<RemoteTaskRepository>((ref) {
  return RemoteTaskRepository(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
  );
});
