import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocalizationsNotifier extends Notifier<AppLocalizations?> {
  @override
  AppLocalizations? build() => null;

  void set(AppLocalizations localizations) {
    state = localizations;
  }
}

final appLocalizationsProvider =
    NotifierProvider<AppLocalizationsNotifier, AppLocalizations?>(
      AppLocalizationsNotifier.new,
    );
