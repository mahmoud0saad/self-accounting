import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database_provider.dart';
import '../../auth/data/token_storage.dart';
import '../../settings/data/app_settings_repository.dart';
import 'customization_restore_service.dart';
import 'sync_api.dart';
import 'sync_service.dart';

export 'customization_restore_service.dart'
    show CustomizationRestoreEvent, CustomizationRestoreState;

/// Mutable confirm callback; sign-in sets this before [CustomizationRestoreService.restoreIfNeeded].
class CustomizationRestoreConfirm {
  Future<bool> Function(int totalItems) call = (_) async => true;
}

final customizationRestoreConfirmProvider =
    Provider<CustomizationRestoreConfirm>((ref) {
  return CustomizationRestoreConfirm();
});

final customizationRestoreServiceProvider =
    Provider<CustomizationRestoreService>((ref) {
  final service = CustomizationRestoreService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(syncApiProvider),
    storage: ref.read(tokenStorageProvider),
    settings: ref.read(appSettingsRepositoryProvider),
    ref: ref,
    drainOutbound: () => ref.read(syncServiceProvider).drainOutbound(),
  );
  ref.onDispose(service.dispose);
  return service;
});
