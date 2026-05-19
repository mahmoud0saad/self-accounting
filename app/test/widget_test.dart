import 'package:app/core/i18n/launch_locale.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';
import 'package:app/features/checklist/data/history_repository.dart';
import 'package:app/features/checklist/data/settings_repository.dart';
import 'package:app/features/checklist/data/static_task_catalog.dart';
import 'package:app/features/checklist/domain/day_completion.dart';
import 'package:app/features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'package:app/features/checklist/presentation/providers/history_repository_provider.dart';
import 'package:app/features/checklist/presentation/providers/task_catalog_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/checklist/presentation/checklist_screen.dart';
import 'package:app/core/time/day_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory checklist stream without Drift (avoids pending timers in tests).
class _FakeChecklistRepository implements ChecklistRepository {
  final Map<String, Map<String, bool>> _byDay = {};

  @override
  Future<Map<String, bool>> readDay(DayKey day) async =>
      Map<String, bool>.from(_byDay[day.toIsoDate()] ?? {});

  @override
  Future<void> resetDay(DayKey day) async {
    _byDay[day.toIsoDate()] = {};
  }

  @override
  Future<void> setCompletion({
    required DayKey day,
    required String taskId,
    required bool completed,
  }) async {
    final key = day.toIsoDate();
    _byDay.putIfAbsent(key, () => {});
    _byDay[key]![taskId] = completed;
  }

  @override
  Stream<Map<String, bool>> watchDay(DayKey day) {
    return Stream.multi((controller) {
      controller.add(Map<String, bool>.from(_byDay[day.toIsoDate()] ?? {}));
    }, isBroadcast: true);
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<String?> readLocaleOverride() async => null;

  @override
  Future<void> writeLocaleOverride(String? languageCode) async {}
}

/// Empty 7-day window for the history strip; the test only cares about the
/// AppBar title rendering, not the strip contents.
class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<DayCompletion>> readRange(DayKey start, DayKey end) async {
    return _build(start, end);
  }

  @override
  Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end) {
    return Stream<List<DayCompletion>>.value(_build(start, end));
  }

  List<DayCompletion> _build(DayKey start, DayKey end) {
    final span = end.daysSince(start);
    if (span < 0) return const [];
    final out = <DayCompletion>[];
    var cursor = start;
    for (var i = 0; i <= span; i++) {
      out.add(
        DayCompletion(
          day: cursor,
          completedPoints: 0,
          totalPoints: 74,
          completedTasks: 0,
          totalTasks: 34,
          fardMet: false,
        ),
      );
      cursor = cursor.nextDay();
    }
    return out;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('Checklist screen shows Muhasabah title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
          taskCatalogProvider.overrideWith((ref) async => staticTaskCatalog),
          checklistRepositoryProvider.overrideWithValue(
            _FakeChecklistRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChecklistScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Muhasabah'), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });
}
