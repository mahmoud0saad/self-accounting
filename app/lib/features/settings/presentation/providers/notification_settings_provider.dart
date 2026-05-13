import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_settings_repository.dart';
import '../../domain/category_notification_schedule.dart';
import '../../domain/task_notification_toggle.dart';

final categorySchedulesProvider =
    StreamProvider<List<CategoryNotificationSchedule>>((ref) {
      return ref
          .watch(notificationSettingsRepositoryProvider)
          .watchCategorySchedules();
    });

final taskTogglesProvider = StreamProvider<List<TaskNotificationToggle>>((ref) {
  return ref.watch(notificationSettingsRepositoryProvider).watchTaskToggles();
});
