import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/curated_icon_data.dart';
import '../../checklist/domain/fard_anchor_set.dart';
import '../domain/catalog_models.dart';
import 'providers/catalog_providers.dart';
import 'widgets/icon_picker_grid.dart';
import 'widgets/remove_permanently_sheet.dart';

class ManageChecklistScreen extends ConsumerStatefulWidget {
  const ManageChecklistScreen({super.key});

  @override
  ConsumerState<ManageChecklistScreen> createState() =>
      _ManageChecklistScreenState();
}

class _ManageChecklistScreenState extends ConsumerState<ManageChecklistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(manageEffectiveCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.manageChecklistTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.manageChecklistCategoriesTab),
            Tab(text: l.manageChecklistTasksTab),
          ],
        ),
      ),
      body: catalogAsync.when(
        data: (catalog) => TabBarView(
          controller: _tabs,
          children: [
            _CategoriesTab(catalog: catalog, l: l),
            _TasksTab(catalog: catalog, l: l),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onFabPressed(context, l),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabs.index == 0
              ? l.manageChecklistAddCategory
              : l.manageChecklistAddTask,
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context, AppLocalizations l) {
    if (_tabs.index == 0) {
      _showCategoryEditor(context, l);
    } else {
      _showTaskEditor(context, l);
    }
  }

  Future<void> _showCategoryEditor(
    BuildContext context,
    AppLocalizations l, {
    EffectiveCategory? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    var icon = existing?.icon ?? 'star';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null
                    ? l.manageChecklistAddCategory
                    : l.manageChecklistEditCategory,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l.manageChecklistNameLabel),
                enabled: existing == null || !existing.isFard,
              ),
              const SizedBox(height: 12),
              IconPickerGrid(
                selected: icon,
                onSelected: (v) => setSheetState(() => icon = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final repo = ref.read(catalogRepositoryProvider);
                  final name = nameCtrl.text.trim();
                  if (name.length < 2) {
                    return;
                  }
                  if (existing == null) {
                    await repo.createUserCategory(name: name, icon: icon);
                  } else if (existing.isUserOwned &&
                      existing.userCategoryId != null) {
                    await repo.updateUserCategory(
                      existing.userCategoryId!,
                      name: name,
                      icon: icon,
                    );
                  } else if (existing.defaultCode != null) {
                    await repo.upsertCategoryOverride(
                      categoryCode: existing.defaultCode!,
                      hidden: !existing.isVisible,
                      customName: existing.isFard ? null : name,
                      customIcon: icon,
                    );
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: Text(l.manageChecklistSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskEditor(
    BuildContext context,
    AppLocalizations l, {
    EffectiveTask? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    var icon = existing?.icon ?? 'star';
    var points = (existing?.points ?? 2).toDouble();
    var categoryKey = existing?.categoryKey;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final catalog = ref.watch(manageEffectiveCatalogProvider).value;
          if (catalog == null) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final selectableCategories =
              catalog.categories.where((c) => c.isVisible).toList();
          if (selectableCategories.isEmpty) {
            return const SizedBox.shrink();
          }
          categoryKey ??= selectableCategories.first.key;
          if (!selectableCategories.any((c) => c.key == categoryKey)) {
            categoryKey = selectableCategories.first.key;
          }

          return StatefulBuilder(
            builder: (ctx, setSheetState) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? l.manageChecklistAddTask
                          : l.manageChecklistEditTask,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.manageChecklistNameLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: categoryKey,
                      decoration: InputDecoration(
                        labelText: l.manageChecklistCategoryLabel,
                      ),
                      items: [
                        for (final c in selectableCategories)
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
                    const SizedBox(height: 8),
                    Text('${points.round()} ${l.pointsLabel}'),
                    Slider(
                      value: points,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '${points.round()}',
                      onChanged: (v) => setSheetState(() => points = v),
                    ),
                    IconPickerGrid(
                      selected: icon,
                      onSelected: (v) => setSheetState(() => icon = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final repo = ref.read(catalogRepositoryProvider);
                        final name = nameCtrl.text.trim();
                        if (name.length < 2) {
                          return;
                        }
                        final cat = selectableCategories
                            .firstWhere((c) => c.key == categoryKey);
                        final categoryRef = cat.isUserOwned
                            ? 'userCategory:${cat.userCategoryId}'
                            : 'category:${cat.defaultCode}';
                        final pts = points.round();
                        if (existing == null) {
                          await repo.createUserTask(
                            name: name,
                            categoryRef: categoryRef,
                            points: pts,
                            icon: icon,
                          );
                        } else if (existing.isUserOwned) {
                          await repo.updateUserTask(
                            existing.id,
                            name: name,
                            categoryRef: categoryRef,
                            points: pts,
                            icon: icon,
                          );
                        } else if (existing.defaultCode != null) {
                          await repo.upsertTaskOverride(
                            taskCode: existing.defaultCode!,
                            customName: name,
                            customPoints: pts,
                            customIcon: icon,
                            customCategoryRef: categoryRef,
                          );
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(l.manageChecklistSave),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Expose editors for list tiles
  void openCategoryEditor(EffectiveCategory cat) =>
      _showCategoryEditor(context, AppLocalizations.of(context)!, existing: cat);

  void openTaskEditor(EffectiveTask task) =>
      _showTaskEditor(context, AppLocalizations.of(context)!, existing: task);
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab({required this.catalog, required this.l});

  final EffectiveCatalog catalog;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(catalogRepositoryProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: catalog.categories.length,
      itemBuilder: (context, index) {
        final cat = catalog.categories[index];
        final locked = cat.isFard;
        return ListTile(
          leading: Icon(curatedIconData(cat.icon)),
          title: Text(cat.displayName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked)
                const Icon(Icons.lock_outline_rounded, size: 20)
              else
                Tooltip(
                  message: cat.isVisible
                      ? l.manageChecklistTooltipHide
                      : l.manageChecklistTooltipShow,
                  child: Switch(
                    value: cat.isVisible,
                    onChanged: (visible) async {
                      if (cat.isUserOwned && cat.userCategoryId != null) {
                        await repo.setUserCategoryArchived(
                          cat.userCategoryId!,
                          !visible,
                        );
                      } else if (cat.defaultCode != null) {
                        if (visible) {
                          await repo.clearCategoryOverride(cat.defaultCode!);
                        } else {
                          await repo.upsertCategoryOverride(
                            categoryCode: cat.defaultCode!,
                            hidden: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              if (cat.isUserOwned)
                PopupMenuButton<String>(
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l.manageChecklistEditCategory),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l.manageChecklistRemovePermanently),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context
                          .findAncestorStateOfType<
                              _ManageChecklistScreenState>()
                          ?.openCategoryEditor(cat);
                    } else if (value == 'remove' &&
                        cat.userCategoryId != null) {
                      await showRemovePermanentlySheet(
                        context: context,
                        ref: ref,
                        l: l,
                        isCategory: true,
                        id: cat.userCategoryId!,
                        logCount: 0,
                        onHideInstead: () => repo.setUserCategoryArchived(
                          cat.userCategoryId!,
                          true,
                        ),
                      );
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: locked
                      ? null
                      : () {
                          context
                              .findAncestorStateOfType<
                                  _ManageChecklistScreenState>()
                              ?.openCategoryEditor(cat);
                        },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab({required this.catalog, required this.l});

  final EffectiveCatalog catalog;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = catalog.tasksByCategoryKey();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final cat in catalog.categories) ...[
          if ((grouped[cat.key] ?? []).isNotEmpty) ...[
            _ManageTasksCategorySection(
              category: cat,
              tasks: grouped[cat.key]!,
              l: l,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _ManageTasksCategorySection extends ConsumerWidget {
  const _ManageTasksCategorySection({
    required this.category,
    required this.tasks,
    required this.l,
  });

  final EffectiveCategory category;
  final List<EffectiveTask> tasks;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  _ManageTaskListTile(task: tasks[i], l: l),
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

class _ManageTaskListTile extends ConsumerWidget {
  const _ManageTaskListTile({required this.task, required this.l});

  final EffectiveTask task;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(catalogRepositoryProvider);

    return ListTile(
      leading: Icon(curatedIconData(task.icon)),
      title: Text(task.displayName),
      subtitle: Text('${task.points} ${l.pointsLabel}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  context
                      .findAncestorStateOfType<_ManageChecklistScreenState>()
                      ?.openTaskEditor(task);
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
              onPressed: () {
                context
                    .findAncestorStateOfType<_ManageChecklistScreenState>()
                    ?.openTaskEditor(task);
              },
            ),
        ],
      ),
    );
  }
}
