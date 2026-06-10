import 'package:flutter/material.dart';

import '../../../../core/icons/curated_icon_data.dart';
import '../../../checklist/presentation/widgets/effective_task_row.dart';
import '../../domain/catalog_models.dart';

class EffectiveCategorySection extends StatelessWidget {
  const EffectiveCategorySection({
    super.key,
    required this.category,
    required this.tasks,
  });

  final EffectiveCategory category;
  final List<EffectiveTask> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final headerFill = category.isFard
        ? scheme.secondaryContainer
        : scheme.primaryContainer;
    final headerOnFill = category.isFard
        ? scheme.onSecondaryContainer
        : scheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        // color: scheme.surface,
        elevation: 0,
        // shadowColor: scheme.shadow.withValues(alpha: 0.18),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(16),
        //   side: BorderSide(
        //     // color: scheme.outlineVariant.withValues(alpha: 0.65),
        //   ),
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              // color: scheme.surfaceContainerHighest,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: headerFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          curatedIconData(category.icon),
                          color: headerOnFill,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.displayName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (category.isFard)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 6,
                                    ),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 18,
                                      color: scheme.outline,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final task in tasks) EffectiveTaskRow(task: task),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
