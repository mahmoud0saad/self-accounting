import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customization/presentation/providers/catalog_providers.dart';
import '../../../customization/presentation/widgets/icon_picker_grid.dart';
import '../../data/challenge_repository.dart';
import '../providers/challenge_providers.dart';

enum _SourceTab { task, category }

Future<void> showCustomChallengeSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCreated,
}) async {
  final l = AppLocalizations.of(context)!;
  final catalog = ref.read(effectiveCatalogProvider).asData?.value;
  if (catalog == null ||
      (catalog.tasks.isEmpty && catalog.categories.isEmpty)) {
    return;
  }

  final titleCtrl = TextEditingController();
  final goalCtrl = TextEditingController(text: '7');
  var icon = 'star';
  var tab = _SourceTab.task;
  var taskId = catalog.tasks.isNotEmpty ? catalog.tasks.first.id : '';
  var categoryKey =
      catalog.categories.isNotEmpty ? catalog.categories.first.key : '';

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
                SegmentedButton<_SourceTab>(
                  segments: [
                    ButtonSegment(
                      value: _SourceTab.task,
                      label: Text(l.challengeSourceTabTask),
                    ),
                    ButtonSegment(
                      value: _SourceTab.category,
                      label: Text(l.challengeSourceTabCategory),
                    ),
                  ],
                  selected: {tab},
                  onSelectionChanged: (s) =>
                      setSheetState(() => tab = s.first),
                ),
                const SizedBox(height: 8),
                if (tab == _SourceTab.task)
                  DropdownButtonFormField<String>(
                    initialValue: taskId.isEmpty ? null : taskId,
                    items: [
                      for (final t in catalog.tasks)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(t.displayName),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => taskId = v);
                      }
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: categoryKey.isEmpty ? null : categoryKey,
                    items: [
                      for (final c in catalog.categories)
                        DropdownMenuItem(
                          value: c.key,
                          child: Text(c.displayName),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => categoryKey = v);
                      }
                    },
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
                          final kind = tab == _SourceTab.task
                              ? 'TASK_WEEKLY_COUNT'
                              : 'CATEGORY_WEEKLY_COUNT';
                          final refId =
                              tab == _SourceTab.task ? taskId : categoryKey;
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
