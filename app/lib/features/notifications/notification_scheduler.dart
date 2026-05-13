import 'package:app/l10n/app_localizations.dart';

import '../../core/time/day_key.dart';
import '../checklist/data/checklist_repository.dart';
import '../checklist/domain/task.dart';
import '../settings/data/app_settings_repository.dart';
import '../settings/data/notification_settings_repository.dart';
import '../settings/domain/eod_summary_settings.dart';
import '../settings/domain/task_notification_toggle.dart';
import 'notification_service.dart';

class NotificationScheduler {
  const NotificationScheduler({
    required NotificationService service,
    required NotificationSettingsRepository notificationSettingsRepository,
    required AppSettingsRepository appSettingsRepository,
    required ChecklistRepository checklistRepository,
    required List<Task> taskCatalog,
    required AppLocalizations localizations,
  }) : _service = service,
       _notificationSettingsRepository = notificationSettingsRepository,
       _appSettingsRepository = appSettingsRepository,
       _checklistRepository = checklistRepository,
       _taskCatalog = taskCatalog,
       _l = localizations;

  static const int _categoryNotificationBaseId = 100;
  static const int _eodNotificationId = 200;

  final NotificationService _service;
  final NotificationSettingsRepository _notificationSettingsRepository;
  final AppSettingsRepository _appSettingsRepository;
  final ChecklistRepository _checklistRepository;
  final List<Task> _taskCatalog;
  final AppLocalizations _l;

  Future<void> syncAll() async {
    await _service.cancelAll();
    final notificationsEnabled = await _appSettingsRepository
        .getNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }
    final categories = await _notificationSettingsRepository
        .watchCategorySchedules()
        .first;
    final toggles = await _notificationSettingsRepository
        .watchTaskToggles()
        .first;
    final eod = await _appSettingsRepository.watchEodSettings().first;

    for (final schedule in categories) {
      if (!schedule.enabled) {
        continue;
      }
      final body = _buildCategoryBody(schedule.category, toggles);
      if (body == null) {
        continue;
      }
      await _service.scheduleDaily(
        id:
            _categoryNotificationBaseId +
            TaskCategory.values.indexOf(schedule.category),
        title: _categoryLabel(schedule.category),
        body: body,
        hour: schedule.hour,
        minute: schedule.minute,
      );
    }

    final eodBody = await _buildEodBody(eod, toggles);
    if (eodBody != null) {
      await _service.scheduleDaily(
        id: _eodNotificationId,
        title: _l.settingsEodToggleLabel,
        body: eodBody,
        hour: eod.hour,
        minute: eod.minute,
      );
    }
  }

  String? _buildCategoryBody(
    TaskCategory category,
    List<TaskNotificationToggle> toggles,
  ) {
    final enabledTasks = _taskCatalog
        .where((task) => task.category == category)
        .where((task) => _isTaskNotificationEnabled(task.id, toggles))
        .toList(growable: false);
    if (enabledTasks.isEmpty) {
      return null;
    }
    if (enabledTasks.length <= 3) {
      return enabledTasks.map((task) => task.titleResolver(_l)).join(', ');
    }
    return _l.notifCategoryBody('${enabledTasks.length} tasks ready');
  }

  Future<String?> _buildEodBody(
    EodSummarySettings eod,
    List<TaskNotificationToggle> toggles,
  ) async {
    if (!eod.enabled) {
      return null;
    }
    final enabledTasks = _taskCatalog
        .where((task) => _isTaskNotificationEnabled(task.id, toggles))
        .toList(growable: false);
    if (enabledTasks.isEmpty) {
      return null;
    }

    final completions = await _checklistRepository.readDay(DayKey.today());
    final completed = enabledTasks
        .where((task) => completions[task.id] ?? false)
        .length;
    final percent = ((completed / enabledTasks.length) * 100).round();
    if (percent >= EodSummarySettings.thresholdPercent) {
      return null;
    }
    return _l.notifEodBody(percent);
  }

  bool _isTaskNotificationEnabled(
    String taskId,
    List<TaskNotificationToggle> toggles,
  ) {
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

  String _categoryLabel(TaskCategory category) {
    return switch (category) {
      TaskCategory.fajr => _l.categoryNameFajr,
      TaskCategory.dhuhr => _l.categoryNameDhuhr,
      TaskCategory.asr => _l.categoryNameAsr,
      TaskCategory.maghrib => _l.categoryNameMaghrib,
      TaskCategory.isha => _l.categoryNameIsha,
      TaskCategory.qiyamEvening => _l.categoryNameQiyamEvening,
      TaskCategory.quranFasting => _l.categoryNameQuranFasting,
      TaskCategory.miscAdhkar => _l.categoryNameMiscAdhkar,
    };
  }
}
