import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../domain/day_completion.dart';
import 'calendar_today_provider.dart';
import 'history_repository_provider.dart';

/// Number of cells in the home-screen history strip (today + 6 prior days).
const int kHistoryStripDays = 7;

DayKey _stripStart(DayKey today) {
  var cursor = today;
  for (var i = 0; i < kHistoryStripDays - 1; i++) {
    cursor = cursor.previousDay();
  }
  return cursor;
}

final historyStripWindowProvider =
    StreamProvider.autoDispose<List<DayCompletion>>((ref) {
      final today = ref.watch(calendarTodayProvider);
      final start = _stripStart(today);
      return ref.watch(historyRepositoryProvider).watchRange(start, today);
    });
