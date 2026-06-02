import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../challenges/data/challenge_restore_service.dart';
import 'customization_restore_provider.dart';
import 'sync_api.dart';
import 'sync_service.dart';

/// First sign-in: push local logs, then restore catalog + challenges (spec order).
Future<int> runFirstSignInAccountSync(
  WidgetRef ref,
  BuildContext context, {
  required Future<bool> Function(
    bool hasCatalogSnapshot,
    bool hasChallengeSnapshot,
    int totalItems,
  ) confirmRestore,
}) async {
  final sync = ref.read(syncServiceProvider);
  final api = ref.read(syncApiProvider);
  final storage = ref.read(tokenStorageProvider);
  final userId = ref.read(authNotifierProvider).user!.id;

  final days = await sync.runFirstSignInMigrationIfNeeded();

  final catalogSnapshot = await api.fetchSnapshotState();
  final challengeSnapshot = await api.fetchChallengeSnapshotState();
  final catalogHas = catalogSnapshot['hasSnapshot'] as bool? ?? false;
  final challengeHas = challengeSnapshot['hasSnapshot'] as bool? ?? false;

  final catalogTotals = catalogSnapshot['totals'] as Map<String, dynamic>? ?? {};
  final challengeTotals =
      challengeSnapshot['totals'] as Map<String, dynamic>? ?? {};
  final totalItems = (catalogTotals['userCategories'] as int? ?? 0) +
      (catalogTotals['userTasks'] as int? ?? 0) +
      (catalogTotals['categoryOverrides'] as int? ?? 0) +
      (catalogTotals['taskOverrides'] as int? ?? 0) +
      (challengeTotals['userChallenges'] as int? ?? 0) +
      (challengeTotals['userChallengeWeeks'] as int? ?? 0);

  var restoreConfirmed = true;
  if (catalogHas || challengeHas) {
    restoreConfirmed = await confirmRestore(
      catalogHas,
      challengeHas,
      totalItems,
    );
    if (!restoreConfirmed) {
      if (catalogHas) {
        await storage.markCustomizationFirstSyncDone(userId);
      }
      if (challengeHas) {
        await storage.markChallengeFirstSyncDone(userId);
      }
    }
  }

  Future<bool> prompt(_) async => restoreConfirmed;

  await ref.read(customizationRestoreServiceProvider).restoreIfNeeded(
        confirmReplacePrompt: prompt,
      );
  await ref.read(challengeRestoreServiceProvider).restoreIfNeeded(
        confirmReplacePrompt: prompt,
      );

  await sync.syncNow();
  return days;
}
