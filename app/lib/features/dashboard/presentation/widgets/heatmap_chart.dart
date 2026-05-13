import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../checklist/presentation/providers/checklist_repositories_provider.dart';
import '../../domain/dashboard_data.dart';
import 'chart_colors.dart';

/// 7-row × N-column GitHub-contributions-style heatmap. Always per-day,
/// regardless of dashboard range (D6).
///
/// Tapping a cell navigates the user back to the Checklist tab and sets the
/// active day so they can review (or edit, if within `kMaxEditableDays`) that
/// day's tasks.
class HeatmapChart extends ConsumerWidget {
  const HeatmapChart({
    super.key,
    required this.cells,
    required this.firstDayOfWeekIndex,
    required this.locale,
  });

  final List<HeatmapCell> cells;

  /// Sunday = 0, Monday = 1, …, Saturday = 6 (matches MaterialLocalizations).
  final int firstDayOfWeekIndex;
  final Locale locale;

  static const double _cellSize = 14;
  static const double _cellGap = 3;
  static const double _tapTarget = 44;

  int _rowFor(DateTime dt) {
    final dartWeekday = dt.weekday % 7; // Sun=0, Mon=1, …, Sat=6
    return (dartWeekday - firstDayOfWeekIndex + 7) % 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final tag = locale.toLanguageTag();

    final leadingOffset = _rowFor(cells.first.day.toLocalDateTime());
    final totalSlots = leadingOffset + cells.length;
    final numCols = (totalSlots + 6) ~/ 7;

    // Materialize the slot → cell mapping.
    HeatmapCell? cellAt(int row, int col) {
      final slot = col * 7 + row;
      final index = slot - leadingOffset;
      if (index < 0 || index >= cells.length) return null;
      return cells[index];
    }

    // Weekday labels in the leading column (Sun→Sat or Sat→Sun depending on
    // firstDayOfWeekIndex). Uses a fixed-width column so RTL flips correctly.
    String weekdayLabel(int row) {
      // Build a synthetic DateTime with the right weekday so DateFormat.E
      // returns the locale-correct abbreviation.
      // 2026-01-04 was a Sunday — use that as the base.
      final base = DateTime(2026, 1, 4);
      final actualWeekdayOffset = (firstDayOfWeekIndex + row) % 7;
      final formatted = DateFormat.E(
        tag,
      ).format(base.add(Duration(days: actualWeekdayOffset)));
      return formatted;
    }

    Widget cellWidget(HeatmapCell? cell) {
      if (cell == null) {
        return SizedBox(width: _cellSize, height: _cellSize);
      }
      final isFard = cell.fardMet;
      final fardStateText = isFard
          ? l.historyStripFardComplete
          : l.historyStripFardIncomplete;
      final dateLabel = DateFormat.yMMMMEEEEd(
        tag,
      ).format(cell.day.toLocalDateTime());
      final semanticsLabel = l.dashboardHeatmapCellA11y(
        dateLabel,
        cell.percentInt,
        fardStateText,
      );

      return Semantics(
        label: semanticsLabel,
        button: true,
        excludeSemantics: true,
        child: SizedBox(
          width: _tapTarget,
          height: _tapTarget,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(3),
                onTap: () {
                  ref.read(activeDayProvider.notifier).goToDay(cell.day);
                  // Switch to the Checklist tab. With StatefulShellRoute the
                  // shell preserves state on both branches (D9 / D7).
                  GoRouter.of(context).go('/');
                },
                child: Container(
                  width: _cellSize,
                  height: _cellSize,
                  decoration: BoxDecoration(
                    color: completionBinColor(cell.fraction, scheme),
                    borderRadius: BorderRadius.circular(3),
                    border: isFard
                        ? Border.all(color: scheme.tertiary, width: 1.5)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < 7; row++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: _cellGap),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            weekdayLabel(row),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (var col = 0; col < numCols; col++)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: _cellGap,
                            ),
                            child: cellWidget(cellAt(row, col)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
