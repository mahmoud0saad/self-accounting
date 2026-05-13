import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../checklist/presentation/providers/calendar_today_provider.dart';
import '../../../checklist/presentation/providers/task_catalog_provider.dart';
import '../../domain/dashboard_aggregator.dart';
import '../../domain/dashboard_data.dart';
import 'dashboard_range_provider.dart';
import 'dashboard_window_provider.dart';

/// Locale-derived first-day-of-week (Sun = 0, Mon = 1, …, Sat = 6).
///
/// Default is `0` (Sunday). The real value is injected by `DashboardScreen`
/// via a `ProviderScope.override` that reads `MaterialLocalizations` for the
/// current locale, keeping the aggregator pure-Dart and testable.
final dashboardFirstDayOfWeekProvider = Provider<int>((ref) => 0);

final dashboardDataProvider = Provider.autoDispose<AsyncValue<DashboardData>>((
  ref,
) {
  final daysAsync = ref.watch(dashboardWindowProvider);
  final catalogAsync = ref.watch(taskCatalogProvider);
  final range = ref.watch(dashboardRangeProvider);
  final today = ref.watch(calendarTodayProvider);
  final firstDayOfWeek = ref.watch(dashboardFirstDayOfWeekProvider);

  return daysAsync.when(
    loading: () => const AsyncValue<DashboardData>.loading(),
    error: (error, stack) => AsyncValue<DashboardData>.error(error, stack),
    data: (days) => catalogAsync.when(
      loading: () => const AsyncValue<DashboardData>.loading(),
      error: (error, stack) => AsyncValue<DashboardData>.error(error, stack),
      data: (catalog) {
        // Defensive: the upstream stream may emit before the window has
        // settled to range.days. Skip the recompute until aligned to avoid
        // an assertion failure inside the aggregator.
        if (days.length != range.days) {
          return const AsyncValue<DashboardData>.loading();
        }
        return AsyncValue<DashboardData>.data(
          const DashboardAggregator().compute(
            days: days,
            catalog: catalog,
            range: range,
            today: today,
            firstDayOfWeekIndex: firstDayOfWeek,
          ),
        );
      },
    ),
  );
});
