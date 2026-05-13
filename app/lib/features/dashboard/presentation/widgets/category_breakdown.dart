import 'package:app/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../checklist/domain/task.dart';
import '../../domain/category_chart_type.dart';
import '../../domain/dashboard_data.dart';
import '../providers/category_chart_type_provider.dart';

/// Per-category breakdown for the active range. Dispatches between four
/// visualizations driven by [categoryChartTypeProvider] (D4).
class CategoryBreakdown extends ConsumerWidget {
  const CategoryBreakdown({super.key, required this.categories});

  final List<CategoryCompletion> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(categoryChartTypeProvider);
    return switch (type) {
      CategoryChartType.horizontalBars => _CategoryBarsView(
        categories: categories,
      ),
      CategoryChartType.radar => _CategoryRadarView(categories: categories),
      CategoryChartType.stackedBar => _CategoryStackedBarView(
        categories: categories,
      ),
      CategoryChartType.donut => _CategoryDonutView(categories: categories),
    };
  }
}

String _categoryName(TaskCategory c, AppLocalizations l) => switch (c) {
  TaskCategory.fajr => l.categoryNameFajr,
  TaskCategory.dhuhr => l.categoryNameDhuhr,
  TaskCategory.asr => l.categoryNameAsr,
  TaskCategory.maghrib => l.categoryNameMaghrib,
  TaskCategory.isha => l.categoryNameIsha,
  TaskCategory.qiyamEvening => l.categoryNameQiyamEvening,
  TaskCategory.quranFasting => l.categoryNameQuranFasting,
  TaskCategory.miscAdhkar => l.categoryNameMiscAdhkar,
};

IconData _categoryIcon(TaskCategory c) => switch (c) {
  TaskCategory.fajr => Icons.wb_twilight_rounded,
  TaskCategory.dhuhr => Icons.wb_sunny_rounded,
  TaskCategory.asr => Icons.wb_cloudy_rounded,
  TaskCategory.maghrib => Icons.brightness_4_rounded,
  TaskCategory.isha => Icons.brightness_3_rounded,
  TaskCategory.qiyamEvening => Icons.nights_stay_rounded,
  TaskCategory.quranFasting => Icons.menu_book_rounded,
  TaskCategory.miscAdhkar => Icons.auto_awesome_rounded,
};

Color _categoryColor(TaskCategory c, ColorScheme scheme) => switch (c) {
  TaskCategory.fajr => scheme.primary,
  TaskCategory.dhuhr => scheme.secondary,
  TaskCategory.asr => scheme.tertiary,
  TaskCategory.maghrib => Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.6),
    scheme.secondary,
  ),
  TaskCategory.isha => scheme.primary.withValues(alpha: 0.7),
  TaskCategory.qiyamEvening => scheme.secondary.withValues(alpha: 0.7),
  TaskCategory.quranFasting => scheme.tertiary.withValues(alpha: 0.7),
  TaskCategory.miscAdhkar => scheme.outline,
};

class _CategoryBarsView extends StatelessWidget {
  const _CategoryBarsView({required this.categories});

  final List<CategoryCompletion> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10),
            child: Semantics(
              label: l.dashboardCategoryA11y(
                _categoryName(c.category, l),
                c.percentInt,
              ),
              container: true,
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    _categoryIcon(c.category),
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Text(
                      _categoryName(c.category, l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: c.fraction.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${c.percentInt}%',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryRadarView extends StatelessWidget {
  const _CategoryRadarView({required this.categories});

  final List<CategoryCompletion> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final dataEntries = <RadarEntry>[
      for (final c in categories)
        RadarEntry(value: (c.fraction * 100).clamp(0.0, 100.0)),
    ];

    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: scheme.surface,
          radarBorderData: BorderSide(color: scheme.outlineVariant),
          gridBorderData: BorderSide(color: scheme.outlineVariant, width: 0.5),
          tickBorderData: BorderSide(color: scheme.outlineVariant, width: 0.5),
          ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          tickCount: 4,
          getTitle: (index, _) {
            if (index < 0 || index >= categories.length) {
              return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: _categoryName(categories[index].category, l),
            );
          },
          titleTextStyle: theme.textTheme.labelSmall,
          dataSets: [
            RadarDataSet(
              dataEntries: dataEntries,
              fillColor: scheme.primary.withValues(alpha: 0.30),
              borderColor: scheme.primary,
              entryRadius: 3,
              borderWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStackedBarView extends StatelessWidget {
  const _CategoryStackedBarView({required this.categories});

  final List<CategoryCompletion> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final totalWeight = categories.fold<int>(
      0,
      (s, c) => s + (c.totalPoints == 0 ? 1 : c.totalPoints),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                for (final c in categories)
                  Expanded(
                    flex: c.totalPoints == 0 ? 1 : c.totalPoints,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: scheme.surfaceContainerHighest),
                        FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: c.fraction.clamp(0.0, 1.0),
                          child: Container(
                            color: _categoryColor(c.category, scheme),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${categories.length} categories, '
          '${totalWeight > 0 ? totalWeight : 0} weighted slots',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final c in categories)
              _LegendChip(
                color: _categoryColor(c.category, scheme),
                label: '${_categoryName(c.category, l)} · ${c.percentInt}%',
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryDonutView extends StatelessWidget {
  const _CategoryDonutView({required this.categories});

  final List<CategoryCompletion> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final sections = <PieChartSectionData>[
      for (final c in categories)
        PieChartSectionData(
          value: c.totalPoints == 0 ? 1 : c.totalPoints.toDouble(),
          color: _categoryColor(c.category, scheme),
          showTitle: false,
          // Stronger fractions push the slice further from the center hole.
          radius: 24 + (c.fraction.clamp(0.0, 1.0) * 36),
          borderSide: BorderSide(color: scheme.surface, width: 1),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 44,
              sectionsSpace: 1,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final c in categories)
              _LegendChip(
                color: _categoryColor(c.category, scheme),
                label: '${_categoryName(c.category, l)} · ${c.percentInt}%',
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
