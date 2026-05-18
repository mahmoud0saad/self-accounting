import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/remote_providers.dart';
import '../../../../core/db/app_database_provider.dart';
import '../../../../core/time/day_key.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../settings/data/app_settings_repository.dart';
import '../../data/merge_service.dart';
import '../../data/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    logs: ref.watch(remoteLogRepositoryProvider),
    isSignedIn: () => ref.read(authStateProvider).isSignedIn,
  );
});

final mergeServiceProvider = Provider<MergeService>((ref) {
  return MergeService(
    ref.watch(appDatabaseProvider),
    ref.watch(remoteLogRepositoryProvider),
    ref.watch(appSettingsRepositoryProvider),
  );
});

final syncLifecycleProvider = Provider<SyncLifecycle>((ref) {
  return SyncLifecycle(ref);
});

class SyncLifecycle {
  SyncLifecycle(this._ref);

  final Ref _ref;

  Future<void> onSignedIn() async {
    final email = _ref.read(authStateProvider).email;
    if (email == null) {
      return;
    }

    _ref.read(syncServiceProvider).start();
    await _ref.read(mergeServiceProvider).mergeOnFirstSignIn(email);

    final remoteTasks = _ref.read(remoteTaskRepositoryProvider);
    try {
      await remoteTasks.fetchAndCache();
    } catch (_) {}

    final today = DayKey.today();
    final from = today.previousDay().previousDay();
    await _ref
        .read(mergeServiceProvider)
        .pullLogsIntoLocal(from: from, to: today);

    await _ref.read(syncServiceProvider).flush();
  }

  Future<void> onSignedOut() async {
    _ref.read(syncServiceProvider).stop();
  }
}
