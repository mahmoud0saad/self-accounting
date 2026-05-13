import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/day_key.dart';
import '../providers/checklist_repositories_provider.dart';

/// Horizontal scroll of the last 30 calendar days as tappable chips (tabs).
/// Order: Today → Yesterday → older days. [activeDayProvider] drives selection.
class DayPickerBar extends ConsumerStatefulWidget {
  const DayPickerBar({super.key});

  static const int _visibleDays = 30;

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
    final today = DayKey.today();
    final oldest = DayPickerBar._oldestAllowed(today);
    final active = ref.read(activeDayProvider);
    _scrollToActive(active, _buildDayKeys(today, oldest));
  }

  List<DayKey> _buildDayKeys(DayKey today, DayKey oldest) {
    final keys = <DayKey>[];
    var d = today;
    for (var i = 0; i < DayPickerBar._visibleDays; i++) {
      if (d.compareTo(oldest) < 0) {
        break;
      }
      keys.add(d);
      d = d.previousDay();
    }
    return keys;
  }

  GlobalKey _keyFor(DayKey day) =>
      _keys.putIfAbsent(day, GlobalKey.new);

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
    final today = DayKey.today();
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
      _scrollToActive(next, _buildDayKeys(DayKey.today(), oldest));
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

    String? line2(DayKey day) {
      if (day == today || day == today.previousDay()) {
        return null;
      }
      return DateFormat.MMMd(tag).format(day.toLocalDateTime());
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dayKeys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final day = dayKeys[index];
            final selected = day == active;
            final l1 = line1(day);
            final l2 = line2(day);

            final chip = Material(
              key: _keyFor(day),
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    ref.read(activeDayProvider.notifier).goToDay(day),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outlineVariant,
                      width: selected ? 0 : 1,
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
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                      if (l2 != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          l2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: selected
                                ? scheme.onPrimary.withValues(alpha: 0.92)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            return Semantics(
              button: true,
              selected: selected,
              label: l1 + (l2 != null ? ', $l2' : ''),
              child: chip,
            );
          },
        ),
      ),
    );
  }
}
