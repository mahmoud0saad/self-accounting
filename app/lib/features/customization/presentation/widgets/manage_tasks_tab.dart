import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/curated_icon_data.dart';
import '../../../checklist/domain/fard_anchor_set.dart';
import '../../domain/catalog_models.dart';
import '../providers/catalog_providers.dart';
import 'remove_permanently_sheet.dart';

class ManageTasksTab extends ConsumerWidget {
  const ManageTasksTab({
    super.key,
    required this.catalog,
    required this.l,
    required this.onAddTask,
    required this.onEditTask,
  });

  final EffectiveCatalog catalog;
  final AppLocalizations l;
  final VoidCallback onAddTask;
  final void Function(EffectiveTask task) onEditTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = catalog.tasksByCategoryKey();
    final sections = <Widget>[];

    for (final cat in catalog.categories) {
      final tasks = grouped[cat.key] ?? [];
      if (tasks.isEmpty) {
        continue;
      }
      sections.add(
        ManageTasksCategorySection(
          category: cat,
          tasks: tasks,
          l: l,
          onEditTask: onEditTask,
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    if (sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.manageChecklistNoTasks,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    sections.removeLast();

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 88),
      children: [
        ...sections,
        _AddCustomTaskCard(l: l, onTap: onAddTask),
      ],
    );
  }
}

class ManageTasksCategorySection extends ConsumerWidget {
  const ManageTasksCategorySection({
    super.key,
    required this.category,
    required this.tasks,
    required this.l,
    required this.onEditTask,
  });

  final EffectiveCategory category;
  final List<EffectiveTask> tasks;
  final AppLocalizations l;
  final void Function(EffectiveTask task) onEditTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sectionTitle = category.isUserOwned
        ? l.manageChecklistCustomTasks
        : category.displayName;

    return Column(
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
                sectionTitle,
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
            if (!category.isVisible) ...[
              const SizedBox(width: 8),
              _HiddenChip(label: l.manageChecklistHiddenLabel),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
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
                  ManageTaskRow(
                    task: tasks[i],
                    l: l,
                    onEdit: () => onEditTask(tasks[i]),
                  ),
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
    );
  }
}

class ManageTaskRow extends ConsumerWidget {
  const ManageTaskRow({
    super.key,
    required this.task,
    required this.l,
    required this.onEdit,
  });

  final EffectiveTask task;
  final AppLocalizations l;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(catalogRepositoryProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = !task.isVisible;

    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
        child: Row(
          children: [
            if (task.isUserOwned) ...[
              Icon(
                Icons.drag_indicator_rounded,
                color: scheme.outlineVariant,
                size: 22,
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                curatedIconData(task.icon),
                color: muted ? scheme.onSurfaceVariant : scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.manageChecklistPointsPlus(task.points, l.pointsLabel),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (task.isUserOwned)
                    Text(
                      l.manageChecklistCustomTaskLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Tooltip(
              message: task.isVisible
                  ? l.manageChecklistTooltipHide
                  : l.manageChecklistTooltipShow,
              child: Switch(
                value: task.isVisible,
                onChanged: (visible) async {
                  if (task.isUserOwned) {
                    if (visible) {
                      await repo.restoreUserTask(task.id);
                    } else {
                      await repo.deleteUserTask(task.id, archive: true);
                    }
                  } else if (task.defaultCode != null) {
                    if (!visible) {
                      if (fardAnchorTaskIds.contains(task.defaultCode)) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l.manageChecklistFardHideTitle),
                            content: Text(l.manageChecklistFardHideBody),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l.manageChecklistCancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l.manageChecklistHide),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) {
                          return;
                        }
                      }
                      await repo.upsertTaskOverride(
                        taskCode: task.defaultCode!,
                        hidden: true,
                      );
                    } else {
                      await repo.clearTaskOverride(task.defaultCode!);
                    }
                  }
                },
              ),
            ),
            if (task.isUserOwned)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l.manageChecklistEditTask),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(l.manageChecklistRemovePermanently),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'remove') {
                    final logCount =
                        await repo.countDailyLogsForUserTask(task.id);
                    if (!context.mounted) {
                      return;
                    }
                    await showRemovePermanentlySheet(
                      context: context,
                      ref: ref,
                      l: l,
                      isCategory: false,
                      id: task.id,
                      logCount: logCount,
                      onHideInstead: () =>
                          repo.deleteUserTask(task.id, archive: true),
                    );
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: l.manageChecklistEditTask,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomTaskCard extends StatelessWidget {
  const _AddCustomTaskCard({required this.l, required this.onTap});

  final AppLocalizations l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.manageChecklistAddCustomTask,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenChip extends StatelessWidget {
  const _HiddenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
