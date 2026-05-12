import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/task.dart';
import '../providers/checklist_state_provider.dart';
import 'task_row.dart';

String _categoryTitle(AppLocalizations l, TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => l.categoryFajr,
    TaskCategory.dhuhr => l.categoryDhuhr,
    TaskCategory.asr => l.categoryAsr,
    TaskCategory.maghrib => l.categoryMaghrib,
    TaskCategory.isha => l.categoryIsha,
    TaskCategory.qiyamEvening => l.categoryQiyamEvening,
    TaskCategory.quranFasting => l.categoryQuranFasting,
    TaskCategory.miscAdhkar => l.categoryMiscAdhkar,
  };
}

IconData _categoryIcon(TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => Icons.wb_twilight_rounded,
    TaskCategory.dhuhr => Icons.wb_sunny_rounded,
    TaskCategory.asr => Icons.brightness_5_rounded,
    TaskCategory.maghrib => Icons.brightness_4_rounded,
    TaskCategory.isha => Icons.nights_stay_rounded,
    TaskCategory.qiyamEvening => Icons.bedtime_rounded,
    TaskCategory.quranFasting => Icons.menu_book_rounded,
    TaskCategory.miscAdhkar => Icons.auto_awesome_rounded,
  };
}

class CategorySection extends ConsumerWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.tasks,
  });

  final TaskCategory category;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final state = ref.watch(checklistStateProvider);
    final totalPts = tasks.fold<int>(0, (s, t) => s + t.points);
    final doneTasks = tasks.where((t) => state[t.id] == true).length;
    final donePts = tasks
        .where((t) => state[t.id] == true)
        .fold<int>(0, (s, t) => s + t.points);
    final allDone = doneTasks == tasks.length && tasks.isNotEmpty;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: allDone
                      ? scheme.primary
                      : scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  allDone ? Icons.check_rounded : _categoryIcon(category),
                  color: allDone ? scheme.onPrimary : scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _categoryTitle(l, category),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CategoryStatPill(
                doneTasks: doneTasks,
                totalTasks: tasks.length,
                donePts: donePts,
                totalPts: totalPts,
                pointsLabel: l.pointsLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < tasks.length; i++) ...[
                    TaskRow(task: tasks[i]),
                    if (i != tasks.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 12,
                        endIndent: 12,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStatPill extends StatelessWidget {
  const _CategoryStatPill({
    required this.doneTasks,
    required this.totalTasks,
    required this.donePts,
    required this.totalPts,
    required this.pointsLabel,
  });

  final int doneTasks;
  final int totalTasks;
  final int donePts;
  final int totalPts;
  final String pointsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final filled = doneTasks == totalTasks && totalTasks > 0;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: filled
            ? scheme.primary.withValues(alpha: 0.15)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$donePts/$totalPts $pointsLabel',
        style: text.labelSmall?.copyWith(
          color: filled ? scheme.primary : scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
