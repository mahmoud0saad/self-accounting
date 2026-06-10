import 'package:app/core/time/day_key.dart';
import 'package:app/features/challenges/presentation/providers/challenge_providers.dart';
import 'package:app/features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'package:app/features/checklist/presentation/providers/checklist_state_provider.dart';
import 'package:app/features/checklist/presentation/providers/effective_task_row_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _taskId = 'fajr_first_congregation';

class _FixedActiveDayNotifier extends ActiveDayNotifier {
  _FixedActiveDayNotifier(this.day);

  final DayKey day;

  @override
  DayKey build() => day;
}

void main() {
  group('effectiveTaskRowStateProvider', () {
    test('readOnly is false for today', () {
      final today = DayKey.today();
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: false}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => TaskChallengeVisualLookup.empty,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.readOnly, isFalse);
    });

    test('readOnly is false for yesterday', () {
      final yesterday = DayKey.today().previousDay();
      final container = ProviderContainer(
        overrides: [
          activeDayProvider
              .overrideWith(() => _FixedActiveDayNotifier(yesterday)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: false}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => TaskChallengeVisualLookup.empty,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.readOnly, isFalse);
    });

    test('readOnly is true when active day is beyond kMaxEditableDays', () {
      var oldDay = DayKey.today();
      for (var i = 0; i < kMaxEditableDays; i++) {
        oldDay = oldDay.previousDay();
      }
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(oldDay)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: false}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => TaskChallengeVisualLookup.empty,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.readOnly, isTrue);
    });

    test('readOnly is true when active day is in the future', () {
      final futureDay = DayKey.today().nextDay();
      final container = ProviderContainer(
        overrides: [
          activeDayProvider
              .overrideWith(() => _FixedActiveDayNotifier(futureDay)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: false}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => TaskChallengeVisualLookup.empty,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.readOnly, isTrue);
    });

    test('isChecked tracks checklist map', () {
      final today = DayKey.today();
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: true}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => TaskChallengeVisualLookup.empty,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.isChecked, isTrue);
    });

    test('challengeVisual and showWeekComplete track challenge lookup', () {
      final today = DayKey.today();
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {_taskId: true}),
          ),
          taskChallengeVisualLookupProvider.overrideWith(
            (ref) => const TaskChallengeVisualLookup({
              _taskId: TaskChallengeVisualState.weekComplete,
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(effectiveTaskRowStateProvider(_taskId));
      expect(state.challengeVisual, TaskChallengeVisualState.weekComplete);
      expect(state.showWeekComplete, isTrue);
    });
  });
}
