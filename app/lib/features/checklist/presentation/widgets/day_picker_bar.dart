import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/day_key.dart';
import '../providers/checklist_repositories_provider.dart';

class DayPickerBar extends ConsumerWidget {
  const DayPickerBar({super.key});

  static DayKey _oldestAllowed(DayKey today) {
    var d = today;
    for (var i = 0; i < kMaxHistoryDays; i++) {
      d = d.previousDay();
    }
    return d;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final active = ref.watch(activeDayProvider);
    final today = DayKey.today();
    final oldest = _oldestAllowed(today);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;

    String middleLabel() {
      if (active == today) {
        return l.dayLabelToday;
      }
      if (active == today.previousDay()) {
        return l.dayLabelYesterday;
      }
      return DateFormat.yMMMEd(
        locale.toLanguageTag(),
      ).format(active.toLocalDateTime());
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: active.toLocalDateTime(),
        firstDate: oldest.toLocalDateTime(),
        lastDate: today.toLocalDateTime(),
        locale: locale,
      );
      if (picked == null || !context.mounted) {
        return;
      }
      ref
          .read(activeDayProvider.notifier)
          .goToDay(DayKey.fromLocalDateTime(picked));
    }

    final canPrev = active.compareTo(oldest) > 0;
    final canNext = active.compareTo(today) < 0;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l.dayPickerPreviousLabel,
            onPressed: canPrev
                ? () => ref.read(activeDayProvider.notifier).goToPreviousDay()
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: scheme.primary,
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: pickDate,
                child: Text(
                  middleLabel(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l.dayPickerNextLabel,
            onPressed: canNext
                ? () => ref.read(activeDayProvider.notifier).goToNextDay()
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: scheme.primary,
          ),
        ],
      ),
    );
  }
}
