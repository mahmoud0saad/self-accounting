import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'launch_locale.dart';
import 'locale_provider.dart';

/// AppBar action: cycles Arabic → English → Arabic.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = resolveAppLocale(ref.watch(localeProvider));
    final label = locale.languageCode == 'ar' ? 'ع' : 'EN';

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Tooltip(
        message: l.languageToggleTooltip,
        child: TextButton(
          onPressed: () => ref.read(localeProvider.notifier).toggle(),
          child: Text(label),
        ),
      ),
    );
  }
}
