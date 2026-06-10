import 'package:app/features/customization/domain/catalog_models.dart';
import 'fake_catalog_repository.dart';
import 'package:app/features/customization/domain/effective_catalog.dart';
import 'package:app/features/customization/presentation/manage_checklist_screen.dart';
import 'package:app/features/customization/presentation/providers/catalog_providers.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

EffectiveCatalog _sampleManageCatalog() {
  return effectiveCatalog(
    defaultCategories: [
      const DefaultCategory(
        code: 'fajr',
        defaultName: 'Fajr',
        defaultIcon: 'wb_twilight',
        defaultSortOrder: 0,
        isFard: true,
      ),
      const DefaultCategory(
        code: 'misc',
        defaultName: 'Misc',
        defaultIcon: 'star',
        defaultSortOrder: 10,
        isFard: false,
      ),
    ],
    userCategories: const [],
    categoryOverrides: const [],
    defaultTasks: [
      const DefaultTask(
        code: 'tahajjud',
        defaultName: 'Tahajjud Prayer',
        categoryCode: 'fajr',
        defaultPoints: 15,
        defaultIcon: 'auto_awesome',
        defaultSortOrder: 0,
      ),
    ],
    userTasks: [
      UserTask(
        id: 'ut1',
        categoryRef: 'category:misc',
        name: 'Morning Run',
        points: 20,
        icon: 'fitness_center',
        sortOrder: 0,
      ),
    ],
    taskOverrides: const [],
    forManage: true,
  );
}

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      manageEffectiveCatalogProvider.overrideWith(
        (ref) => Stream.value(_sampleManageCatalog()),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('ManageChecklistScreen', () {
    testWidgets('shows Categories and Tasks tabs', (tester) async {
      await tester.pumpWidget(_wrap(const ManageChecklistScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('Categories tab lists category names', (tester) async {
      await tester.pumpWidget(_wrap(const ManageChecklistScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Misc'), findsOneWidget);
    });

    testWidgets('Tasks tab shows grouped tasks and add card', (tester) async {
      await tester.pumpWidget(_wrap(const ManageChecklistScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Tahajjud Prayer'), findsOneWidget);
      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Add Custom Task'), findsWidgets);
    });

    testWidgets('FAB label switches with tab', (tester) async {
      await tester.pumpWidget(_wrap(const ManageChecklistScreen()));
      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Task'), findsWidgets);
    });

    testWidgets('does not show restore default tasks action', (tester) async {
      await tester.pumpWidget(_wrap(const ManageChecklistScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.textContaining('RESTORE'), findsNothing);
      expect(find.textContaining('Restore default'), findsNothing);
    });

    testWidgets('RTL smoke: Arabic locale renders manage title', (tester) async {
      await tester.pumpWidget(
        _wrap(const ManageChecklistScreen(), locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة القائمة'), findsOneWidget);
    });

    testWidgets('empty categories shows empty state', (tester) async {
      final empty = effectiveCatalog(
        defaultCategories: const [],
        userCategories: const [],
        categoryOverrides: const [],
        defaultTasks: const [],
        userTasks: const [],
        taskOverrides: const [],
        forManage: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
            manageEffectiveCatalogProvider.overrideWith(
              (ref) => Stream.value(empty),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ManageChecklistScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No categories yet'),
        findsOneWidget,
      );
    });
  });
}
