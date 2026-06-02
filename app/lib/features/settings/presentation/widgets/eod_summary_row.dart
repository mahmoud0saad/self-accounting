import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/providers/notification_scheduler_provider.dart';
import '../../../notifications/providers/notification_service_provider.dart';
import '../../data/app_settings_repository.dart';
import '../../domain/eod_summary_settings.dart';

class EodSummaryRow extends ConsumerWidget {
  const EodSummaryRow({super.key, required this.settings});

  final EodSummarySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final time = TimeOfDay(hour: settings.hour, minute: settings.minute);
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(time);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(l.settingsEodToggleLabel),
          trailing: Switch(
            value: settings.enabled,
            onChanged: (value) => _setEnabled(ref, value),
          ),
        ),
        if (settings.enabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: ActionChip(
              label: Text(l.settingsEodTimeLabel(formatted)),
              onPressed: () => _pickTime(context, ref, time),
            ),
            subtitle: Text(l.settingsEodThresholdNote),
          ),
      ],
    );
  }

  Future<void> _setEnabled(WidgetRef ref, bool enabled) async {
    if (enabled) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await ref.read(appSettingsRepositoryProvider).setEodEnabled(enabled);
    if (enabled) {
      await ref.read(notificationSchedulerProvider)?.syncAll();
    } else {
      await ref.read(notificationServiceProvider).cancelAll();
    }
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
        .read(appSettingsRepositoryProvider)
        .setEodTime(picked.hour, picked.minute);
    await ref.read(notificationSchedulerProvider)?.syncAll();
  }
}
