import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool> showRestoreCatalogDialog(
  BuildContext context,
  AppLocalizations l,
  int totalItems,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l.restoreCatalogDialogTitle),
      content: Text(l.restoreCatalogDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.manageChecklistCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.restoreCatalogDialogRestore),
        ),
      ],
    ),
  );
  return result ?? false;
}
