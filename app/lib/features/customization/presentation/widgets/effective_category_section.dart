import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/curated_icon_data.dart';
import '../../../checklist/presentation/providers/checklist_state_provider.dart';
import '../../../checklist/presentation/widgets/effective_task_row.dart';
import '../../domain/catalog_models.dart';

class EffectiveCategorySection extends ConsumerWidget {
  const EffectiveCategorySection({
    super.key,
    required this.category,
    required this.tasks,
  });

  final EffectiveCategory category;
  final List<EffectiveTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final checklistAsync = ref.watch(checklistStateProvider);
    final state = checklistAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <String, bool>{},
    );

    final totalPts = tasks.fold<int>(0, (s, t) => s + t.points);
    final doneTasks = tasks.where((t) => state[t.id] == true).length;
    final donePts = tasks
        .where((t) => state[t.id] == true)
        .fold<int>(0, (s, t) => s + t.points);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                curatedIconData(category.icon),
                color: scheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (category.isFard)
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: scheme.outline,
                ),
              const SizedBox(width: 8),
              Text(
                '$donePts / $totalPts',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$doneTasks / ${tasks.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final task in tasks)
                EffectiveTaskRow(task: task),
            ],
          ),
        ],
      ),
    );
  }
}
