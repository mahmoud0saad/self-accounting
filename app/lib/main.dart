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
import 'features/checklist/presentation/providers/checklist_repositories_provider.dart';

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
      routerConfig: appRouter,
    );
  }
}
