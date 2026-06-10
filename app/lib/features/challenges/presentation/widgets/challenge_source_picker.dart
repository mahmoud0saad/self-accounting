import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../customization/domain/catalog_models.dart';

String defaultTaskId(EffectiveCatalog catalog) {
  final grouped = catalog.tasksByCategoryKey();
  for (final cat in catalog.categories) {
    final tasks = grouped[cat.key];
    if (tasks != null && tasks.isNotEmpty) {
      return tasks.first.id;
    }
  }
  if (catalog.tasks.isNotEmpty) {
    return catalog.tasks.first.id;
  }
  throw StateError('Catalog has no selectable tasks');
}

(String sourceKind, String sourceRef) challengeSourceFields(String taskId) {
  return ('TASK_WEEKLY_COUNT', taskId);
}

class ChallengeSourcePicker extends StatelessWidget {
  const ChallengeSourcePicker({
    super.key,
    required this.catalog,
    required this.l,
    required this.selectedTaskId,
    required this.onSelected,
  });

  final EffectiveCatalog catalog;
  final AppLocalizations l;
  final String selectedTaskId;
  final ValueChanged<String> onSelected;

  static String _headerValue(String categoryKey) => '__header__$categoryKey';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final grouped = catalog.tasksByCategoryKey();
    final items = <DropdownMenuItem<String>>[];

    for (final cat in catalog.categories) {
      final tasks = grouped[cat.key] ?? [];
      if (tasks.isEmpty) {
        continue;
      }
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: _headerValue(cat.key),
          child: Text(
            cat.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
      );
      for (final task in tasks) {
        items.add(
          DropdownMenuItem<String>(
            value: task.id,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(task.displayName),
            ),
          ),
        );
      }
    }

    final value = items.any((i) => i.enabled && i.value == selectedTaskId)
        ? selectedTaskId
        : items.firstWhere((i) => i.enabled).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.challengeCustomSourceHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.challengeSourceTabTask,
            border: const OutlineInputBorder(),
          ),
          items: items,
          onChanged: (v) {
            if (v != null) {
              onSelected(v);
            }
          },
        ),
      ],
    );
  }
}
