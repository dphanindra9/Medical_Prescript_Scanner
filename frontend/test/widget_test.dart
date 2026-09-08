import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(PrescriptionScannerApp());

    // Verify that the title of our app is on screen.
    expect(find.text('Prescription Scanner'), findsOneWidget);
  });
}
