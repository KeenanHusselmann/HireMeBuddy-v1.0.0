# 🔔 FCM Push Notification Testing Guide

## Overview
This guide helps you test Firebase Cloud Messaging (FCM) push notifications in HireMeBuddy.

## Prerequisites
✅ Firebase project configured (hiremebuddy-850a8)
✅ google-services.json in place
✅ FCM dependencies installed
✅ Service account key file available

---

## Quick Start - Testing FCM

### Step 1: Install Dependencies (Node.js Method - Recommended)

```bash
cd scripts
npm install
```

This installs `firebase-admin` SDK for sending test notifications.

### Step 2: Run the App

```bash
# From project root
flutter run
```

### Step 3: Get Your FCM Token

Watch the console output when the app starts. You'll see:

```
I/flutter (12345): ℹ️ FCM token: fK3x9Y2mTpOZQr4vLm1XYZ:APA91bH...
```

**Copy this entire token** - you'll need it for testing!

### Step 4: Send Test Notifications

**Using Node.js (Recommended):**
```bash
cd scripts
node test_fcm_notifications.js
```

**Using PowerShell:**
```powershell
cd scripts
.\test_fcm_notifications.ps1
```

### Step 5: Choose a Test Scenario

The tool provides several test options:

1. **Custom Test Notification**
   - Send any title/body you want
   - Good for basic functionality testing

2. **Booking Notification**
   - Simulates "New Booking Request"
   - Includes booking data payload
   - Tests booking-related notifications

3. **Message Notification**
   - Simulates "New Message"
   - Includes chat data payload
   - Tests chat notifications

4. **Payment Notification**
   - Simulates "Payment Received"
   - Includes payment data payload
   - Tests payment notifications

5. **Verification Notification**
   - Simulates "Profile Verified"
   - Tests provider verification flow

---

## Testing Scenarios

### Test 1: Foreground Notification (App Open)

**Expected Behavior:**
- ✅ Notification banner appears at top of screen
- ✅ Local notification shows (via NotificationService)
- ✅ Console logs: "FCM foreground message: xyz"
- ✅ Notification auto-dismisses after 5 seconds

**What to Check:**
- Notification appears
- Title and body are correct
- Notification is clickable
- App doesn't crash

### Test 2: Background Notification (App Minimized)

**Expected Behavior:**
- ✅ System notification appears in notification tray
- ✅ Notification icon shows
- ✅ Sound/vibration (if enabled)
- ✅ Tapping notification opens the app

**What to Check:**
- Notification appears in system tray
- Tapping opens the app
- Data payload is received

### Test 3: Notification When App is Killed

**Expected Behavior:**
- ✅ System notification appears
- ✅ Background handler processes message
- ✅ Tapping notification launches the app
- ✅ Console logs: "🔔 [BG] FCM message: xyz"

**What to Check:**
- Notification still works
- App launches properly
- No crashes on cold start

### Test 4: Data-Only Notification (Silent)

**Expected Behavior:**
- ✅ No visible notification
- ✅ Background handler runs
- ✅ Data is processed silently
- ✅ App state updates (if needed)

**What to Check:**
- Background handler executes
- Data is saved to database
- No user interruption

---

## Notification Types & Data Payloads

### Booking Notification
```json
{
  "type": "booking",
  "booking_id": "uuid",
  "action": "new_booking|cancelled|completed",
  "client_name": "John Doe",
  "service_name": "Plumbing Service"
}
```

### Message Notification
```json
{
  "type": "message",
  "chat_id": "uuid",
  "sender_id": "uuid",
  "sender_name": "Sarah Johnson"
}
```

### Payment Notification
```json
{
  "type": "payment",
  "payment_id": "uuid",
  "amount": "150.00",
  "currency": "NAD",
  "booking_id": "uuid"
}
```

### Verification Notification
```json
{
  "type": "verification",
  "status": "approved|rejected",
  "verification_id": "uuid"
}
```

---

## Troubleshooting

### ❌ "Token not found" Error

**Problem:** App doesn't show FCM token in logs

**Solutions:**
1. Check Firebase initialization:
   ```dart
   await Firebase.initializeApp();
   await PushNotificationService().init();
   ```

2. Check google-services.json is in `android/app/`

3. Verify FCM dependencies in pubspec.yaml:
   ```yaml
   firebase_core: ^3.8.0
   firebase_messaging: ^15.1.3
   ```

4. Rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### ❌ "Sender ID mismatch" Error

**Problem:** Wrong project configuration

**Solutions:**
1. Verify google-services.json matches Firebase project
2. Check package name in AndroidManifest.xml matches Firebase
3. Download fresh google-services.json from Firebase Console

### ❌ Notifications Not Appearing

**Problem:** Notifications don't show up

**Solutions:**

**For Android 13+:**
1. Grant notification permission:
   ```dart
   await _messaging.requestPermission(
     alert: true,
     badge: true,
     sound: true,
   );
   ```

2. Check Android settings:
   - Settings > Apps > HireMeBuddy > Notifications > Allow

**For Android 8.0+:**
1. Verify notification channel exists in NotificationService
2. Check channel importance level (HIGH)

**General:**
1. Check device is connected to internet
2. Verify FCM token is valid (not expired)
3. Check console for errors
4. Try restarting the app

### ❌ "Invalid token" Error

**Problem:** Token is invalid or expired

**Solutions:**
1. Get a fresh token (restart app)
2. Check token is saved to Supabase:
   ```sql
   SELECT * FROM device_tokens WHERE user_id = 'your-user-id';
   ```
3. Verify token refresh listener is working:
   ```dart
   _messaging.onTokenRefresh.listen((newToken) {
     // Should update Supabase
   });
   ```

### ❌ Background Handler Not Working

**Problem:** Notifications not processed in background

**Solutions:**
1. Verify background handler is registered BEFORE getting token:
   ```dart
   FirebaseMessaging.onBackgroundMessage(
     firebaseMessagingBackgroundHandler
   );
   ```

2. Check AndroidManifest.xml has FCM service declared

3. Ensure background handler is a top-level function:
   ```dart
   @pragma('vm:entry-point')
   Future<void> firebaseMessagingBackgroundHandler(
     RemoteMessage message
   ) async {
     // Must be top-level, not inside a class
   }
   ```

---

## Manual Testing with Firebase Console

### Alternative to Scripts

1. Open Firebase Console: https://console.firebase.google.com
2. Go to: Project > Engage > Messaging
3. Click "Send your first message"
4. Enter:
   - **Title:** "Test Notification"
   - **Body:** "This is a test"
5. Click "Send test message"
6. Paste your FCM token
7. Click "Test"

**Pros:**
- No scripts needed
- Visual interface
- Quick for basic tests

**Cons:**
- Can't customize data payload easily
- Manual process
- No automation

---

## Production Checklist

Before going live, verify:

- [ ] FCM tokens are saved to `device_tokens` table
- [ ] Token refresh updates Supabase
- [ ] Notifications work in all app states (foreground/background/killed)
- [ ] Data payloads are handled correctly
- [ ] Navigation works when tapping notifications
- [ ] Background handler processes messages
- [ ] Notification channels configured (Android 8+)
- [ ] Permissions requested properly (Android 13+)
- [ ] Edge functions can send notifications via admin SDK
- [ ] RLS policies protect device_tokens table
- [ ] Token cleanup on logout

---

## Integration with Backend

### Sending Notifications from Supabase Edge Functions

```typescript
// In your edge function
import { createClient } from '@supabase/supabase-js'
import * as admin from 'firebase-admin'

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: Deno.env.get('FIREBASE_PROJECT_ID'),
      clientEmail: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY'),
    }),
  })
}

// Get user's FCM token from device_tokens table
const { data: tokens } = await supabase
  .from('device_tokens')
  .select('token')
  .eq('user_id', userId)

// Send notification to all user's devices
for (const { token } of tokens) {
  await admin.messaging().send({
    token,
    notification: {
      title: 'New Booking',
      body: 'You have a new booking request!'
    },
    data: {
      type: 'booking',
      booking_id: bookingId
    }
  })
}
```

---

## Next Steps

1. ✅ Test basic notifications (this guide)
2. ⬜ Implement notification navigation (deep linking)
3. ⬜ Set up Edge Functions for automated notifications
4. ⬜ Test notification_queue processing
5. ⬜ Implement notification preferences
6. ⬜ Add notification history/inbox
7. ⬜ Test on multiple devices
8. ⬜ Performance testing (1000+ notifications)

---

## Resources

- **Firebase Console:** https://console.firebase.google.com/project/hiremebuddy-850a8
- **FCM Documentation:** https://firebase.google.com/docs/cloud-messaging
- **Flutter FCM Plugin:** https://pub.dev/packages/firebase_messaging
- **Testing Guide:** https://firebase.google.com/docs/cloud-messaging/flutter/first-message

---

**Last Updated:** January 3, 2026  
**Status:** ✅ Ready for Testing  
**Confidence:** 🟢 HIGH - All components configured
