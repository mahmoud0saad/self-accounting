import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/curated_icon_data.dart';
import '../../domain/catalog_models.dart';
import '../providers/catalog_providers.dart';
import 'remove_permanently_sheet.dart';

class ManageCategoriesTab extends ConsumerWidget {
  const ManageCategoriesTab({
    super.key,
    required this.catalog,
    required this.l,
    required this.onEditCategory,
  });

  final EffectiveCatalog catalog;
  final AppLocalizations l;
  final void Function(EffectiveCategory category) onEditCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(catalogRepositoryProvider);

    if (catalog.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.manageChecklistNoCategories,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 88),
      itemCount: catalog.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cat = catalog.categories[index];
        return _ManageCategoryCard(
          category: cat,
          l: l,
          onEdit: () => onEditCategory(cat),
          onVisibilityChanged: (visible) async {
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
          onRemove: cat.isUserOwned && cat.userCategoryId != null
              ? () => showRemovePermanentlySheet(
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
                  )
              : null,
        );
      },
    );
  }
}

class _ManageCategoryCard extends StatelessWidget {
  const _ManageCategoryCard({
    required this.category,
    required this.l,
    required this.onEdit,
    required this.onVisibilityChanged,
    this.onRemove,
  });

  final EffectiveCategory category;
  final AppLocalizations l;
  final VoidCallback onEdit;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = category.isFard;
    final muted = !category.isVisible;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                curatedIconData(category.icon),
                color: muted ? scheme.onSurfaceVariant : scheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                  if (category.isUserOwned) ...[
                    const SizedBox(height: 2),
                    Text(
                      l.manageChecklistCustomCategoryLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (muted) ...[
                    const SizedBox(height: 4),
                    _HiddenChip(label: l.manageChecklistHiddenLabel),
                  ],
                ],
              ),
            ),
            if (locked)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: scheme.outline,
                ),
              )
            else
              Tooltip(
                message: category.isVisible
                    ? l.manageChecklistTooltipHide
                    : l.manageChecklistTooltipShow,
                child: Switch(
                  value: category.isVisible,
                  onChanged: onVisibilityChanged,
                ),
              ),
            if (onRemove != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
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
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'remove') {
                    onRemove!();
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: locked ? null : onEdit,
                tooltip: l.manageChecklistEditCategory,
              ),
          ],
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
