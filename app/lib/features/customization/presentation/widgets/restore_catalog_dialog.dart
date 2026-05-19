import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool> showRestoreCatalogDialog(
  BuildContext context,
  AppLocalizations l,
  int totalItems,
) async {
  return showAccountRestoreDialog(
    context,
    l,
    hasCatalogSnapshot: true,
    hasChallengeSnapshot: false,
    totalItems: totalItems,
  );
}

Future<bool> showAccountRestoreDialog(
  BuildContext context,
  AppLocalizations l, {
  required bool hasCatalogSnapshot,
  required bool hasChallengeSnapshot,
  required int totalItems,
}) async {
  final String title;
  final String body;
  if (hasCatalogSnapshot && hasChallengeSnapshot) {
    title = l.restoreUnifiedDialogTitle;
    body = l.restoreUnifiedDialogBody;
  } else if (hasCatalogSnapshot) {
    title = l.restoreCatalogDialogTitle;
    body = l.restoreCatalogDialogBody;
  } else {
    title = l.restoreChallengesDialogTitle;
    body = l.restoreChallengesDialogBody;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
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
