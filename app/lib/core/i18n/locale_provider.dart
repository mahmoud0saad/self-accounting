import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'launch_locale.dart';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => persistedLocaleAtLaunch;

  Future<void> setLocale(Locale? locale) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.writeLocaleOverride(locale?.languageCode);
    state = locale;
  }

  /// Cycles: system (`null`) → English → Arabic → system.
  Future<void> toggle() async {
    final current = state;
    if (current == null) {
      await setLocale(const Locale('en'));
    } else if (current.languageCode == 'en') {
      await setLocale(const Locale('ar'));
    } else {
      await setLocale(null);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
