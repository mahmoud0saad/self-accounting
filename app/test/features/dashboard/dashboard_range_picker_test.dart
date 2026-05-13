import 'package:app/features/dashboard/domain/dashboard_range.dart';
import 'package:app/features/dashboard/presentation/providers/dashboard_range_provider.dart';
import 'package:app/features/dashboard/presentation/widgets/dashboard_range_picker.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'range picker updates dashboardRangeProvider via Notifier.select',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: DashboardRangePicker()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DashboardRangePicker)),
      );

      expect(container.read(dashboardRangeProvider), DashboardRange.week7);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardRangeProvider), DashboardRange.month30);

      await tester.tap(find.text('90 days'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardRangeProvider), DashboardRange.days90);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardRangeProvider), DashboardRange.week7);
    },
  );
}
