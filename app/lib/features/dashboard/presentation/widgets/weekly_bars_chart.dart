import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dashboard_data.dart';
import '../../domain/dashboard_range.dart';

/// Daily-completion bar chart. For [DashboardRange.days90] the input list is
/// already pre-bucketed into weekly averages by [DashboardAggregator]; for
/// shorter ranges each bar maps 1:1 to a calendar day.
class WeeklyBarsChart extends StatelessWidget {
  const WeeklyBarsChart({
    super.key,
    required this.bars,
    required this.range,
    required this.locale,
    required this.titleHint,
  });

  final List<DailyBar> bars;
  final DashboardRange range;
  final Locale locale;

  /// Human-readable section title, included in the wrapping [Semantics] node
  /// since per-bar a11y is intentionally out of scope (Phase 4 R8).
  final String titleHint;

  double _maxBarWidth() {
    switch (range) {
      case DashboardRange.week7:
        return 22;
      case DashboardRange.month30:
        return 8;
      case DashboardRange.days90:
        return 14;
    }
  }

  String _xLabel(int index, DateTime dt) {
    final tag = locale.toLanguageTag();
    switch (range) {
      case DashboardRange.week7:
        return DateFormat.E(tag).format(dt);
      case DashboardRange.month30:
        if (index % 5 != 0) return '';
        return DateFormat.MMMd(tag).format(dt);
      case DashboardRange.days90:
        if (index % 2 != 0) return '';
        return DateFormat.MMMd(tag).format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final groups = <BarChartGroupData>[
      for (var i = 0; i < bars.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: bars[i].fraction * 100,
              width: _maxBarWidth(),
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              borderSide: bars[i].fardMet
                  ? BorderSide(color: scheme.tertiary, width: 1.5)
                  : BorderSide.none,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
    ];

    return Semantics(
      label: '$titleHint, ${bars.length} bars',
      container: true,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: 100,
            minY: 0,
            barGroups: groups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant,
                strokeWidth: 0.5,
                dashArray: const [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    if (value % 25 != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        '${value.toInt()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= bars.length) {
                      return const SizedBox.shrink();
                    }
                    final label = _xLabel(
                      index,
                      bars[index].day.toLocalDateTime(),
                    );
                    if (label.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(top: 6),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, _, rod, _) {
                  final dt = bars[group.x].day.toLocalDateTime();
                  final dateLabel = DateFormat.yMMMMd(
                    locale.toLanguageTag(),
                  ).format(dt);
                  return BarTooltipItem(
                    '$dateLabel\n${rod.toY.toInt()}%',
                    theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
