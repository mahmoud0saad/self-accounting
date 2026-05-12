import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void setLocale(Locale? locale) {
    state = locale;
  }

  /// Cycles: system (`null`) → English → Arabic → system.
  void toggle() {
    final current = state;
    if (current == null) {
      state = const Locale('en');
    } else if (current.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = null;
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
