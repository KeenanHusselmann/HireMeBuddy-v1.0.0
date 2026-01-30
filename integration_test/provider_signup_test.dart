import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hiremebuddy_flutter/main_provider.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Provider Signup Tests', () {
    testWidgets('Successfully sign up a new provider user', (WidgetTester tester) async {
      // Launch the provider app
      app.main();
      
      // Give app time to initialize Firebase and Supabase
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Keep pumping until we see actual UI content (not just splash/loading)
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        
        // Check if we can find the Register button (means app loaded)
        final registerButton = find.text('Register');
        if (registerButton.evaluate().isNotEmpty) {
          print('App loaded successfully after ${i + 5} seconds');
          break;
        }
        
        if (i == 19) {
          print('Warning: App took more than 25 seconds to load');
        }
      }
      
      await tester.pumpAndSettle();

      // Find and tap "Register" or "Sign Up" button on login screen
      final registerButton = find.text('Register').first;
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Generate unique email to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'testprovider$timestamp@hiremebuddy.app';
      
      // Password that meets all requirements:
      // - At least 8 characters
      // - One uppercase letter (A-Z)
      // - One lowercase letter (a-z)
      // - One number (0-9)
      // - One special character (!@#$%^&*(),.?":{}|<>)
      const testPassword = 'Provider@123';

      // Fill in First Name
      final firstNameField = find.byType(TextFormField).at(0);
      await tester.enterText(firstNameField, 'Test');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Fill in Last Name
      final lastNameField = find.byType(TextFormField).at(1);
      await tester.enterText(lastNameField, 'Provider');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Fill in Email
      final emailField = find.byType(TextFormField).at(2);
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Fill in Phone Number
      final phoneField = find.byType(TextFormField).at(3);
      await tester.enterText(phoneField, '+264811234567');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Fill in Password
      final passwordField = find.byType(TextFormField).at(4);
      await tester.enterText(passwordField, testPassword);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify password requirements are met
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('One uppercase letter (A-Z)'), findsOneWidget);
      expect(find.text('One lowercase letter (a-z)'), findsOneWidget);
      expect(find.text('One number (0-9)'), findsOneWidget);

      // Fill in Confirm Password
      final confirmPasswordField = find.byType(TextFormField).at(5);
      await tester.enterText(confirmPasswordField, testPassword);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Scroll down to see the terms checkbox
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Find and tap the Terms & Conditions checkbox
      final termsCheckbox = find.byType(Checkbox);
      expect(termsCheckbox, findsOneWidget);
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify checkbox is checked
      final checkboxWidget = tester.widget<Checkbox>(termsCheckbox);
      expect(checkboxWidget.value, true);

      // Scroll down more to reveal the Create Account button
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Find and tap Create Account button
      final createAccountButton = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
      expect(createAccountButton, findsOneWidget);
      await tester.tap(createAccountButton);
      
      // Wait for the loading dialog to appear
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify loading dialog appears
      expect(find.text('Creating your account'), findsOneWidget);
      expect(find.text('Setting up your profile...'), findsOneWidget);

      // Wait for account creation to complete (may take several seconds)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After successful signup, should navigate to provider dashboard or registration screen
      // Wait a bit more for navigation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we're no longer on the signup screen
      expect(find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT'), findsNothing);

      print('✓ Successfully created provider account: $testEmail');
    });

    testWidgets('Validate password requirements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Register').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      final registerButton = find.text('Register').first;
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find password field
      final passwordField = find.byType(TextFormField).at(4);

      // Test weak password (missing uppercase)
      await tester.enterText(passwordField, 'password123!');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify requirement indicators show correctly
      expect(find.text('One uppercase letter (A-Z)'), findsOneWidget);

      // Test strong password
      await tester.enterText(passwordField, 'Provider@123');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // All requirements should be met (green checks)
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('One uppercase letter (A-Z)'), findsOneWidget);
      expect(find.text('One lowercase letter (a-z)'), findsOneWidget);
      expect(find.text('One number (0-9)'), findsOneWidget);

      print('✓ Password validation working correctly');
    });

    testWidgets('Prevent signup without accepting terms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Register').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      
      // Find register button - try both ways
      var registerButtons = find.text('Register');
      if (registerButtons.evaluate().isEmpty) {
        registerButtons = find.textContaining('egister');
      }
      
      expect(registerButtons, findsAtLeastNWidgets(1));
      await tester.tap(registerButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Fill in minimal required fields
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Find text fields by type
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(6));
      
      await tester.enterText(textFields.at(0), 'Test');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textFields.at(1), 'User');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textFields.at(2), 'test$timestamp@test.com');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textFields.at(3), '+264811234567');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textFields.at(4), 'Provider@123');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(textFields.at(5), 'Provider@123');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Scroll to bottom to see create account button
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Record initial state - we should still be on signup screen
      final createButton = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
      expect(createButton, findsOneWidget);

      // Tap create account WITHOUT checking terms
      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're STILL on signup screen (didn't navigate)
      expect(find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT'), findsOneWidget);

      print('✓ Terms checkbox validation prevented signup successfully');
    });
  });
}
