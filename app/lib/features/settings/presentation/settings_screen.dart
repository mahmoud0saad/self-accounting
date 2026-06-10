import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/api/server_availability_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../customization/presentation/widgets/restore_catalog_dialog.dart';
import '../../sync/data/customization_restore_provider.dart';
import '../../challenges/domain/week_boundary.dart';
import '../../challenges/presentation/providers/challenge_providers.dart';
import '../../sync/data/sync_service.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/providers/app_localizations_provider.dart';
import '../../notifications/providers/notification_service_provider.dart';
import '../../auth/data/token_storage.dart';
import '../data/app_settings_repository.dart';
import '../domain/eod_summary_settings.dart';
import 'providers/eod_settings_provider.dart';
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

    final eod = ref.watch(eodSettingsProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final auth = ref.watch(authNotifierProvider);
    final serverAvailable = ref.watch(serverAvailableProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text(l.settingsTitle), pinned: true),
          SliverToBoxAdapter(
            child: SettingsSectionCard(
              title: l.settingsChallengesTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsChallengesManage),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/challenges'),
                  ),
                  // const Divider(height: 24),
                  // Text(
                  //   l.challengeWeekStartTitle,
                  //   style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  // ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   l.challengeWeekStartSubtitle,
                  //   style: Theme.of(context).textTheme.bodySmall,
                  // ),
                  // const SizedBox(height: 8),
                  // const _WeekStartSettings(),
                ],
              ),
            ),
          ),
          if (serverAvailable &&
              auth.status == AuthStatus.authenticated &&
              auth.user?.isEmailConfirmed == true)
            SliverToBoxAdapter(
              child: SettingsSectionCard(
                title: l.settingsAccountTitle,
                child: Column(
                  children: [
                    _RestoreCatalogTile(l: l),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.settingsSyncNow),
                      trailing: const Icon(Icons.sync_rounded),
                      onTap: () async {
                        await ref.read(syncServiceProvider).syncNow();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.settingsSyncDone)),
                          );
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.authSignOut,
                        style: TextStyle(
                          color: const Color(0xFFC98E1A),
                        ),
                      ),
                      onTap: () => _confirmSignOut(context, ref, l),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SettingsSectionCard(
              title: l.manageChecklistTitle,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.manageChecklistMenu),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/manage'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSectionCard(
              title: l.settingsNotificationsTitle,
              child: _notificationsBody(context, ref, l, eod),
            ),
          ),
          SliverToBoxAdapter(child: _AboutSection(l: l)),
          SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
        ],
      ),
    );
  }

  static Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.authSignOut),
        content: Text(l.authSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.authSignOutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.authSignOut,
              style: const TextStyle(color: Color(0xFFC98E1A)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  Widget _notificationsBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    AsyncValue<EodSummarySettings> eod,
  ) {
    return eod.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('$error'),
      data: (eodSettings) => Column(
        children: [
          if (kIsWeb) _WebNotificationBanner(l: l),
          EodSummaryRow(settings: eodSettings),
        ],
      ),
    );
  }
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

class _RestoreCatalogTile extends ConsumerWidget {
  const _RestoreCatalogTile({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsRepositoryProvider);
    return FutureBuilder<DateTime?>(
      future: settings.getCustomizationLastRestoredAt(),
      builder: (context, snapshot) {
        final at = snapshot.data;
        final subtitle = at == null
            ? l.settingsRestoreCatalogNever
            : l.settingsRestoreCatalogLast(_formatRelative(at, l));
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.settingsRestoreCatalogTitle),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.cloud_download_rounded),
          onTap: () => _onTap(context, ref),
        );
      },
    );
  }

  String _formatRelative(DateTime at, AppLocalizations l) {
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) {
      return 'today';
    }
    if (days == 1) {
      return '1 day ago';
    }
    return '$days days ago';
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) {
      return;
    }
    await ref.read(tokenStorageProvider).clearCustomizationFirstSyncFlag(user.id);
    ref.read(customizationRestoreConfirmProvider).call =
        (total) => showRestoreCatalogDialog(context, l, total);
    await ref.read(customizationRestoreServiceProvider).restoreIfNeeded(
          force: true,
          confirmReplacePrompt:
              ref.read(customizationRestoreConfirmProvider).call,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsSyncDone)),
      );
    }
  }
}

class _WeekStartSettings extends ConsumerWidget {
  const _WeekStartSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final dowAsync = ref.watch(weekStartDowProvider);

    return dowAsync.when(
      data: (current) => Column(
        children: [
          RadioListTile<WeekStartDow>(
            title: Text(l.challengeWeekStartSaturday),
            value: WeekStartDow.sat,
            groupValue: current,
            onChanged: (v) => _set(context, ref, l, v!),
          ),
          RadioListTile<WeekStartDow>(
            title: Text(l.challengeWeekStartSunday),
            value: WeekStartDow.sun,
            groupValue: current,
            onChanged: (v) => _set(context, ref, l, v!),
          ),
          RadioListTile<WeekStartDow>(
            title: Text(l.challengeWeekStartMonday),
            value: WeekStartDow.mon,
            groupValue: current,
            onChanged: (v) => _set(context, ref, l, v!),
          ),
        ],
      ),
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    WeekStartDow dow,
  ) async {
    await ref.read(weekStartDowProvider.notifier).set(dow);
    final label = switch (dow) {
      WeekStartDow.sat => l.challengeWeekStartSaturday,
      WeekStartDow.sun => l.challengeWeekStartSunday,
      WeekStartDow.mon => l.challengeWeekStartMonday,
    };
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.challengeWeekStartSnackbar(label))),
      );
    }
    ref.invalidate(currentWeekProgressProvider);
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
