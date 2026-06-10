import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import 'checklist_repositories_provider.dart';
import 'checklist_state_provider.dart';

class EffectiveTaskRowState {
  const EffectiveTaskRowState({
    required this.readOnly,
    required this.isChecked,
    required this.challengeVisual,
  });

  final bool readOnly;
  final bool isChecked;
  final TaskChallengeVisualState challengeVisual;

  bool get showWeekComplete =>
      challengeVisual == TaskChallengeVisualState.weekComplete;
}

final effectiveTaskRowStateProvider =
    Provider.family<EffectiveTaskRowState, String>((ref, taskId) {
  final activeDay = ref.watch(activeDayProvider);
  final today = DayKey.today();
  final daysAgo = today.daysSince(activeDay);
  final readOnly = daysAgo < 0 || daysAgo >= kMaxEditableDays;

  final isChecked = ref.watch(
    checklistStateProvider.select(
      (async) => async.maybeWhen(
        data: (m) => m[taskId] ?? false,
        orElse: () => false,
      ),
    ),
  );
  final challengeVisual = ref.watch(taskChallengeVisualForTaskProvider(taskId));

  return EffectiveTaskRowState(
    readOnly: readOnly,
    isChecked: isChecked,
    challengeVisual: challengeVisual,
  );
});

Color? effectiveTaskRowChallengeFillColor(
  TaskChallengeVisualState visual,
  ColorScheme scheme,
  bool readOnly,
) {
  return switch (visual) {
    TaskChallengeVisualState.pending =>
      scheme.secondaryContainer.withValues(alpha: readOnly ? 0.12 : 0.18),
    TaskChallengeVisualState.contributed =>
      scheme.secondaryContainer.withValues(alpha: readOnly ? 0.22 : 0.35),
    _ => null,
  };
}

Border effectiveTaskRowChallengeBorder(
  TaskChallengeVisualState visual,
  ColorScheme scheme,
  bool readOnly,
) {
  return switch (visual) {
    TaskChallengeVisualState.pending => Border.all(
      color: scheme.outline.withValues(alpha: readOnly ? 0.3 : 0.45),
      width: 1.5,
    ),
    TaskChallengeVisualState.contributed => Border.all(
      color: scheme.secondary.withValues(alpha: readOnly ? 0.55 : 1.0),
      width: 1.5,
    ),
    _ => Border.all(
      color: scheme.outline.withValues(alpha: 0),
      width: 1.5,
    ),
  };
}
