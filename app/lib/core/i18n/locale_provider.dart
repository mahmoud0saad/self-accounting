import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'launch_locale.dart';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => persistedLocaleAtLaunch;

  Future<void> setLocale(Locale locale) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.writeLocaleOverride(locale.languageCode);
    state = locale;
  }

  /// Cycles: Arabic → English → Arabic.
  Future<void> toggle() async {
    final current = resolveAppLocale(state);
    if (current.languageCode == 'ar') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ar'));
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
