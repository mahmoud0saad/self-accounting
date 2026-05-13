import 'dart:async';

import 'package:flutter/widgets.dart';

import 'day_key.dart';

/// Fires when the calendar day advances in local time (timer + resume).
final class MidnightTickerService extends WidgetsBindingObserver {
  Timer? _timer;
  void Function(DayKey newToday)? _onTodayChanged;
  DayKey _lastKnownToday = DayKey.today();

  void start(void Function(DayKey newToday) onTodayChanged) {
    _onTodayChanged = onTodayChanged;
    WidgetsBinding.instance.addObserver(this);
    _lastKnownToday = DayKey.today();
    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    var duration = nextMidnight.difference(now);
    if (duration <= Duration.zero) {
      duration = const Duration(seconds: 1);
    }
    _timer = Timer(duration, _onMidnight);
  }

  void _onMidnight() {
    final newToday = DayKey.today();
    if (newToday != _lastKnownToday) {
      _lastKnownToday = newToday;
      _onTodayChanged?.call(newToday);
    }
    _scheduleNextMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final newToday = DayKey.today();
      if (newToday != _lastKnownToday) {
        _lastKnownToday = newToday;
        _onTodayChanged?.call(newToday);
      }
      _scheduleNextMidnight();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }
}
