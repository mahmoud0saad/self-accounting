import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../checklist/domain/task.dart';
import '../../data/notification_settings_repository.dart';

class TaskNotifToggleTile extends ConsumerWidget {
  const TaskNotifToggleTile({
    super.key,
    required this.task,
    required this.enabled,
  });

  final Task task;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final title = task.titleResolver(l);
    return Semantics(
      label: l.settingsTaskNotifToggleA11y(title),
      child: SwitchListTile(
        title: Text(title),
        value: enabled,
        onChanged: (value) => ref
            .read(notificationSettingsRepositoryProvider)
            .setTaskEnabled(task.id, value),
      ),
    );
  }
}
