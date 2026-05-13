import 'package:app/core/i18n/launch_locale.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';
import 'package:app/features/checklist/data/settings_repository.dart';
import 'package:app/features/checklist/data/static_task_catalog.dart';
import 'package:app/features/checklist/presentation/providers/checklist_repositories_provider.dart';
import 'package:app/features/checklist/presentation/providers/task_catalog_provider.dart';
import 'package:app/main.dart';
import 'package:app/core/time/day_key.dart';
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

void main() {
  testWidgets('Checklist screen shows Muhasabah title', (
    WidgetTester tester,
  ) async {
    persistedLocaleAtLaunch = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskCatalogProvider.overrideWith((ref) async => staticTaskCatalog),
          checklistRepositoryProvider.overrideWithValue(
            _FakeChecklistRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(),
          ),
        ],
        child: const MuhasabahApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muhasabah'), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });
}
