import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../domain/day_completion.dart';
import 'calendar_today_provider.dart';
import 'checklist_repositories_provider.dart';
import 'history_repository_provider.dart';

DayKey _streakStart(DayKey today) {
  var cursor = today;
  for (var i = 0; i < kMaxHistoryDays; i++) {
    cursor = cursor.previousDay();
  }
  return cursor;
}

/// 30-day rolling window feeding the streak counter (D5).
final streakWindowProvider = StreamProvider.autoDispose<List<DayCompletion>>((
  ref,
) {
  final today = ref.watch(calendarTodayProvider);
  final start = _streakStart(today);
  return ref.watch(historyRepositoryProvider).watchRange(start, today);
});
