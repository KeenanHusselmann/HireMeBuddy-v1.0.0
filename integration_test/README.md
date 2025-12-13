# Provider Registration Integration Test

## Run the test on your physical device

```powershell
# Run on specific device
flutter test integration_test/provider_registration_test.dart -d NRLVY9SWIBPBEEXC

# Or run on any connected device
flutter test integration_test/provider_registration_test.dart
```

## What the test does:

1. ✅ Launches the provider app
2. ✅ Waits for splash screen
3. ✅ Clicks "Sign Up" on login screen
4. ✅ Fills in signup form:
   - First Name: John
   - Last Name: Doe
   - Email: johndoe[timestamp]@test.com (unique)
   - Phone: +264811234567
   - Password: Test@123456
   - Confirm Password: Test@123456
5. ✅ Checks Terms & Conditions checkbox
6. ✅ Clicks "CREATE ACCOUNT" button
7. ✅ Waits for navigation to registration screen
8. ✅ Fills in provider registration:
   - First Name: John
   - Last Name: Doe
   - Bio: Professional description
   - Hourly Rate: $150
   - Skills: Adds "Plumbing"
9. ✅ Selects "plumbing" service category
10. ✅ Clicks "Complete Registration" button
11. ✅ Verifies navigation to Provider Dashboard

## Notes:
- Uses unique email with timestamp to avoid duplicates
- Scrolls automatically to reveal hidden buttons
- Waits appropriately between actions
- Verifies each step completes successfully
