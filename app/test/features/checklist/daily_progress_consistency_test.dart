import 'package:app/core/time/day_key.dart';
import 'package:app/features/checklist/data/drift_history_repository.dart';
import 'package:app/features/checklist/domain/daily_progress.dart';
import 'package:app/features/checklist/domain/day_completion.dart';
import 'package:app/features/customization/domain/catalog_models.dart';
import 'package:app/features/customization/domain/effective_catalog.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/checklist/data/checklist_repository.dart';

DefaultCategory _dc(String code, {int order = 0, bool fard = false}) =>
    DefaultCategory(
      code: code,
      defaultName: code,
      defaultIcon: 'mosque',
      defaultSortOrder: order,
      isFard: fard,
    );

DefaultTask _dt(String code, String category, {int points = 2}) => DefaultTask(
      code: code,
      defaultName: code,
      categoryCode: category,
      defaultPoints: points,
      defaultIcon: 'star',
      defaultSortOrder: 0,
    );

void main() {
  group('daily progress consistency', () {
    test(
      'custom points on effective catalog differ from static DayCompletion percent',
      () {
        final catalog = effectiveCatalog(
          defaultCategories: [_dc('fajr', fard: true), _dc('misc')],
          userCategories: const [],
          categoryOverrides: const [],
          defaultTasks: [
            _dt('fajr_first_congregation', 'fajr', points: 2),
            _dt('misc_restroom_adhkar', 'misc', points: 2),
          ],
          userTasks: const [],
          taskOverrides: const [
            UserTaskOverride(
              taskCode: 'fajr_first_congregation',
              customPoints: 8,
            ),
          ],
        );

        const state = {'fajr_first_congregation': true};
        final progress = DailyProgress.fromEffective(catalog, state);

        // History repository uses static catalog points (2) and full static total.
        final historySummary = DayCompletion(
          day: const DayKey(year: 2026, month: 6, day: 1),
          completedPoints: 2,
          totalPoints: 74,
          completedTasks: 1,
          totalTasks: 34,
          fardMet: false,
        );

        expect(progress.completedPoints, 8);
        expect(progress.totalPoints, 10);
        expect(progress.percentInt, 80);
        expect(historySummary.percentInt, 3);
        expect(progress.percentInt, isNot(historySummary.percentInt));
      },
    );

    test(
      'DriftHistoryRepository and DailyProgress.fromEffective can disagree after customization',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        await db.seedAndReconcile();
        final checklist = DriftChecklistRepository(db);
        final history = DriftHistoryRepository(db);

        const day = DayKey(year: 2026, month: 6, day: 2);
        await checklist.setCompletion(
          day: day,
          taskId: 'fajr_first_congregation',
          completed: true,
        );

        final historyDay = (await history.readRange(day, day)).single;
        final state = await checklist.readDay(day);

        final minimalCatalog = effectiveCatalog(
          defaultCategories: [_dc('fajr', fard: true)],
          userCategories: const [],
          categoryOverrides: const [],
          defaultTasks: [
            _dt('fajr_first_congregation', 'fajr', points: 2),
            _dt('fajr_waking_up_adhkar', 'fajr', points: 2),
          ],
          userTasks: const [],
          taskOverrides: const [
            UserTaskOverride(
              taskCode: 'fajr_first_congregation',
              customPoints: 8,
            ),
          ],
        );

        final progress = DailyProgress.fromEffective(minimalCatalog, state);

        expect(historyDay.completedPoints, 2);
        expect(historyDay.totalPoints, 74);
        expect(progress.completedPoints, 8);
        expect(progress.totalPoints, 10);
        expect(progress.percentInt, isNot(historyDay.percentInt));

        await db.close();
      },
    );
  });
}
