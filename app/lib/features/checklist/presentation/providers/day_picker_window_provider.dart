import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../domain/day_completion.dart';
import 'calendar_today_provider.dart';
import 'history_repository_provider.dart';

/// Number of day chips shown in [DayPickerBar].
const int kDayPickerVisibleDays = 30;

DayKey _pickerStart(DayKey today) {
  var cursor = today;
  for (var i = 0; i < kDayPickerVisibleDays - 1; i++) {
    cursor = cursor.previousDay();
  }
  return cursor;
}

/// Rolling 30-day completion summaries for day-picker chip colors.
final dayPickerWindowProvider =
    StreamProvider.autoDispose<List<DayCompletion>>((ref) {
      final today = ref.watch(calendarTodayProvider);
      final start = _pickerStart(today);
      return ref.watch(historyRepositoryProvider).watchRange(start, today);
    });
