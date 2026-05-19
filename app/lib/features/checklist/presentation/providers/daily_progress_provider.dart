import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../domain/daily_progress.dart';
import 'checklist_repositories_provider.dart';
import 'checklist_state_provider.dart';
import '../../../customization/presentation/providers/catalog_providers.dart';

final dailyProgressForDayProvider = Provider.autoDispose
    .family<AsyncValue<DailyProgress>, DayKey>((ref, day) {
  final catalog = ref.watch(effectiveCatalogProvider);
  final checklist = ref.watch(checklistStateForDayProvider(day));
  return catalog.when(
    data: (effective) {
      return checklist.when(
        data: (map) =>
            AsyncValue.data(DailyProgress.fromEffective(effective, map)),
        loading: () => const AsyncValue<DailyProgress>.loading(),
        error: (e, s) => AsyncValue<DailyProgress>.error(e, s),
      );
    },
    loading: () => const AsyncValue<DailyProgress>.loading(),
    error: (e, s) => AsyncValue<DailyProgress>.error(e, s),
  );
});

/// Progress for the day the user is currently viewing on the checklist.
final dailyProgressProvider = Provider<AsyncValue<DailyProgress>>((ref) {
  final day = ref.watch(activeDayProvider);
  return ref.watch(dailyProgressForDayProvider(day));
});
