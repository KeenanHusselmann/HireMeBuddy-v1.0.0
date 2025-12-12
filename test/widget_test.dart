import 'package:flutter_test/flutter_test.dart';
import 'package:hiremebuddy_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HireMeBuddyApp());

    // Verify that the app starts
    expect(find.text('Welcome to HireMeBuddy'), findsOneWidget);
  });
}
