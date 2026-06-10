import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalog_models.dart';
import 'providers/catalog_providers.dart';
import 'widgets/manage_catalog_editor_sheets.dart';
import 'widgets/manage_categories_tab.dart';
import 'widgets/manage_tasks_tab.dart';

class ManageChecklistScreen extends ConsumerStatefulWidget {
  const ManageChecklistScreen({super.key});

  @override
  ConsumerState<ManageChecklistScreen> createState() =>
      ManageChecklistScreenState();
}

class ManageChecklistScreenState extends ConsumerState<ManageChecklistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index != _tabIndex) {
      setState(() => _tabIndex = _tabs.index);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(manageEffectiveCatalogProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: scheme.surfaceTint,
        title: Text(
          l.manageChecklistTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
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
            ManageCategoriesTab(
              catalog: catalog,
              l: l,
              onEditCategory: openCategoryEditor,
            ),
            ManageTasksTab(
              catalog: catalog,
              l: l,
              onAddTask: () => openTaskEditor(),
              onEditTask: openTaskEditor,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onFabPressed(l),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabIndex == 0
              ? l.manageChecklistNewCategory
              : l.manageChecklistAddCustomTask,
        ),
      ),
    );
  }

  void _onFabPressed(AppLocalizations l) {
    if (_tabIndex == 0) {
      openCategoryEditor();
    } else {
      openTaskEditor();
    }
  }

  void openCategoryEditor([EffectiveCategory? existing]) {
    showManageCategoryEditor(
      context: context,
      ref: ref,
      l: AppLocalizations.of(context)!,
      existing: existing,
    );
  }

  void openTaskEditor([EffectiveTask? existing]) {
    showManageTaskEditor(
      context: context,
      ref: ref,
      l: AppLocalizations.of(context)!,
      existing: existing,
    );
  }
}
