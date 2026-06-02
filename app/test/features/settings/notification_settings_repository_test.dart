import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/db/app_database.dart';
import 'package:app/features/settings/data/app_settings_repository.dart';

void main() {
  late AppDatabase db;
  late AppSettingsRepository settingsRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('SELECT 1');
    settingsRepo = AppSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('EOD settings default to disabled at 21:30', () async {
    final settings = await settingsRepo.watchEodSettings().first;
    expect(settings.enabled, isFalse);
    expect(settings.hour, 21);
    expect(settings.minute, 30);
  });

  test('EOD settings round-trip', () async {
    await settingsRepo.setEodEnabled(true);
    await settingsRepo.setEodTime(22, 0);
    final settings = await settingsRepo.watchEodSettings().first;
    expect(settings.enabled, isTrue);
    expect(settings.hour, 22);
    expect(settings.minute, 0);
  });

  test('onboarding flag starts false and persists true', () async {
    expect(await settingsRepo.getNotificationOnboardingDone(), isFalse);
    await settingsRepo.setNotificationOnboardingDone(true);
    expect(await settingsRepo.getNotificationOnboardingDone(), isTrue);
  });
}
