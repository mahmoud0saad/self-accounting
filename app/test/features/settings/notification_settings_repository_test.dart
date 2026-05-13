import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/checklist/domain/task.dart';
import 'package:app/features/settings/data/app_settings_repository.dart';
import 'package:app/features/settings/data/notification_settings_repository.dart';

void main() {
  late AppDatabase db;
  late NotificationSettingsRepository repo;
  late AppSettingsRepository settingsRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('SELECT 1');
    repo = NotificationSettingsRepository(db);
    settingsRepo = AppSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('migration seeds 8 category rows', () async {
    expect(await repo.watchCategorySchedules().first, hasLength(8));
  });

  test('migration seeds 34 task rows', () async {
    expect(await repo.watchTaskToggles().first, hasLength(34));
  });

  test('toggle category off persists', () async {
    await repo.setCategoryEnabled(TaskCategory.fajr, false);
    final schedules = await repo.watchCategorySchedules().first;
    expect(
      schedules
          .firstWhere((schedule) => schedule.category == TaskCategory.fajr)
          .enabled,
      isFalse,
    );
  });

  test('update category time persists', () async {
    await repo.setCategoryTime(TaskCategory.fajr, 6, 15);
    final schedules = await repo.watchCategorySchedules().first;
    final fajr = schedules.firstWhere(
      (schedule) => schedule.category == TaskCategory.fajr,
    );
    expect(fajr.hour, 6);
    expect(fajr.minute, 15);
  });

  test('toggle task off persists', () async {
    await repo.setTaskEnabled('fajr_waking_up_adhkar', false);
    final toggles = await repo.watchTaskToggles().first;
    expect(
      toggles
          .firstWhere((toggle) => toggle.taskId == 'fajr_waking_up_adhkar')
          .notificationsEnabled,
      isFalse,
    );
  });

  test('EOD settings round-trip', () async {
    await settingsRepo.setEodEnabled(false);
    await settingsRepo.setEodTime(22, 0);
    final settings = await settingsRepo.watchEodSettings().first;
    expect(settings.enabled, isFalse);
    expect(settings.hour, 22);
    expect(settings.minute, 0);
  });

  test('onboarding flag starts false and persists true', () async {
    expect(await settingsRepo.getNotificationOnboardingDone(), isFalse);
    await settingsRepo.setNotificationOnboardingDone(true);
    expect(await settingsRepo.getNotificationOnboardingDone(), isTrue);
  });
}
