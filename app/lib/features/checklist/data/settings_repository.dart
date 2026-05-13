import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/launch_locale.dart';

abstract class SettingsRepository {
  Future<String?> readLocaleOverride();

  Future<void> writeLocaleOverride(String? languageCode);
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String?> readLocaleOverride() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(localeOverrideSettingsKey))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> writeLocaleOverride(String? languageCode) async {
    if (languageCode == null) {
      await (_db.delete(
        _db.appSettings,
      )..where((s) => s.key.equals(localeOverrideSettingsKey))).go();
      return;
    }
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: localeOverrideSettingsKey,
            value: Value(languageCode),
          ),
        );
  }
}
