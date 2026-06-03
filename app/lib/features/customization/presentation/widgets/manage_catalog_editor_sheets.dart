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
}) async {
  final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
  var icon = existing?.icon ?? 'star';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: manageEditorSheetShape(context),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: manageEditorSheetPadding(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null
                  ? l.manageChecklistNewCategory
                  : l.manageChecklistEditCategory,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
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
              selected: icon,
              onSelected: (v) => setSheetState(() => icon = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
  nameCtrl.dispose();
}

Future<void> showManageTaskEditor({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l,
  EffectiveTask? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
  var icon = existing?.icon ?? 'star';
  var points = (existing?.points ?? 2).toDouble();
  var categoryKey = existing?.categoryKey;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: manageEditorSheetShape(context),
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final catalog = ref.watch(manageEffectiveCatalogProvider).value;
        if (catalog == null) {
          return Padding(
            padding: manageEditorSheetPadding(ctx),
            child: const Center(child: CircularProgressIndicator()),
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

        final scheme = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: manageEditorSheetPadding(ctx),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null
                        ? l.manageChecklistAddCustomTask
                        : l.manageChecklistEditTask,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
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
                        setSheetState(() => categoryKey = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.manageChecklistPointsPlus(
                      points.round(),
                      l.pointsLabel,
                    ),
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Slider(
                    value: points,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${points.round()}',
                    activeColor: scheme.primary,
                    onChanged: (v) => setSheetState(() => points = v),
                  ),
                  IconPickerGrid(
                    selected: icon,
                    onSelected: (v) => setSheetState(() => icon = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
  nameCtrl.dispose();
}
