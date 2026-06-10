import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog_models.dart';
import '../providers/catalog_providers.dart';
import 'icon_picker_grid.dart';

/// Rounded top padding for manage create/edit bottom sheets.
EdgeInsetsDirectional manageEditorSheetPadding(BuildContext context) {
  final bottom = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsetsDirectional.only(
    start: 20,
    end: 20,
    top: 24,
    bottom: bottom + 24,
  );
}

ShapeBorder? manageEditorSheetShape(BuildContext context) {
  return const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  );
}

Future<void> showManageCategoryEditor({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l,
  EffectiveCategory? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: manageEditorSheetShape(context),
    builder: (ctx) => _ManageCategoryEditorSheet(
      parentRef: ref,
      l: l,
      existing: existing,
    ),
  );
}

class _ManageCategoryEditorSheet extends StatefulWidget {
  const _ManageCategoryEditorSheet({
    required this.parentRef,
    required this.l,
    required this.existing,
  });

  final WidgetRef parentRef;
  final AppLocalizations l;
  final EffectiveCategory? existing;

  @override
  State<_ManageCategoryEditorSheet> createState() =>
      _ManageCategoryEditorSheetState();
}

class _ManageCategoryEditorSheetState extends State<_ManageCategoryEditorSheet> {
  late String _name;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.displayName ?? '';
    _icon = widget.existing?.icon ?? 'star';
  }

  Future<void> _save() async {
    final name = _name.trim();
    if (name.length < 2) {
      return;
    }

    final existing = widget.existing;
    final icon = _icon;
    final repo = widget.parentRef.read(catalogRepositoryProvider);

    if (mounted) {
      FocusScope.of(context).unfocus();
      Navigator.pop(context);
    }

    if (existing == null) {
      await repo.createUserCategory(name: name, icon: icon);
    } else if (existing.isUserOwned && existing.userCategoryId != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final l = widget.l;

    return Padding(
      padding: manageEditorSheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            existing == null
                ? l.manageChecklistNewCategory
                : l.manageChecklistEditCategory,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _name,
            onChanged: (value) => _name = value,
            decoration: InputDecoration(
              labelText: l.manageChecklistNameLabel,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: existing == null || !existing.isFard,
          ),
          const SizedBox(height: 16),
          IconPickerGrid(
            selected: _icon,
            onSelected: (v) => setState(() => _icon = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _save,
            child: Text(l.manageChecklistSave),
          ),
        ],
      ),
    );
  }
}

Future<void> showManageTaskEditor({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l,
  EffectiveTask? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: manageEditorSheetShape(context),
    builder: (ctx) => _ManageTaskEditorSheet(
      l: l,
      existing: existing,
    ),
  );
}

class _ManageTaskEditorSheet extends ConsumerStatefulWidget {
  const _ManageTaskEditorSheet({
    required this.l,
    required this.existing,
  });

  final AppLocalizations l;
  final EffectiveTask? existing;

  @override
  ConsumerState<_ManageTaskEditorSheet> createState() =>
      _ManageTaskEditorSheetState();
}

class _ManageTaskEditorSheetState extends ConsumerState<_ManageTaskEditorSheet> {
  late String _name;
  late String _icon;
  late double _points;
  String? _categoryKey;

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.displayName ?? '';
    _icon = widget.existing?.icon ?? 'star';
    _points = (widget.existing?.points ?? 2).toDouble();
    _categoryKey = widget.existing?.categoryKey;
  }

  Future<void> _save({
    required EffectiveTask? existing,
    required List<EffectiveCategory> selectableCategories,
    required String categoryKey,
  }) async {
    final name = _name.trim();
    if (name.length < 2) {
      return;
    }

    final cat = selectableCategories.firstWhere((c) => c.key == categoryKey);
    final categoryRef = cat.isUserOwned
        ? 'userCategory:${cat.userCategoryId}'
        : 'category:${cat.defaultCode}';
    final pts = _points.round();
    final icon = _icon;
    final repo = ref.read(catalogRepositoryProvider);

    if (mounted) {
      FocusScope.of(context).unfocus();
      Navigator.pop(context);
    }

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
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(manageEffectiveCatalogProvider).value;
    if (catalog == null) {
      return Padding(
        padding: manageEditorSheetPadding(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectableCategories =
        catalog.categories.where((c) => c.isVisible).toList();
    if (selectableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    _categoryKey ??= selectableCategories.first.key;
    if (!selectableCategories.any((c) => c.key == _categoryKey)) {
      _categoryKey = selectableCategories.first.key;
    }

    final existing = widget.existing;
    final l = widget.l;
    final scheme = Theme.of(context).colorScheme;
    final categoryKey = _categoryKey!;

    return Padding(
      padding: manageEditorSheetPadding(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null
                  ? l.manageChecklistAddCustomTask
                  : l.manageChecklistEditTask,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _name,
              onChanged: (value) => _name = value,
              decoration: InputDecoration(
                labelText: l.manageChecklistNameLabel,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoryKey,
              decoration: InputDecoration(
                labelText: l.manageChecklistCategoryLabel,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  setState(() => _categoryKey = v);
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              l.manageChecklistPointsPlus(
                _points.round(),
                l.pointsLabel,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Slider(
              value: _points,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_points.round()}',
              activeColor: scheme.primary,
              onChanged: (v) => setState(() => _points = v),
            ),
            IconPickerGrid(
              selected: _icon,
              onSelected: (v) => setState(() => _icon = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _save(
                existing: existing,
                selectableCategories: selectableCategories,
                categoryKey: categoryKey,
              ),
              child: Text(l.manageChecklistSave),
            ),
          ],
        ),
      ),
    );
  }
}
