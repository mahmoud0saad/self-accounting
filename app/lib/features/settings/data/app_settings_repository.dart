import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/app_database_provider.dart';
import '../domain/eod_summary_settings.dart';

const notificationOnboardingDoneKey = 'notification_onboarding_done';
const customizationLastRestoredAtKey = 'customization_last_restored_at';
const _notificationsEnabledKey = 'notifications_enabled';
const _eodEnabledKey = 'eod_enabled';
const _eodHourKey = 'eod_hour';
const _eodMinuteKey = 'eod_minute';

class AppSettingsRepository {
  const AppSettingsRepository(this._db);

  final AppDatabase _db;

  Future<bool> getNotificationOnboardingDone() async {
    final value = await _read(notificationOnboardingDoneKey);
    return value == 'true';
  }

  Future<void> setNotificationOnboardingDone(bool value) {
    return _write(notificationOnboardingDoneKey, value.toString());
  }

  Stream<bool> watchNotificationsEnabled() {
    return (_db.select(_db.appSettings)
          ..where((s) => s.key.equals(_notificationsEnabledKey)))
        .watchSingleOrNull()
        .map((row) => row?.value != 'false');
  }

  Future<bool> getNotificationsEnabled() async {
    final value = await _read(_notificationsEnabledKey);
    return value != 'false';
  }

  Future<void> setNotificationsEnabled(bool enabled) {
    return _write(_notificationsEnabledKey, enabled.toString());
  }

  Stream<EodSummarySettings> watchEodSettings() {
    return (_db.select(_db.appSettings)..where(
          (s) => s.key.isIn([_eodEnabledKey, _eodHourKey, _eodMinuteKey]),
        ))
        .watch()
        .map((rows) {
          final values = {for (final row in rows) row.key: row.value};
          return EodSummarySettings(
            enabled: values[_eodEnabledKey] == 'true',
            hour: int.tryParse(values[_eodHourKey] ?? '') ?? 21,
            minute: int.tryParse(values[_eodMinuteKey] ?? '') ?? 30,
          );
        });
  }

  Future<void> setEodEnabled(bool enabled) {
    return _write(_eodEnabledKey, enabled.toString());
  }

  Future<void> setEodTime(int hour, int minute) async {
    await _write(_eodHourKey, hour.toString());
    await _write(_eodMinuteKey, minute.toString());
  }

  Future<DateTime?> getCustomizationLastRestoredAt() async {
    final raw = await _read(customizationLastRestoredAtKey);
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> setCustomizationLastRestoredAt(DateTime at) {
    return _write(customizationLastRestoredAtKey, at.toIso8601String());
  }

  Future<String?> readRaw(String key) => _read(key);

  Future<void> writeRaw(String key, String value) => _write(key, value);

  Future<String?> _read(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: Value(value)),
        );
  }
}

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(ref.watch(appDatabaseProvider));
});
