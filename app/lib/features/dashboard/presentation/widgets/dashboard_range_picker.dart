import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dashboard_range.dart';
import '../providers/dashboard_range_provider.dart';

/// Three-segment range picker pinned just under the Dashboard AppBar.
/// Drives [dashboardRangeProvider]; selection is not persisted across cold
/// launches (Phase 4 D9).
class DashboardRangePicker extends ConsumerWidget {
  const DashboardRangePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = ref.watch(dashboardRangeProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<DashboardRange>(
          segments: [
            ButtonSegment(
              value: DashboardRange.week7,
              label: Text(l.dashboardRangeWeek),
            ),
            ButtonSegment(
              value: DashboardRange.month30,
              label: Text(l.dashboardRangeMonth),
            ),
            ButtonSegment(
              value: DashboardRange.days90,
              label: Text(l.dashboardRange90),
            ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(dashboardRangeProvider.notifier).select(s.first),
        ),
      ),
    );
  }
}
