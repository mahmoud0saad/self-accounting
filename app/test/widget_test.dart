import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Home screen shows Muhasabah title', (WidgetTester tester) async {
    await tester.pumpWidget(const MuhasabahApp());
    await tester.pumpAndSettle();

    expect(find.text('Muhasabah'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
  });
}
