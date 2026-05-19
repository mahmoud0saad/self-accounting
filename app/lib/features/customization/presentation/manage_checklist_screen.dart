import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/curated_icon_data.dart';
import '../../checklist/domain/fard_anchor_set.dart';
import '../domain/catalog_models.dart';
import 'providers/catalog_providers.dart';
import 'widgets/icon_picker_grid.dart';

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
    final catalogAsync = ref.watch(effectiveCatalogProvider);

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
      builder: (ctx) => Padding(
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
              onSelected: (v) => icon = v,
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
                } else if (existing.isUserOwned && existing.userCategoryId != null) {
                  await repo.updateUserCategory(
                    existing.userCategoryId!,
                    name: name,
                    icon: icon,
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
    );
  }

  Future<void> _showTaskEditor(
    BuildContext context,
    AppLocalizations l, {
    EffectiveTask? existing,
  }) async {
    final catalog = ref.read(effectiveCatalogProvider).value;
    if (catalog == null) {
      return;
    }
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    var icon = existing?.icon ?? 'star';
    var points = (existing?.points ?? 2).toDouble();
    var categoryKey = existing?.categoryKey ?? catalog.categories.first.key;

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
                  decoration:
                      InputDecoration(labelText: l.manageChecklistNameLabel),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categoryKey,
                  decoration: InputDecoration(
                    labelText: l.manageChecklistCategoryLabel,
                  ),
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
                    final cat = catalog.categories
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
                Switch(
                  value: true,
                  onChanged: (v) async {
                    if (!v && cat.defaultCode != null) {
                      await repo.upsertCategoryOverride(
                        categoryCode: cat.defaultCode!,
                        hidden: true,
                      );
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: locked || !cat.isUserOwned
                    ? null
                    : () {
                        final state = context
                            .findAncestorStateOfType<_ManageChecklistScreenState>();
                        state?.openCategoryEditor(cat);
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
    final repo = ref.read(catalogRepositoryProvider);
    final grouped = catalog.tasksByCategoryKey();
    final items = <EffectiveTask>[];
    for (final cat in catalog.categories) {
      items.addAll(grouped[cat.key] ?? []);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final task = items[index];
        return ListTile(
          leading: Icon(curatedIconData(task.icon)),
          title: Text(task.displayName),
          subtitle: Text('${task.points} ${l.pointsLabel}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: true,
                onChanged: (v) async {
                  if (!v) {
                    if (task.isUserOwned) {
                      await repo.deleteUserTask(task.id, archive: true);
                    } else if (task.defaultCode != null) {
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
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<_ManageChecklistScreenState>();
                  state?.openTaskEditor(task);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
