import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_providers.dart';

const _amber = Color(0xFFC98E1A);

Future<void> showRemovePermanentlySheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l,
  required bool isCategory,
  required String id,
  required int logCount,
  required VoidCallback onHideInstead,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final hasHistory = logCount > 0;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.manageChecklistRemovePermanently,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              hasHistory
                  ? l.manageChecklistRemoveHasHistory
                  : l.manageChecklistRemoveConfirmBody,
            ),
            const SizedBox(height: 20),
            if (hasHistory)
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onHideInstead();
                },
                child: Text(l.manageChecklistHide),
              )
            else ...[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.manageChecklistCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _amber),
                onPressed: () async {
                  final repo = ref.read(catalogRepositoryProvider);
                  if (isCategory) {
                    await repo.deleteUserCategory(id);
                  } else {
                    await repo.deleteUserTask(id);
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: Text(l.manageChecklistRemovePermanently),
              ),
            ],
          ],
        ),
      );
    },
  );
}
