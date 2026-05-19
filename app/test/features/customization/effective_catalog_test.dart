import 'package:app/features/customization/domain/catalog_models.dart';
import 'package:app/features/customization/domain/effective_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

DefaultCategory _dc(
  String code, {
  String name = '',
  int order = 0,
  bool fard = false,
  String icon = 'mosque',
}) =>
    DefaultCategory(
      code: code,
      defaultName: name.isEmpty ? code : name,
      defaultIcon: icon,
      defaultSortOrder: order,
      isFard: fard,
    );

DefaultTask _dt(
  String code,
  String category, {
  String name = '',
  int points = 2,
  int order = 0,
}) =>
    DefaultTask(
      code: code,
      defaultName: name.isEmpty ? code : name,
      categoryCode: category,
      defaultPoints: points,
      defaultIcon: 'star',
      defaultSortOrder: order,
    );

void main() {
  final defaults = [
    _dc('fajr', order: 0, fard: true),
    _dc('dhuhr', order: 1, fard: true),
    _dc('miscAdhkar', order: 7, name: 'Misc'),
  ];

  final defaultTasks = [
    _dt('fajr_first_congregation', 'fajr', name: 'Fajr jamaah'),
    _dt('misc_restroom_adhkar', 'miscAdhkar', name: 'Restroom'),
  ];

  group('effectiveCatalog', () {
    test('empty user data returns all defaults', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      expect(cat.categories.length, 3);
      expect(cat.tasks.length, 2);
      expect(cat.totalPoints, 4);
    });

    test('hidden default category removes its tasks', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [
          UserCategoryOverride(categoryCode: 'miscAdhkar', hidden: true),
        ],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      expect(cat.categories.any((c) => c.defaultCode == 'miscAdhkar'), false);
      expect(cat.tasks.any((t) => t.defaultCode == 'misc_restroom_adhkar'), false);
    });

    test('hidden default task via override', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [
          UserTaskOverride(taskCode: 'fajr_first_congregation', hidden: true),
        ],
      );
      expect(cat.tasks.length, 1);
    });

    test('override points on default task', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [
          UserTaskOverride(taskCode: 'fajr_first_congregation', customPoints: 8),
        ],
      );
      final t = cat.tasks.firstWhere((t) => t.defaultCode == 'fajr_first_congregation');
      expect(t.points, 8);
    });

    test('override name on default task', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [
          UserTaskOverride(
            taskCode: 'fajr_first_congregation',
            customName: 'Fajr in masjid',
          ),
        ],
      );
      expect(
        cat.tasks.firstWhere((t) => t.defaultCode == 'fajr_first_congregation').displayName,
        'Fajr in masjid',
      );
    });

    test('user category and user task appear', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(
            id: 'uc1',
            name: 'Quran study',
            icon: 'menu_book',
            sortOrder: 50,
          ),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [
          UserTask(
            id: 'ut1',
            categoryRef: 'userCategory:uc1',
            name: 'Memorize 5 ayat',
            points: 10,
            icon: 'book_5',
            sortOrder: 0,
          ),
        ],
        taskOverrides: const [],
      );
      expect(cat.categories.any((c) => c.userCategoryId == 'uc1'), true);
      expect(cat.tasks.any((t) => t.id == 'ut1' && t.points == 10), true);
      expect(cat.totalPoints, 14);
    });

    test('archived user category excluded', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: [
          UserCategory(
            id: 'uc1',
            name: 'Gone',
            icon: 'star',
            sortOrder: 50,
            archivedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [
          UserTask(
            id: 'ut1',
            categoryRef: 'userCategory:uc1',
            name: 'Orphan',
            points: 2,
            icon: 'star',
            sortOrder: 0,
          ),
        ],
        taskOverrides: const [],
      );
      expect(cat.categories.any((c) => c.userCategoryId == 'uc1'), false);
      expect(cat.tasks.any((t) => t.id == 'ut1'), false);
    });

    test('archived user task excluded', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(id: 'uc1', name: 'Study', icon: 'star', sortOrder: 50),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: [
          UserTask(
            id: 'ut1',
            categoryRef: 'userCategory:uc1',
            name: 'Done',
            points: 2,
            icon: 'star',
            sortOrder: 0,
            archivedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        taskOverrides: const [],
      );
      expect(cat.tasks.any((t) => t.id == 'ut1'), false);
    });

    test('move default task to user category via override', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(id: 'uc1', name: 'Study', icon: 'star', sortOrder: 50),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [
          UserTaskOverride(
            taskCode: 'misc_restroom_adhkar',
            customCategoryRef: 'userCategory:uc1',
          ),
        ],
      );
      final t = cat.tasks.firstWhere((t) => t.defaultCode == 'misc_restroom_adhkar');
      expect(t.categoryKey, 'user:uc1');
    });

    test('category sort order from override', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [
          UserCategoryOverride(categoryCode: 'fajr', sortOrder: 99),
        ],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      final fajr = cat.categories.firstWhere((c) => c.defaultCode == 'fajr');
      expect(fajr.sortOrder, 99);
    });

    test('fard rename override throws', () {
      expect(
        () => effectiveCatalog(
          defaultCategories: defaults,
          userCategories: const [],
          categoryOverrides: const [
            UserCategoryOverride(categoryCode: 'fajr', customName: 'Subh'),
          ],
          defaultTasks: defaultTasks,
          userTasks: const [],
          taskOverrides: const [],
        ),
        throwsA(isA<FardCategoryLockedError>()),
      );
    });

    test('assertValidCategoryOverride blocks fard hide', () {
      expect(
        () => assertValidCategoryOverride(
          categoryCode: 'fajr',
          hidden: true,
        ),
        throwsA(isA<FardCategoryLockedError>()),
      );
    });

    test('tasksByCategoryKey groups correctly', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      final grouped = cat.tasksByCategoryKey();
      expect(grouped['fajr']?.length, 1);
    });

    for (var i = 0; i < 15; i++) {
      test('property: hiding task $i reduces count', () {
        final code = defaultTasks[i % defaultTasks.length].code;
        final base = effectiveCatalog(
          defaultCategories: defaults,
          userCategories: const [],
          categoryOverrides: const [],
          defaultTasks: defaultTasks,
          userTasks: const [],
          taskOverrides: const [],
        );
        final hidden = effectiveCatalog(
          defaultCategories: defaults,
          userCategories: const [],
          categoryOverrides: const [],
          defaultTasks: defaultTasks,
          userTasks: const [],
          taskOverrides: [UserTaskOverride(taskCode: code, hidden: true)],
        );
        expect(hidden.tasks.length, base.tasks.length - 1);
      });
    }

    test('custom icon on category override', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [
          UserCategoryOverride(categoryCode: 'miscAdhkar', customIcon: 'spa'),
        ],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      final misc = cat.categories.firstWhere((c) => c.defaultCode == 'miscAdhkar');
      expect(misc.icon, 'spa');
    });

    test('points cap respected in user task', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(id: 'uc1', name: 'X', icon: 'star', sortOrder: 50),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [
          UserTask(
            id: 'ut1',
            categoryRef: 'userCategory:uc1',
            name: 'Big',
            points: 20,
            icon: 'star',
            sortOrder: 0,
          ),
        ],
        taskOverrides: const [],
      );
      expect(cat.tasks.firstWhere((t) => t.id == 'ut1').points, 20);
    });

    test('multiple user tasks same category', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(id: 'uc1', name: 'X', icon: 'star', sortOrder: 50),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [
          UserTask(
            id: 'ut1',
            categoryRef: 'userCategory:uc1',
            name: 'A',
            points: 2,
            icon: 'star',
            sortOrder: 0,
          ),
          UserTask(
            id: 'ut2',
            categoryRef: 'userCategory:uc1',
            name: 'B',
            points: 3,
            icon: 'star',
            sortOrder: 1,
          ),
        ],
        taskOverrides: const [],
      );
      expect(cat.tasks.where((t) => t.isUserOwned).length, 2);
    });

    test('CategoryRef parse roundtrip', () {
      final ref = CategoryRef.defaultCategory('fajr');
      expect(CategoryRef.parse(ref.value).codeOrId, 'fajr');
    });

    test('invalid CategoryRef throws', () {
      expect(() => CategoryRef.parse('bad'), throwsFormatException);
    });

    test('non-fard category can be hidden via override', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [],
        categoryOverrides: const [
          UserCategoryOverride(categoryCode: 'dhuhr', hidden: true),
        ],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      expect(cat.categories.any((c) => c.defaultCode == 'dhuhr'), false);
    });

    test('reorder: user category before default when sort lower', () {
      final cat = effectiveCatalog(
        defaultCategories: defaults,
        userCategories: const [
          UserCategory(id: 'uc1', name: 'Early', icon: 'star', sortOrder: -1),
        ],
        categoryOverrides: const [],
        defaultTasks: defaultTasks,
        userTasks: const [],
        taskOverrides: const [],
      );
      expect(cat.categories.first.key, 'user:uc1');
    });
  });
}
