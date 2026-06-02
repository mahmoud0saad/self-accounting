import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../checklist/presentation/providers/checklist_repositories_provider.dart';
import '../../checklist/presentation/providers/task_catalog_provider.dart';
import '../../settings/data/app_settings_repository.dart';
import '../notification_scheduler.dart';
import 'app_localizations_provider.dart';
import 'notification_service_provider.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler?>((ref) {
  final localizations = ref.watch(appLocalizationsProvider);
  if (localizations == null) {
    return null;
  }
  return NotificationScheduler(
    service: ref.watch(notificationServiceProvider),
    appSettingsRepository: ref.watch(appSettingsRepositoryProvider),
    checklistRepository: ref.watch(checklistRepositoryProvider),
    taskCatalog: ref.watch(taskCatalogProvider).value ?? const [],
    localizations: localizations,
  );
});
