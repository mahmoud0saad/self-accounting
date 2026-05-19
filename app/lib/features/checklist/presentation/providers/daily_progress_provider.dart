import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_progress.dart';
import 'checklist_state_provider.dart';
import '../../../customization/presentation/providers/catalog_providers.dart';

final dailyProgressProvider = Provider<AsyncValue<DailyProgress>>((ref) {
  final catalog = ref.watch(effectiveCatalogProvider);
  final checklist = ref.watch(checklistStateProvider);
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
