import 'package:app/core/time/day_key.dart';
import 'package:app/features/challenges/domain/challenge_models.dart';
import 'package:app/features/challenges/domain/week_boundary.dart';
import 'package:app/features/challenges/presentation/providers/challenge_providers.dart';
import 'package:app/features/checklist/presentation/providers/calendar_today_provider.dart';
import 'package:app/features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'package:app/features/checklist/presentation/providers/checklist_state_provider.dart';
import 'package:app/features/checklist/presentation/widgets/effective_task_row.dart';
import 'package:app/features/customization/domain/catalog_models.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _task = EffectiveTask(
  id: 'fajr_first_congregation',
  displayName: 'First congregation',
  points: 2,
  icon: 'mosque',
  categoryKey: 'fajr',
  sortOrder: 0,
  isUserOwned: false,
);

UserChallenge _taskChallenge({required String id}) {
  return UserChallenge(
    id: id,
    templateCode: 'fajr_in_jamaah',
    startedAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    template: const ChallengeTemplate(
      code: 'fajr_in_jamaah',
      defaultTitle: 'Pray every Fajr in congregation',
      defaultIcon: 'mosque',
      sourceKind: 'TASK_WEEKLY_COUNT',
      sourceRef: 'fajr_first_congregation',
      goalCount: 7,
      defaultSortOrder: 0,
      isActive: true,
    ),
  );
}

UserChallenge _categoryChallenge({required String id}) {
  return UserChallenge(
    id: id,
    templateCode: 'fajr_category_all_week',
    startedAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    template: const ChallengeTemplate(
      code: 'fajr_category_all_week',
      defaultTitle: 'Complete the Fajr block every day',
      defaultIcon: 'wb_twilight',
      sourceKind: 'CATEGORY_WEEKLY_COUNT',
      sourceRef: 'fajr',
      goalCount: 7,
      defaultSortOrder: 1,
      isActive: true,
    ),
  );
}

ChallengeWeek _week({
  required String challengeId,
  required String status,
  String weekStart = '2026-06-07',
  String weekEnd = '2026-06-13',
}) {
  return ChallengeWeek(
    id: 'week-$challengeId',
    userChallengeId: challengeId,
    weekStart: weekStart,
    weekEnd: weekEnd,
    goalCount: 7,
    achievedCount: status == 'COMPLETED' ? 7 : 2,
    status: status,
    updatedAt: DateTime.utc(2026, 6, 7),
  );
}

class _FixedActiveDayNotifier extends ActiveDayNotifier {
  _FixedActiveDayNotifier(this.day);

  final DayKey day;

  @override
  DayKey build() => day;
}

class _FixedCalendarTodayNotifier extends CalendarTodayNotifier {
  _FixedCalendarTodayNotifier(this.day);

  final DayKey day;

  @override
  DayKey build() => day;
}

Widget _taskRowHarness({required overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(body: EffectiveTaskRow(task: _task)),
    ),
  );
}

void main() {
  group('taskChallengeVisualLookupProvider', () {
    test('returns pending when task challenge is active and unchecked', () {
      final today = DayKey(year: 2026, month: 6, day: 7);
      final challenge = _taskChallenge(id: 'c1');
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          calendarTodayProvider
              .overrideWith(() => _FixedCalendarTodayNotifier(today)),
          weekStartDowProvider.overrideWith(
            () => _SyncWeekStartDowNotifier(WeekStartDow.sat),
          ),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {'fajr_first_congregation': false}),
          ),
          currentWeekProgressProvider.overrideWith(
            (ref) => Future.value([
              ChallengeWithWeek(
                challenge: challenge,
                week: _week(challengeId: challenge.id, status: 'IN_PROGRESS'),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(taskChallengeVisualLookupProvider);
      expect(
        lookup.forTask('fajr_first_congregation'),
        TaskChallengeVisualState.pending,
      );
    });

    test('returns contributed when task is checked on active day', () {
      final today = DayKey(year: 2026, month: 6, day: 7);
      final challenge = _taskChallenge(id: 'c1');
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          calendarTodayProvider
              .overrideWith(() => _FixedCalendarTodayNotifier(today)),
          weekStartDowProvider.overrideWith(
            () => _SyncWeekStartDowNotifier(WeekStartDow.sat),
          ),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {'fajr_first_congregation': true}),
          ),
          currentWeekProgressProvider.overrideWith(
            (ref) => Future.value([
              ChallengeWithWeek(
                challenge: challenge,
                week: _week(challengeId: challenge.id, status: 'IN_PROGRESS'),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(taskChallengeVisualLookupProvider);
      expect(
        lookup.forTask('fajr_first_congregation'),
        TaskChallengeVisualState.contributed,
      );
    });

    test('returns weekComplete when challenge goal is met', () {
      final today = DayKey(year: 2026, month: 6, day: 7);
      final challenge = _taskChallenge(id: 'c1');
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          calendarTodayProvider
              .overrideWith(() => _FixedCalendarTodayNotifier(today)),
          weekStartDowProvider.overrideWith(
            () => _SyncWeekStartDowNotifier(WeekStartDow.sat),
          ),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {'fajr_first_congregation': true}),
          ),
          currentWeekProgressProvider.overrideWith(
            (ref) => Future.value([
              ChallengeWithWeek(
                challenge: challenge,
                week: _week(challengeId: challenge.id, status: 'COMPLETED'),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(taskChallengeVisualLookupProvider);
      expect(
        lookup.forTask('fajr_first_congregation'),
        TaskChallengeVisualState.weekComplete,
      );
    });

    test('ignores category-level challenges', () {
      final today = DayKey(year: 2026, month: 6, day: 7);
      final challenge = _categoryChallenge(id: 'c2');
      final container = ProviderContainer(
        overrides: [
          activeDayProvider.overrideWith(() => _FixedActiveDayNotifier(today)),
          calendarTodayProvider
              .overrideWith(() => _FixedCalendarTodayNotifier(today)),
          weekStartDowProvider.overrideWith(
            () => _SyncWeekStartDowNotifier(WeekStartDow.sat),
          ),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {'fajr_first_congregation': false}),
          ),
          currentWeekProgressProvider.overrideWith(
            (ref) => Future.value([
              ChallengeWithWeek(
                challenge: challenge,
                week: _week(challengeId: challenge.id, status: 'IN_PROGRESS'),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(taskChallengeVisualLookupProvider);
      expect(
        lookup.forTask('fajr_first_congregation'),
        TaskChallengeVisualState.none,
      );
    });

    test('returns none when active day is outside challenge week', () {
      final today = DayKey(year: 2026, month: 6, day: 7);
      final outsideWeek = DayKey(year: 2026, month: 5, day: 1);
      final challenge = _taskChallenge(id: 'c1');
      final container = ProviderContainer(
        overrides: [
          activeDayProvider
              .overrideWith(() => _FixedActiveDayNotifier(outsideWeek)),
          calendarTodayProvider
              .overrideWith(() => _FixedCalendarTodayNotifier(today)),
          weekStartDowProvider.overrideWith(
            () => _SyncWeekStartDowNotifier(WeekStartDow.sat),
          ),
          checklistStateProvider.overrideWith(
            (ref) => Stream.value(const {'fajr_first_congregation': false}),
          ),
          currentWeekProgressProvider.overrideWith(
            (ref) => Future.value([
              ChallengeWithWeek(
                challenge: challenge,
                week: _week(challengeId: challenge.id, status: 'IN_PROGRESS'),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(taskChallengeVisualLookupProvider);
      expect(
        lookup.forTask('fajr_first_congregation'),
        TaskChallengeVisualState.none,
      );
    });
  });

  group('EffectiveTaskRow challenge styling', () {
    testWidgets('shows pending flag icon and semantics', (tester) async {
      await tester.pumpWidget(
        _taskRowHarness(
          overrides: [
            taskChallengeVisualLookupProvider.overrideWith(
              (ref) => const TaskChallengeVisualLookup({
                'fajr_first_congregation': TaskChallengeVisualState.pending,
              }),
            ),
            checklistStateProvider.overrideWith(
              (ref) => Stream.value(const {'fajr_first_congregation': false}),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.outlined_flag_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'First congregation, 2 points, not checked, '
            r'Counts toward your challenge — not done on this day',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Completed this week'), findsNothing);
    });

    testWidgets('shows contributed flag icon and semantics', (tester) async {
      await tester.pumpWidget(
        _taskRowHarness(
          overrides: [
            taskChallengeVisualLookupProvider.overrideWith(
              (ref) => const TaskChallengeVisualLookup({
                'fajr_first_congregation':
                    TaskChallengeVisualState.contributed,
              }),
            ),
            checklistStateProvider.overrideWith(
              (ref) => Stream.value(const {'fajr_first_congregation': true}),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'First congregation, 2 points, checked, '
            r'This day counts toward your challenge',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows week-complete pill without challenge border icon',
        (tester) async {
      await tester.pumpWidget(
        _taskRowHarness(
          overrides: [
            taskChallengeVisualLookupProvider.overrideWith(
              (ref) => const TaskChallengeVisualLookup({
                'fajr_first_congregation':
                    TaskChallengeVisualState.weekComplete,
              }),
            ),
            checklistStateProvider.overrideWith(
              (ref) => Stream.value(const {'fajr_first_congregation': true}),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Completed this week'), findsOneWidget);
      expect(find.byIcon(Icons.outlined_flag_rounded), findsNothing);
      expect(find.byIcon(Icons.flag_rounded), findsNothing);
    });

    testWidgets('shows no challenge affordance when state is none',
        (tester) async {
      await tester.pumpWidget(
        _taskRowHarness(
          overrides: [
            taskChallengeVisualLookupProvider.overrideWith(
              (ref) => TaskChallengeVisualLookup.empty,
            ),
            checklistStateProvider.overrideWith(
              (ref) => Stream.value(const {'fajr_first_congregation': false}),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.outlined_flag_rounded), findsNothing);
      expect(find.byIcon(Icons.flag_rounded), findsNothing);
      expect(find.text('Completed this week'), findsNothing);
    });
  });
}

class _SyncWeekStartDowNotifier extends WeekStartDowNotifier {
  _SyncWeekStartDowNotifier(this.value);

  final WeekStartDow value;

  @override
  Future<WeekStartDow> build() async => value;
}
