import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

/// AppBar action: cycles system → English → Arabic → system.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final localeOverride = ref.watch(localeProvider);
    final systemCode = View.of(context).platformDispatcher.locale.languageCode;
    final isArPreferred = systemCode.startsWith('ar');

    final String label;
    if (localeOverride == null) {
      label = isArPreferred ? 'ع' : 'EN';
    } else if (localeOverride.languageCode == 'ar') {
      label = 'ع';
    } else {
      label = 'EN';
    }

    final isAuto = localeOverride == null;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Tooltip(
        message: l.languageToggleTooltip,
        child: TextButton(
          onPressed: () => ref.read(localeProvider.notifier).toggle(),
          child: Text(
            isAuto ? '$label · ${l.languageAutoSuffix}' : label,
            style: TextStyle(
              decoration: isAuto ? TextDecoration.underline : null,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
      ),
    );
  }
}
