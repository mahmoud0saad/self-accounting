import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/day_key.dart';
import '../providers/calendar_today_provider.dart';
import '../providers/checklist_repositories_provider.dart';
import '../providers/daily_progress_provider.dart';
import '../providers/day_picker_window_provider.dart';

/// Horizontal scroll of the last 30 calendar days as tappable chips (tabs).
/// Order: Today → Yesterday → older days. [activeDayProvider] drives selection.
class DayPickerBar extends ConsumerStatefulWidget {
  const DayPickerBar({super.key});

  static DayKey _oldestAllowed(DayKey today) {
    var d = today;
    for (var i = 0; i < kMaxHistoryDays; i++) {
      d = d.previousDay();
    }
    return d;
  }

  @override
  ConsumerState<DayPickerBar> createState() => _DayPickerBarState();
}

class _DayPickerBarState extends ConsumerState<DayPickerBar> {
  final Map<DayKey, GlobalKey> _keys = {};
  bool _didScheduleInitialScroll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleInitialScroll) {
      return;
    }
    _didScheduleInitialScroll = true;
    final today = ref.read(calendarTodayProvider);
    final oldest = DayPickerBar._oldestAllowed(today);
    final active = ref.read(activeDayProvider);
    _scrollToActive(active, _buildDayKeys(today, oldest));
  }

  List<DayKey> _buildDayKeys(DayKey today, DayKey oldest) {
    final keys = <DayKey>[];
    var d = today;
    for (var i = 0; i < kDayPickerVisibleDays; i++) {
      if (d.compareTo(oldest) < 0) {
        break;
      }
      keys.add(d);
      d = d.previousDay();
    }
    return keys;
  }

  GlobalKey _keyFor(DayKey day) => _keys.putIfAbsent(day, GlobalKey.new);

  void _scrollToActive(DayKey active, List<DayKey> dayKeys) {
    if (!dayKeys.contains(active)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final key = _keys[active];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final active = ref.watch(activeDayProvider);
    final today = ref.watch(calendarTodayProvider);
    final oldest = DayPickerBar._oldestAllowed(today);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tag = locale.toLanguageTag();

    final dayKeys = _buildDayKeys(today, oldest);

    ref.listen<DayKey>(activeDayProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      _scrollToActive(next, _buildDayKeys(today, oldest));
    });

    String line1(DayKey day) {
      if (day == today) {
        return l.dayLabelToday;
      }
      if (day == today.previousDay()) {
        return l.dayLabelYesterday;
      }
      return DateFormat.EEEE(tag).format(day.toLocalDateTime());
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      child: SizedBox(
        height: 68,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dayKeys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final day = dayKeys[index];
            return _DayPickerChip(
              key: _keyFor(day),
              day: day,
              selected: day == active,
              line1: line1(day),
              scheme: scheme,
              textTheme: textTheme,
              onTap: () => ref.read(activeDayProvider.notifier).goToDay(day),
            );
          },
        ),
      ),
    );
  }
}

class _DayPickerChip extends ConsumerWidget {
  const _DayPickerChip({
    required super.key,
    required this.day,
    required this.selected,
    required this.line1,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  final DayKey day;
  final bool selected;
  final String line1;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  static Color _fillColor(double fraction, ColorScheme scheme) {
    if (fraction <= 0.0) return scheme.surfaceContainerHighest;
    return scheme.primary.withValues(alpha: fraction.clamp(0.0, 1.0));
  }

  static Color _labelColor(double fraction, ColorScheme scheme) {
    return fraction >= 0.50 ? scheme.onPrimary : scheme.onSurface;
  }

  static Color _secondaryLabelColor(double fraction, ColorScheme scheme) {
    return fraction >= 0.50
        ? scheme.onPrimary.withValues(alpha: 0.92)
        : scheme.onSurfaceVariant;
  }

  static Color _selectionBorderColor(
    bool selected,
    double fraction,
    ColorScheme scheme,
  ) {
    if (!selected) return scheme.outlineVariant;
    if (fraction >= 0.65) return scheme.onPrimary;
    return scheme.secondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(dailyProgressForDayProvider(day)).maybeWhen(
          data: (p) => p,
          orElse: () => null,
        );
    final fraction = progress?.fraction ?? 0.0;
    final percentInt = progress?.percentInt ?? 0;
    final percentLabel = '$percentInt%';
    final fillColor = _fillColor(fraction, scheme);
    final labelColor = _labelColor(fraction, scheme);
    final secondaryLabelColor = _secondaryLabelColor(fraction, scheme);
    final borderColor = _selectionBorderColor(selected, fraction, scheme);

    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                line1,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                percentLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: secondaryLabelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '$line1, $percentLabel',
      child: chip,
    );
  }
}
