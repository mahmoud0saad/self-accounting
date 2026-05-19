/// Reference to a category: `category:<code>` or `userCategory:<id>`.
class CategoryRef {
  const CategoryRef._(this.value);

  final String value;

  factory CategoryRef.defaultCategory(String code) =>
      CategoryRef._('category:$code');

  factory CategoryRef.userCategory(String id) => CategoryRef._('userCategory:$id');

  static CategoryRef parse(String raw) {
    if (!raw.startsWith('category:') && !raw.startsWith('userCategory:')) {
      throw FormatException('Invalid category ref: $raw');
    }
    return CategoryRef._(raw);
  }

  bool get isDefault => value.startsWith('category:');

  String get codeOrId =>
      isDefault ? value.substring('category:'.length) : value.substring('userCategory:'.length);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryRef && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class DefaultCategory {
  const DefaultCategory({
    required this.code,
    required this.defaultName,
    required this.defaultIcon,
    required this.defaultSortOrder,
    required this.isFard,
  });

  final String code;
  final String defaultName;
  final String defaultIcon;
  final int defaultSortOrder;
  final bool isFard;
}

class UserCategory {
  const UserCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}

class UserCategoryOverride {
  const UserCategoryOverride({
    required this.categoryCode,
    this.hidden = false,
    this.customName,
    this.customIcon,
    this.sortOrder,
  });

  final String categoryCode;
  final bool hidden;
  final String? customName;
  final String? customIcon;
  final int? sortOrder;
}

class DefaultTask {
  const DefaultTask({
    required this.code,
    required this.defaultName,
    required this.categoryCode,
    required this.defaultPoints,
    required this.defaultIcon,
    required this.defaultSortOrder,
  });

  final String code;
  final String defaultName;
  final String categoryCode;
  final int defaultPoints;
  final String defaultIcon;
  final int defaultSortOrder;
}

class UserTask {
  const UserTask({
    required this.id,
    required this.categoryRef,
    required this.name,
    required this.points,
    required this.icon,
    required this.sortOrder,
    this.archivedAt,
    this.description,
    this.recurrence,
    this.kind = 'TASK',
  });

  final String id;
  final String categoryRef;
  final String name;
  final int points;
  final String icon;
  final int sortOrder;
  final DateTime? archivedAt;
  final String? description;
  final String? recurrence;
  final String kind;

  bool get isArchived => archivedAt != null;
}

class UserTaskOverride {
  const UserTaskOverride({
    required this.taskCode,
    this.hidden = false,
    this.customName,
    this.customPoints,
    this.customIcon,
    this.customCategoryRef,
    this.sortOrder,
  });

  final String taskCode;
  final bool hidden;
  final String? customName;
  final int? customPoints;
  final String? customIcon;
  final String? customCategoryRef;
  final int? sortOrder;
}

/// Resolved category visible on the checklist.
class EffectiveCategory {
  const EffectiveCategory({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.sortOrder,
    required this.isFard,
    required this.isUserOwned,
    this.defaultCode,
    this.userCategoryId,
  });

  /// Stable key for grouping: default code or `user:<id>`.
  final String key;
  final String displayName;
  final String icon;
  final int sortOrder;
  final bool isFard;
  final bool isUserOwned;
  final String? defaultCode;
  final String? userCategoryId;
}

/// Resolved task visible on the checklist.
class EffectiveTask {
  const EffectiveTask({
    required this.id,
    required this.displayName,
    required this.points,
    required this.icon,
    required this.categoryKey,
    required this.sortOrder,
    required this.isUserOwned,
    this.defaultCode,
  });

  final String id;
  final String displayName;
  final int points;
  final String icon;
  final String categoryKey;
  final int sortOrder;
  final bool isUserOwned;
  final String? defaultCode;
}

class EffectiveCatalog {
  const EffectiveCatalog({
    required this.categories,
    required this.tasks,
  });

  final List<EffectiveCategory> categories;
  final List<EffectiveTask> tasks;

  int get totalPoints =>
      tasks.fold<int>(0, (sum, t) => sum + t.points);

  Map<String, List<EffectiveTask>> tasksByCategoryKey() {
    final map = <String, List<EffectiveTask>>{};
    for (final t in tasks) {
      map.putIfAbsent(t.categoryKey, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }
}

class FardCategoryLockedError implements Exception {
  FardCategoryLockedError(this.message);
  final String message;
  @override
  String toString() => message;
}
