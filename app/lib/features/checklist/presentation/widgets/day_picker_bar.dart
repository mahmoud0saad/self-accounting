import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/day_key.dart';
import '../../domain/day_completion.dart';
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

  Color _fillColor(double fraction, ColorScheme scheme) {
    if (fraction <= 0.0) return scheme.surfaceContainerHighest;
    return scheme.primary.withValues(alpha: fraction.clamp(0.0, 1.0));
  }

  Color _labelColor(double fraction, ColorScheme scheme) {
    return fraction >= 0.50 ? scheme.onPrimary : scheme.onSurface;
  }

  Color _secondaryLabelColor(double fraction, ColorScheme scheme) {
    return fraction >= 0.50
        ? scheme.onPrimary.withValues(alpha: 0.92)
        : scheme.onSurfaceVariant;
  }

  Color _selectionBorderColor(
    bool selected,
    double fraction,
    ColorScheme scheme,
  ) {
    if (!selected) return scheme.outlineVariant;
    if (fraction >= 0.65) return scheme.onPrimary;
    return scheme.secondary;
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
    final completionByDay = ref.watch(dayPickerWindowProvider).maybeWhen(
      data: (days) => {for (final dc in days) dc.day: dc},
      orElse: () => <DayKey, DayCompletion>{},
    );
    final todayProgress = ref.watch(dailyProgressForDayProvider(today)).maybeWhen(
      data: (progress) => progress,
      orElse: () => null,
    );
    final activeProgress = ref.watch(dailyProgressProvider).maybeWhen(
      data: (progress) => progress,
      orElse: () => null,
    );

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
            final selected = day == active;
            final l1 = line1(day);
            final completion = completionByDay[day];
            var fraction = completion?.fraction ?? 0.0;
            var percentInt = completion?.percentInt ?? 0;
            if (day == today && todayProgress != null) {
              fraction = todayProgress.fraction;
              percentInt = todayProgress.percentInt;
            } else if (selected && activeProgress != null) {
              fraction = activeProgress.fraction;
              percentInt = activeProgress.percentInt;
            }
            final percentLabel = '$percentInt%';
            final fillColor = _fillColor(fraction, scheme);
            final labelColor = _labelColor(fraction, scheme);
            final secondaryLabelColor = _secondaryLabelColor(fraction, scheme);
            final borderColor = _selectionBorderColor(
              selected,
              fraction,
              scheme,
            );

            final chip = Material(
              key: _keyFor(day),
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(activeDayProvider.notifier).goToDay(day),
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
                        l1,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
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
              label: '$l1, $percentLabel',
              child: chip,
            );
          },
        ),
      ),
    );
  }
}
