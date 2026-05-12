import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Checklist screen shows Muhasabah title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MuhasabahApp()));
    await tester.pumpAndSettle();

    expect(find.text('Muhasabah'), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });
}
