import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../checklist/domain/task.dart';
import '../../checklist/presentation/providers/task_catalog_provider.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/providers/app_localizations_provider.dart';
import '../../notifications/providers/notification_scheduler_provider.dart';
import '../../notifications/providers/notification_service_provider.dart';
import '../data/app_settings_repository.dart';
import '../domain/category_notification_schedule.dart';
import '../domain/eod_summary_settings.dart';
import '../domain/task_notification_toggle.dart';
import 'providers/eod_settings_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'widgets/category_schedule_tile.dart';
import 'widgets/eod_summary_row.dart';
import 'widgets/settings_section_card.dart';

final notificationPermissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>((ref) {
      return ref.watch(notificationServiceProvider).permissionStatus();
    });

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLocalizationsProvider.notifier).set(l);
    });

    final schedules = ref.watch(categorySchedulesProvider);
    final toggles = ref.watch(taskTogglesProvider);
    final eod = ref.watch(eodSettingsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final tasks = ref.watch(taskCatalogProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text(l.settingsTitle), pinned: true),
          SliverToBoxAdapter(
            child: SettingsSectionCard(
              title: l.settingsNotificationsTitle,
              child: _notificationsBody(
                context,
                ref,
                l,
                schedules,
                toggles,
                eod,
                notificationsEnabled,
                tasks,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _AboutSection(l: l)),
          SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
        ],
      ),
    );
  }

  Widget _notificationsBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    AsyncValue<List<CategoryNotificationSchedule>> schedules,
    AsyncValue<List<TaskNotificationToggle>> toggles,
    AsyncValue<EodSummarySettings> eod,
    AsyncValue<bool> notificationsEnabled,
    AsyncValue<List<Task>> tasks,
  ) {
    final hasError = [
      schedules,
      toggles,
      eod,
      notificationsEnabled,
      tasks,
    ].where((value) => value.hasError).firstOrNull;
    if (hasError != null) {
      return Text('${hasError.error}');
    }
    if ([
      schedules,
      toggles,
      eod,
      notificationsEnabled,
      tasks,
    ].any((value) => value.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }

    final scheduleRows = ref.watch(categorySchedulesProvider).requireValue;
    final toggleRows = ref.watch(taskTogglesProvider).requireValue;
    final eodSettings = ref.watch(eodSettingsProvider).requireValue;
    final globalEnabled = ref.watch(notificationsEnabledProvider).requireValue;
    final taskRows = ref.watch(taskCatalogProvider).requireValue;
    final grouped = _groupByCategory(taskRows);

    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.settingsNotificationsGlobalToggleLabel),
          value: globalEnabled,
          onChanged: (value) async {
            await ref
                .read(appSettingsRepositoryProvider)
                .setNotificationsEnabled(value);
            if (value) {
              await ref.read(notificationSchedulerProvider)?.syncAll();
            } else {
              await ref.read(notificationServiceProvider).cancelAll();
            }
          },
        ),
        if (kIsWeb) _WebNotificationBanner(l: l),
        EodSummaryRow(settings: eodSettings),
        for (final schedule in scheduleRows)
          CategoryScheduleTile(
            schedule: schedule,
            tasks: grouped[schedule.category] ?? const <Task>[],
            toggles: toggleRows,
          ),
      ],
    );
  }
}

Map<TaskCategory, List<Task>> _groupByCategory(List<Task> tasks) {
  final map = <TaskCategory, List<Task>>{};
  for (final task in tasks) {
    map.putIfAbsent(task.category, () => <Task>[]).add(task);
  }
  return map;
}

class _WebNotificationBanner extends ConsumerWidget {
  const _WebNotificationBanner({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationPermissionStatusProvider).value;
    final children = <Widget>[_InfoBanner(text: l.settingsWebNotificationNote)];
    if (status == NotificationPermissionStatus.denied) {
      children.add(
        const _InfoBanner(text: 'Notifications blocked in browser settings'),
      );
    }
    return Column(children: children);
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: l.settingsAboutTitle,
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
              : '...';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l.settingsVersionLabel(version)),
          );
        },
      ),
    );
  }
}
