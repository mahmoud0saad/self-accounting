import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/app_database.dart';
import 'core/db/app_database_provider.dart';
import 'core/i18n/launch_locale.dart';
import 'core/i18n/locale_provider.dart';
import 'core/time/midnight_ticker_provider.dart';
import 'core/routing/app_router.dart';
import 'features/checklist/data/settings_repository.dart';
import 'features/checklist/presentation/providers/calendar_today_provider.dart';
import 'features/checklist/presentation/providers/checklist_state_provider.dart';
import 'features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'features/checklist/presentation/providers/task_catalog_provider.dart';
import 'features/notifications/providers/app_localizations_provider.dart';
import 'features/notifications/providers/notification_scheduler_provider.dart';
import 'features/settings/presentation/providers/eod_settings_provider.dart';
import 'features/settings/presentation/providers/notification_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  await database.seedAndReconcile();

  final settingsRepo = DriftSettingsRepository(database);
  final code = await settingsRepo.readLocaleOverride();
  persistedLocaleAtLaunch = switch (code) {
    'ar' => const Locale('ar'),
    'en' => const Locale('en'),
    _ => null,
  };

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const MuhasabahAppRoot(),
    ),
  );
}

class MuhasabahAppRoot extends ConsumerStatefulWidget {
  const MuhasabahAppRoot({super.key});

  @override
  ConsumerState<MuhasabahAppRoot> createState() => _MuhasabahAppRootState();
}

class _MuhasabahAppRootState extends ConsumerState<MuhasabahAppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(midnightTickerServiceProvider).start((newToday) {
        // Phase 3: rebase the wall-clock today anchor *first* so the history
        // strip + streak window providers see the new today before the active
        // day shifts (D15).
        ref.read(calendarTodayProvider.notifier).rebase(newToday);
        ref.read(activeDayProvider.notifier).onCalendarDayAdvanced(newToday);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MuhasabahApp();
  }
}

class MuhasabahApp extends ConsumerWidget {
  const MuhasabahApp({super.key});

  static const Color _seedColor = Color(0xFF4C9A6E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeOverride = ref.watch(localeProvider);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          _NotificationStartup(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _NotificationStartup extends ConsumerWidget {
  const _NotificationStartup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appLocalizationsProvider.notifier).set(localizations);
        ref.read(notificationSchedulerProvider)?.syncAll();
      });
    }

    void syncOnChange(Object? _, Object? __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationSchedulerProvider)?.syncAll();
      });
    }

    ref.listen(categorySchedulesProvider, syncOnChange);
    ref.listen(taskTogglesProvider, syncOnChange);
    ref.listen(eodSettingsProvider, syncOnChange);
    ref.listen(notificationsEnabledProvider, syncOnChange);
    ref.listen(checklistStateProvider, syncOnChange);
    ref.listen(taskCatalogProvider, syncOnChange);

    return child;
  }
}
