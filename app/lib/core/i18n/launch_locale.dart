import 'dart:ui' show Locale;

/// Locale read from settings before [runApp]; consumed once by [LocaleNotifier].
Locale? persistedLocaleAtLaunch;

const String localeOverrideSettingsKey = 'app.locale.override';
