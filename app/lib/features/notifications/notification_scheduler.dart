import 'package:app/l10n/app_localizations.dart';

import '../../core/time/day_key.dart';
import '../checklist/data/checklist_repository.dart';
import '../checklist/domain/task.dart';
import '../settings/data/app_settings_repository.dart';
import '../settings/domain/eod_summary_settings.dart';
import 'notification_service.dart';

class NotificationScheduler {
  const NotificationScheduler({
    required NotificationService service,
    required AppSettingsRepository appSettingsRepository,
    required ChecklistRepository checklistRepository,
    required List<Task> taskCatalog,
    required AppLocalizations localizations,
  }) : _service = service,
       _appSettingsRepository = appSettingsRepository,
       _checklistRepository = checklistRepository,
       _taskCatalog = taskCatalog,
       _l = localizations;

  static const int _eodNotificationId = 200;

  final NotificationService _service;
  final AppSettingsRepository _appSettingsRepository;
  final ChecklistRepository _checklistRepository;
  final List<Task> _taskCatalog;
  final AppLocalizations _l;

  Future<void> syncAll() async {
    await _service.cancelAll();
    final eod = await _appSettingsRepository.watchEodSettings().first;
    if (!eod.enabled || _taskCatalog.isEmpty) {
      return;
    }

    final percent = await _completionPercent();
    if (percent >= EodSummarySettings.thresholdPercent) {
      return;
    }

    await _service.scheduleDaily(
      id: _eodNotificationId,
      title: _l.settingsEodToggleLabel,
      body: _l.notifEodBody(percent),
      hour: eod.hour,
      minute: eod.minute,
    );
  }

  Future<int> _completionPercent() async {
    final completions = await _checklistRepository.readDay(DayKey.today());
    final completed = _taskCatalog
        .where((task) => completions[task.id] ?? false)
        .length;
    return ((completed / _taskCatalog.length) * 100).round();
  }
}
