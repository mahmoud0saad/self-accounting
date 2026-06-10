import 'package:app/features/customization/data/catalog_repository.dart';
import 'package:app/features/customization/domain/catalog_models.dart';
import 'package:app/l10n/app_localizations.dart';

/// No-op catalog repository for widget tests.
class FakeCatalogRepository implements CatalogRepository {
  @override
  Stream<EffectiveCatalog> watchEffective(
    AppLocalizations l, {
    bool forManage = false,
  }) =>
      const Stream.empty();

  @override
  Future<void> createUserCategory({
    required String name,
    required String icon,
    int sortOrder = 100,
  }) async {}

  @override
  Future<void> updateUserCategory(
    String id, {
    String? name,
    String? icon,
    int? sortOrder,
  }) async {}

  @override
  Future<void> deleteUserCategory(String id, {bool force = false}) async {}

  @override
  Future<void> upsertCategoryOverride({
    required String categoryCode,
    bool? hidden,
    String? customName,
    String? customIcon,
    int? sortOrder,
  }) async {}

  @override
  Future<void> createUserTask({
    required String name,
    required String categoryRef,
    required int points,
    required String icon,
    int sortOrder = 0,
  }) async {}

  @override
  Future<void> updateUserTask(
    String id, {
    String? name,
    String? categoryRef,
    int? points,
    String? icon,
    int? sortOrder,
  }) async {}

  @override
  Future<void> deleteUserTask(String id, {bool archive = false}) async {}

  @override
  Future<void> upsertTaskOverride({
    required String taskCode,
    bool? hidden,
    String? customName,
    int? customPoints,
    String? customIcon,
    String? customCategoryRef,
    int? sortOrder,
  }) async {}

  @override
  Future<void> setUserCategoryArchived(String id, bool archived) async {}

  @override
  Future<void> clearTaskOverride(String taskCode) async {}

  @override
  Future<void> clearCategoryOverride(String categoryCode) async {}

  @override
  Future<int> countDailyLogsForUserTask(String userTaskId) async => 0;

  @override
  Future<void> restoreUserTask(String id) async {}
}
