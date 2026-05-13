import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/dashboard_data_provider.dart';
import 'providers/dashboard_window_provider.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/category_chart_type_switcher.dart';
import 'widgets/dashboard_range_picker.dart';
import 'widgets/dashboard_section_card.dart';
import 'widgets/heatmap_chart.dart';
import 'widgets/weekly_bars_chart.dart';

/// Top-level Dashboard screen. Hosts the range picker and three section
/// cards (daily bars, activity heatmap, by-category breakdown), with
/// loading / empty / error fallbacks (D10).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inject the locale-aware first day of week into the pure-Dart
    // aggregator's data provider (D15).
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    return ProviderScope(
      overrides: [
        dashboardFirstDayOfWeekProvider.overrideWithValue(firstDayOfWeek),
      ],
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        scrolledUnderElevation: 0.5,
        title: Text(
          l.dashboardTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: dataAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (error, _) => _ErrorView(
          message: l.dashboardErrorLabel,
          retryLabel: l.dashboardRetryLabel,
          onRetry: () => ref.invalidate(dashboardWindowProvider),
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsetsDirectional.only(bottom: 24),
            children: [
              const DashboardRangePicker(),
              DashboardSectionCard(
                title: l.dashboardWeeklyBarsTitle,
                child: WeeklyBarsChart(
                  bars: data.bars,
                  range: data.range,
                  locale: Localizations.localeOf(context),
                  titleHint: l.dashboardWeeklyBarsTitle,
                ),
              ),
              DashboardSectionCard(
                title: l.dashboardHeatmapTitle,
                child: HeatmapChart(
                  cells: data.heatmap,
                  firstDayOfWeekIndex: MaterialLocalizations.of(
                    context,
                  ).firstDayOfWeekIndex,
                  locale: Localizations.localeOf(context),
                ),
              ),
              DashboardSectionCard(
                title: l.dashboardCategoriesTitle,
                trailing: const CategoryChartTypeSwitcher(),
                child: CategoryBreakdown(categories: data.categories),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget box(double h) => Card(
      margin: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
      child: SizedBox(
        height: h,
        child: ColoredBox(color: scheme.surfaceContainerHighest),
      ),
    );
    return ListView(
      padding: const EdgeInsetsDirectional.only(top: 12, bottom: 24),
      children: [box(180), box(140), box(200)],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
