import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/day_completion.dart';
import '../providers/calendar_today_provider.dart';
import '../providers/checklist_repositories_provider.dart';
import '../providers/history_strip_window_provider.dart';

/// Rolling 7-day completion heatmap rendered between [DayPickerBar] and
/// [ChecklistProgressHeader]. Each cell is a 1-tap shortcut into that day.
class HistoryStrip extends ConsumerWidget {
  const HistoryStrip({super.key});

  static const double _cellSize = 36;
  static const double _cellRadius = 8;
  static const double _outerVertical = 4;
  static const double _outerHorizontal = 12;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(historyStripWindowProvider);
    final activeDay = ref.watch(activeDayProvider);
    final today = ref.watch(calendarTodayProvider);
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        _outerHorizontal,
        _outerVertical,
        _outerHorizontal,
        _outerVertical,
      ),
      child: SizedBox(
        height: _cellSize + 22,
        child: daysAsync.when(
          data: (days) => _StripRow(
            cells: [
              for (final dc in days)
                _HistoryCell(
                  dc: dc,
                  isToday: dc.day == today,
                  isActive: dc.day == activeDay,
                  locale: locale,
                  l: l,
                  scheme: scheme,
                  onTap: () =>
                      ref.read(activeDayProvider.notifier).goToDay(dc.day),
                ),
            ],
          ),
          loading: () => _StripRow(
            cells: List.generate(
              kHistoryStripDays,
              (_) => _HistoryCellPlaceholder(scheme: scheme),
            ),
          ),
          error: (_, _) => _StripRow(
            cells: List.generate(
              kHistoryStripDays,
              (_) => _HistoryCellPlaceholder(scheme: scheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripRow extends StatelessWidget {
  const _StripRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(child: Center(child: cells[i])),
          if (i < cells.length - 1) const SizedBox(width: HistoryStrip._gap),
        ],
      ],
    );
  }
}

class _HistoryCellPlaceholder extends StatelessWidget {
  const _HistoryCellPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: HistoryStrip._cellSize,
          height: HistoryStrip._cellSize,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(HistoryStrip._cellRadius),
          ),
        ),
        const SizedBox(height: 4),
        Text(' ', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell({
    required this.dc,
    required this.isToday,
    required this.isActive,
    required this.locale,
    required this.l,
    required this.scheme,
    required this.onTap,
  });

  final DayCompletion dc;
  final bool isToday;
  final bool isActive;
  final Locale locale;
  final AppLocalizations l;
  final ColorScheme scheme;
  final VoidCallback onTap;

  Color _binColor() {
    final f = dc.fraction;
    if (f <= 0.0) return scheme.surfaceContainerHighest;
    if (f < 0.25) return scheme.primary.withValues(alpha: 0.20);
    if (f < 0.50) return scheme.primary.withValues(alpha: 0.40);
    if (f < 0.75) return scheme.primary.withValues(alpha: 0.65);
    return scheme.primary.withValues(alpha: 1.0);
  }

  String _dayLetter() {
    final formatted = DateFormat.E(
      locale.toLanguageTag(),
    ).format(dc.day.toLocalDateTime());
    if (formatted.isEmpty) return '';
    return formatted.characters.first.toString();
  }

  String _a11yDate() {
    return DateFormat.yMMMMEEEEd(
      locale.toLanguageTag(),
    ).format(dc.day.toLocalDateTime());
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = isActive ? scheme.primaryContainer : _binColor();
    final showFardRing = dc.fardMet;
    final showTodayRing = isToday && !dc.fardMet;
    final borderColor = showFardRing
        ? scheme.tertiary
        : (showTodayRing ? scheme.outline : Colors.transparent);
    final borderWidth = showFardRing ? 2.0 : (showTodayRing ? 1.0 : 0.0);

    final fardStateText = dc.fardMet
        ? l.historyStripFardComplete
        : l.historyStripFardIncomplete;
    final semanticsLabel = l.historyStripCellA11y(
      _a11yDate(),
      dc.percentInt,
      fardStateText,
    );

    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HistoryStrip._cellRadius),
        child: SizedBox(
          width: HistoryStrip._cellSize + 8,
          height: HistoryStrip._cellSize + 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: HistoryStrip._cellSize,
                height: HistoryStrip._cellSize,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(HistoryStrip._cellRadius),
                  border: borderWidth > 0
                      ? Border.all(color: borderColor, width: borderWidth)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dayLetter(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
