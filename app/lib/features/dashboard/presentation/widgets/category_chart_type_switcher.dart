import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/category_chart_type.dart';
import '../providers/category_chart_type_provider.dart';

/// Compact icon-only segmented switcher for choosing which visualization the
/// category breakdown should use.
class CategoryChartTypeSwitcher extends ConsumerWidget {
  const CategoryChartTypeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = ref.watch(categoryChartTypeProvider);

    return SegmentedButton<CategoryChartType>(
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: CategoryChartType.horizontalBars,
          icon: Tooltip(
            message: l.categoryChartTypeBarsTooltip,
            child: Semantics(
              label: l.categoryChartTypeBarsTooltip,
              child: const Icon(Icons.bar_chart_rounded),
            ),
          ),
        ),
        ButtonSegment(
          value: CategoryChartType.radar,
          icon: Tooltip(
            message: l.categoryChartTypeRadarTooltip,
            child: Semantics(
              label: l.categoryChartTypeRadarTooltip,
              child: const Icon(Icons.radar_rounded),
            ),
          ),
        ),
        ButtonSegment(
          value: CategoryChartType.stackedBar,
          icon: Tooltip(
            message: l.categoryChartTypeStackedTooltip,
            child: Semantics(
              label: l.categoryChartTypeStackedTooltip,
              child: const Icon(Icons.view_week_rounded),
            ),
          ),
        ),
        ButtonSegment(
          value: CategoryChartType.donut,
          icon: Tooltip(
            message: l.categoryChartTypeDonutTooltip,
            child: Semantics(
              label: l.categoryChartTypeDonutTooltip,
              child: const Icon(Icons.donut_large_rounded),
            ),
          ),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(categoryChartTypeProvider.notifier).select(s.first),
    );
  }
}
