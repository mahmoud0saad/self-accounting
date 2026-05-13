import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';

/// Reactive "what is today" anchor — distinct from [activeDayProvider], which
/// tracks the day the user is *viewing*. The midnight ticker rebases this
/// whenever the local calendar day advances, so the history strip and streak
/// window stay anchored to wall-clock today regardless of which day the user
/// is currently reviewing (D15).
class CalendarTodayNotifier extends Notifier<DayKey> {
  @override
  DayKey build() => DayKey.today();

  /// Called from the midnight ticker callback.
  void rebase(DayKey newToday) {
    if (state != newToday) {
      state = newToday;
    }
  }
}

final calendarTodayProvider = NotifierProvider<CalendarTodayNotifier, DayKey>(
  CalendarTodayNotifier.new,
);
