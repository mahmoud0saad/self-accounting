import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customization/presentation/providers/catalog_providers.dart';
import '../../../customization/presentation/widgets/icon_picker_grid.dart';
import '../../data/challenge_repository.dart';
import '../providers/challenge_providers.dart';
import 'challenge_source_picker.dart';

Future<void> showCustomChallengeSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCreated,
}) async {
  final l = AppLocalizations.of(context)!;
  final catalog = ref.read(effectiveCatalogProvider).asData?.value;
  if (catalog == null || catalog.tasks.isEmpty) {
    return;
  }

  final titleCtrl = TextEditingController();
  final goalCtrl = TextEditingController(text: '7');
  var icon = 'star';
  var taskId = defaultTaskId(catalog);

  int? parsedGoal() {
    final n = int.tryParse(goalCtrl.text.trim());
    if (n == null || n < 1) {
      return null;
    }
    return n;
  }

  String goalHint(int days) => days > 7
      ? l.challengeGoalDaysCumulativeLabel(days)
      : l.challengeGoalDaysLabel(days);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final goal = parsedGoal();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.challengeCreateCustom,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: l.challengeCustomTitleLabel,
                    counterText: '',
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  l.challengeCustomIconLabel,
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                IconPickerGrid(
                  selected: icon,
                  onSelected: (v) => setSheetState(() => icon = v),
                ),
                const SizedBox(height: 12),
                Text(
                  l.challengeCustomSourceLabel,
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ChallengeSourcePicker(
                  catalog: catalog,
                  l: l,
                  selectedTaskId: taskId,
                  onSelected: (id) => setSheetState(() => taskId = id),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l.challengeCustomGoalLabel,
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                if (goal != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    goalHint(goal),
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: titleCtrl.text.trim().length < 2 || goal == null
                      ? null
                      : () async {
                          final name = titleCtrl.text.trim();
                          final (kind, refId) = challengeSourceFields(taskId);
                          await ref
                              .read(challengeRepositoryProvider)
                              .createCustom(
                                title: name,
                                icon: icon,
                                sourceKind: kind,
                                sourceRef: refId,
                                goalCount: goal,
                              );
                          ref.invalidate(activeUserChallengesProvider);
                          ref.invalidate(currentWeekProgressProvider);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            onCreated?.call();
                          }
                        },
                  child: Text(l.challengeCustomCreate),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
