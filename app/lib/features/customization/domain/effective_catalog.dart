import 'catalog_models.dart';
import 'fard_constants.dart';

/// Merges defaults, user-owned rows, and overrides into the checklist catalog.
EffectiveCatalog effectiveCatalog({
  required List<DefaultCategory> defaultCategories,
  required List<UserCategory> userCategories,
  required List<UserCategoryOverride> categoryOverrides,
  required List<DefaultTask> defaultTasks,
  required List<UserTask> userTasks,
  required List<UserTaskOverride> taskOverrides,
}) {
  final categoryOverrideByCode = {
    for (final o in categoryOverrides) o.categoryCode: o,
  };
  final taskOverrideByCode = {for (final o in taskOverrides) o.taskCode: o};

  final effectiveCategories = <EffectiveCategory>[];
  final categoryKeyByRef = <String, String>{};

  void registerCategoryKey(String ref, String key) {
    categoryKeyByRef[ref] = key;
  }

  for (final dc in defaultCategories) {
    final ov = categoryOverrideByCode[dc.code];
    if (ov?.hidden == true) {
      continue;
    }
    if (ov != null &&
        ov.customName != null &&
        isFardCategoryCode(dc.code)) {
      throw FardCategoryLockedError(
        'Cannot rename fard category "${dc.code}"',
      );
    }
    final key = dc.code;
    final ref = CategoryRef.defaultCategory(dc.code).value;
    registerCategoryKey(ref, key);
    effectiveCategories.add(
      EffectiveCategory(
        key: key,
        displayName: ov?.customName ?? dc.defaultName,
        icon: ov?.customIcon ?? dc.defaultIcon,
        sortOrder: ov?.sortOrder ?? dc.defaultSortOrder,
        isFard: dc.isFard,
        isUserOwned: false,
        defaultCode: dc.code,
      ),
    );
  }

  for (final uc in userCategories) {
    if (uc.isArchived) {
      continue;
    }
    final ref = CategoryRef.userCategory(uc.id).value;
    final key = 'user:${uc.id}';
    registerCategoryKey(ref, key);
    effectiveCategories.add(
      EffectiveCategory(
        key: key,
        displayName: uc.name,
        icon: uc.icon,
        sortOrder: uc.sortOrder,
        isFard: false,
        isUserOwned: true,
        userCategoryId: uc.id,
      ),
    );
  }

  effectiveCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final effectiveTasks = <EffectiveTask>[];

  String? resolveCategoryKey(String? categoryRef, String fallbackCode) {
    if (categoryRef == null) {
      return categoryKeyByRef[CategoryRef.defaultCategory(fallbackCode).value];
    }
    return categoryKeyByRef[categoryRef];
  }

  for (final dt in defaultTasks) {
    final ov = taskOverrideByCode[dt.code];
    if (ov?.hidden == true) {
      continue;
    }
    final catRef = ov?.customCategoryRef ??
        CategoryRef.defaultCategory(dt.categoryCode).value;
    final categoryKey = resolveCategoryKey(catRef, dt.categoryCode);
    if (categoryKey == null) {
      continue;
    }
    effectiveTasks.add(
      EffectiveTask(
        id: dt.code,
        displayName: ov?.customName ?? dt.defaultName,
        points: ov?.customPoints ?? dt.defaultPoints,
        icon: ov?.customIcon ?? dt.defaultIcon,
        categoryKey: categoryKey,
        sortOrder: ov?.sortOrder ?? dt.defaultSortOrder,
        isUserOwned: false,
        defaultCode: dt.code,
      ),
    );
  }

  for (final ut in userTasks) {
    if (ut.isArchived) {
      continue;
    }
    final categoryKey = categoryKeyByRef[ut.categoryRef];
    if (categoryKey == null) {
      continue;
    }
    effectiveTasks.add(
      EffectiveTask(
        id: ut.id,
        displayName: ut.name,
        points: ut.points,
        icon: ut.icon,
        categoryKey: categoryKey,
        sortOrder: ut.sortOrder,
        isUserOwned: true,
      ),
    );
  }

  effectiveTasks.sort((a, b) {
    final c = a.categoryKey.compareTo(b.categoryKey);
    if (c != 0) {
      return c;
    }
    return a.sortOrder.compareTo(b.sortOrder);
  });

  return EffectiveCatalog(
    categories: effectiveCategories,
    tasks: effectiveTasks,
  );
}

/// Validates an override write against fard rules before persisting.
void assertValidCategoryOverride({
  required String categoryCode,
  required bool hidden,
  String? customName,
}) {
  if (!isFardCategoryCode(categoryCode)) {
    return;
  }
  if (hidden) {
    throw FardCategoryLockedError('Fard category cannot be hidden: $categoryCode');
  }
  if (customName != null && customName.trim().isNotEmpty) {
    throw FardCategoryLockedError('Fard category cannot be renamed: $categoryCode');
  }
}
