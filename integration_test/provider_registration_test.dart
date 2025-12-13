import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hiremebuddy_flutter/main_provider.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Provider Registration Flow', () {
    testWidgets('Complete provider registration flow', (WidgetTester tester) async {
      // Launch the provider app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Register" button on login screen
      final registerButton = find.text('Register');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Fill in signup form
      // First Name
      final firstNameField = find.widgetWithText(TextFormField, 'First Name');
      expect(firstNameField, findsOneWidget);
      await tester.enterText(firstNameField, 'John');
      await tester.pumpAndSettle();

      // Last Name
      final lastNameField = find.widgetWithText(TextFormField, 'Last Name');
      expect(lastNameField, findsOneWidget);
      await tester.enterText(lastNameField, 'Doe');
      await tester.pumpAndSettle();

      // Email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'johndoe${DateTime.now().millisecondsSinceEpoch}@test.com');
      await tester.pumpAndSettle();

      // Phone Number
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '+264811234567');
      await tester.pumpAndSettle();

      // Password
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'Test@123456');
      await tester.pumpAndSettle();

      // Confirm Password
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirm Password');
      expect(confirmPasswordField, findsOneWidget);
      await tester.enterText(confirmPasswordField, 'Test@123456');
      await tester.pumpAndSettle();

      // Scroll down to see the terms checkbox
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -250));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Agree to terms - tap the checkbox directly with warnIfMissed: false
      final termsCheckbox = find.byType(Checkbox);
      expect(termsCheckbox, findsOneWidget);
      await tester.tap(termsCheckbox, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Scroll down more to see the Create Account button
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -100));
      await tester.pumpAndSettle();

      // Tap Create Account button
      final createAccountButton = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
      expect(createAccountButton, findsOneWidget);
      await tester.tap(createAccountButton);
      
      // Wait for account creation and navigation - give it more time
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should now be on registration screen
      // Look for "Register as Provider" title - give it extra wait if needed
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Check if we're on the registration screen (there are 2 with this text, use .first)
      final registrationTitle = find.text('Register as Provider');
      expect(registrationTitle, findsWidgets);  // Changed to findsWidgets since there are 2

      // Fill in registration form
      // First Name (should be pre-filled or empty)
      final regFirstNameField = find.widgetWithText(TextFormField, 'First Name').first;
      await tester.enterText(regFirstNameField, 'John');
      await tester.pumpAndSettle();

      // Last Name
      final regLastNameField = find.widgetWithText(TextFormField, 'Last Name').first;
      await tester.enterText(regLastNameField, 'Doe');
      await tester.pumpAndSettle();

      // Bio
      final bioField = find.widgetWithText(TextFormField, 'Bio');
      expect(bioField, findsOneWidget);
      await tester.enterText(bioField, 'I am an experienced professional with over 5 years in the industry providing quality services.');
      await tester.pumpAndSettle();

      // Scroll down to see more fields
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Hourly Rate
      final hourlyRateField = find.widgetWithText(TextFormField, 'Hourly Rate (\$)');
      expect(hourlyRateField, findsOneWidget);
      await tester.enterText(hourlyRateField, '150');
      await tester.pumpAndSettle();

      // Add a skill
      final skillField = find.widgetWithText(TextField, 'Add a skill');
      expect(skillField, findsOneWidget);
      await tester.enterText(skillField, 'Plumbing');
      await tester.pumpAndSettle();

      // Tap Add button to add the skill
      final addSkillButton = find.widgetWithText(ElevatedButton, 'Add');
      expect(addSkillButton, findsOneWidget);
      await tester.tap(addSkillButton);
      await tester.pumpAndSettle();

      // Scroll down to see service categories
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Select service categories - tap on ChoiceChip with text "plumbing", using warnIfMissed: false
      final plumbingChip = find.widgetWithText(ChoiceChip, 'plumbing');
      if (plumbingChip.evaluate().isNotEmpty) {
        await tester.tap(plumbingChip, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Scroll to bottom to see Register as Provider button - need to scroll more
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      
      // Scroll once more to ensure button is visible
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Tap Register as Provider button - use warnIfMissed: false
      final registerAsProviderButton = find.widgetWithText(ElevatedButton, 'Register as Provider');
      expect(registerAsProviderButton, findsOneWidget);
      await tester.tap(registerAsProviderButton, warnIfMissed: false);
      
      // Wait for registration to complete - give it more time
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to provider dashboard
      // Verify we're on the dashboard by looking for expected elements
      // Wait a bit more if needed
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      final dashboardTitle = find.text('Provider Dashboard');
      if (dashboardTitle.evaluate().isEmpty) {
        // Maybe still loading, wait more
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Print what we can see instead
        print('Dashboard not found. Looking for Welcome text...');
        final welcomeText = find.textContaining('Welcome');
        if (welcomeText.evaluate().isNotEmpty) {
          print('✅ Found Welcome text on screen!');
        } else {
          print('❌ Could not find Welcome text either');
        }
      }
      
      expect(dashboardTitle, findsOneWidget);

      print('✅ Provider registration flow completed successfully!');
    });
  });
}
