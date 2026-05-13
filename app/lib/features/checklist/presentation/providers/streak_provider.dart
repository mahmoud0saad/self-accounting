import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak.dart';
import '../../domain/streak_calculator.dart';
import 'calendar_today_provider.dart';
import 'streak_window_provider.dart';

const _calculator = StreakCalculator();

final streakProvider = Provider.autoDispose<AsyncValue<Streak>>((ref) {
  final today = ref.watch(calendarTodayProvider);
  final daysAsync = ref.watch(streakWindowProvider);
  return daysAsync.whenData((days) => _calculator.compute(days, today: today));
});
