import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../checklist/domain/task.dart';
import '../../data/notification_settings_repository.dart';
import '../../domain/category_notification_schedule.dart';
import '../../domain/task_notification_toggle.dart';
import 'task_notif_toggle_tile.dart';

class CategoryScheduleTile extends ConsumerWidget {
  const CategoryScheduleTile({
    super.key,
    required this.schedule,
    required this.tasks,
    required this.toggles,
  });

  final CategoryNotificationSchedule schedule;
  final List<Task> tasks;
  final List<TaskNotificationToggle> toggles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final categoryName = _categoryLabel(l, schedule.category);
    final time = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(time);
    final allMuted = tasks.every((task) => !_isEnabled(task.id));

    return Semantics(
      label:
          '$categoryName, ${schedule.enabled ? l.taskStateChecked : l.taskStateUnchecked}',
      child: ExpansionTile(
        leading: Icon(_categoryIcon(schedule.category)),
        title: Text(categoryName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionChip(
              label: Text(
                l.settingsCategoryScheduleTimeLabel(categoryName, formatted),
              ),
              onPressed: () => _pickTime(context, ref, time),
            ),
            const SizedBox(width: 8),
            Switch(
              value: schedule.enabled,
              onChanged: (value) => ref
                  .read(notificationSettingsRepositoryProvider)
                  .setCategoryEnabled(schedule.category, value),
            ),
          ],
        ),
        children: [
          if (allMuted)
            ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('All tasks muted'),
            ),
          for (final task in tasks)
            TaskNotifToggleTile(task: task, enabled: _isEnabled(task.id)),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initial,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) {
      return;
    }
    await ref
        .read(notificationSettingsRepositoryProvider)
        .setCategoryTime(schedule.category, picked.hour, picked.minute);
  }

  bool _isEnabled(String taskId) {
    return toggles
        .firstWhere(
          (toggle) => toggle.taskId == taskId,
          orElse: () => TaskNotificationToggle(
            taskId: taskId,
            notificationsEnabled: true,
          ),
        )
        .notificationsEnabled;
  }
}

String _categoryLabel(AppLocalizations l, TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => l.categoryNameFajr,
    TaskCategory.dhuhr => l.categoryNameDhuhr,
    TaskCategory.asr => l.categoryNameAsr,
    TaskCategory.maghrib => l.categoryNameMaghrib,
    TaskCategory.isha => l.categoryNameIsha,
    TaskCategory.qiyamEvening => l.categoryNameQiyamEvening,
    TaskCategory.quranFasting => l.categoryNameQuranFasting,
    TaskCategory.miscAdhkar => l.categoryNameMiscAdhkar,
  };
}

IconData _categoryIcon(TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => Icons.wb_twilight_rounded,
    TaskCategory.dhuhr => Icons.wb_sunny_rounded,
    TaskCategory.asr => Icons.sunny_snowing,
    TaskCategory.maghrib => Icons.nights_stay_rounded,
    TaskCategory.isha => Icons.dark_mode_rounded,
    TaskCategory.qiyamEvening => Icons.auto_awesome_rounded,
    TaskCategory.quranFasting => Icons.menu_book_rounded,
    TaskCategory.miscAdhkar => Icons.spa_rounded,
  };
}
