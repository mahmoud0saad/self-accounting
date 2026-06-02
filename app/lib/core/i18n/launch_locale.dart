import 'dart:ui' show Locale;

/// App language when the user has not chosen one in settings.
const Locale defaultAppLocale = Locale('ar');

/// Locale read from settings before [runApp]; consumed once by [LocaleNotifier].
/// `null` means no saved preference (use [defaultAppLocale]).
Locale? persistedLocaleAtLaunch;

Locale resolveAppLocale([Locale? override]) => override ?? defaultAppLocale;

const String localeOverrideSettingsKey = 'app.locale.override';
