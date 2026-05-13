import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../../checklist/domain/day_completion.dart';
import '../../../checklist/presentation/providers/calendar_today_provider.dart';
import '../../../checklist/presentation/providers/history_repository_provider.dart';
import '../../domain/dashboard_range.dart';
import 'dashboard_range_provider.dart';

DayKey _startOfRange(DayKey today, DashboardRange range) {
  var cursor = today;
  for (var i = 0; i < range.days - 1; i++) {
    cursor = cursor.previousDay();
  }
  return cursor;
}

/// Reactive day window driving every dashboard chart. Anchored to wall-clock
/// `today` (NOT the user's active day on the Checklist tab — V33).
final dashboardWindowProvider = StreamProvider.autoDispose<List<DayCompletion>>(
  (ref) {
    final today = ref.watch(calendarTodayProvider);
    final range = ref.watch(dashboardRangeProvider);
    final start = _startOfRange(today, range);
    return ref.watch(historyRepositoryProvider).watchRange(start, today);
  },
);
