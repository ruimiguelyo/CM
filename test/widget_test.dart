// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hellofarmer_app/main.dart';

void main() {
  testWidgets('HelloFarmer app starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HelloFarmerApp());

    // Wait for the splash screen to load
    await tester.pump();

    // Verify that we can find the HelloFarmer text or logo
    expect(find.text('HelloFarmer'), findsOneWidget);
  });
}
