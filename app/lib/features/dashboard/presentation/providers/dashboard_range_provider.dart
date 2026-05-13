import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dashboard_range.dart';

class DashboardRangeNotifier extends Notifier<DashboardRange> {
  @override
  DashboardRange build() => DashboardRange.week7;

  void select(DashboardRange range) {
    if (state != range) state = range;
  }
}

final dashboardRangeProvider =
    NotifierProvider<DashboardRangeNotifier, DashboardRange>(
      DashboardRangeNotifier.new,
    );
