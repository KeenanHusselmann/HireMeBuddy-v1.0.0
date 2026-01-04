# 🚀 Quick Start - Test FCM Now!

## Step-by-Step Testing

### 1. Install Testing Tool Dependencies

```bash
cd scripts
npm install
```

### 2. Run Your App

```bash
# From project root
flutter run
```

### 3. Get Your FCM Token

Look for this line in the console:

```
I/flutter: ℹ️ FCM token: fK3x9Y2m...
```

**Copy the entire token!**

### 4. Send Test Notification

```bash
cd scripts
node test_fcm_notifications.js
```

### 5. Test the Notification

1. Choose option **2** (Booking Notification)
2. Paste your FCM token
3. Press Enter

**You should see:**
- ✅ "Notification sent successfully!"
- 🔔 Notification appears on your device!

---

## What You Can Test

### 🎉 Booking Notification (Option 2)
- Title: "🎉 New Booking Request!"
- Body: "You have a new booking request for Plumbing Service"
- **Perfect for:** Testing provider notifications

### 💬 Message Notification (Option 3)
- Title: "💬 New Message from Sarah"
- Body: "Hey, are you available tomorrow morning?"
- **Perfect for:** Testing chat notifications

### 💰 Payment Notification (Option 4)
- Title: "💰 Payment Received"
- Body: "You received N$150.00 for Plumbing Service"
- **Perfect for:** Testing payment confirmations

### ✅ Verification Notification (Option 5)
- Title: "✅ Verification Complete"
- Body: "Your provider profile has been verified!"
- **Perfect for:** Testing provider approval flow

---

## Expected Behavior

### ✅ App in Foreground (Open)
- Notification banner appears at top
- Auto-dismisses after 5 seconds
- Console: "FCM foreground message: xyz"

### ✅ App in Background (Minimized)
- System notification in tray
- Sound/vibration
- Tapping opens the app

### ✅ App Killed (Not Running)
- System notification appears
- Background handler processes it
- Console: "🔔 [BG] FCM message: xyz"

---

## Troubleshooting

### ❌ No Token in Console?

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

Then check logs again.

### ❌ "Invalid token" Error?

**Solution:**
1. Restart the app to get fresh token
2. Copy the **entire** token (it's long!)
3. Make sure no extra spaces

### ❌ Notifications Not Appearing?

**Solution for Android 13+:**
1. Open app
2. When permission popup appears, tap "Allow"
3. Try sending notification again

**Solution for Android Settings:**
1. Settings > Apps > HireMeBuddy
2. Notifications > Turn ON

---

## Full Documentation

For complete guide with all testing scenarios, see:
📄 [docs/FCM_TESTING_GUIDE.md](FCM_TESTING_GUIDE.md)

---

## Quick Commands

```bash
# Install dependencies
cd scripts && npm install

# Run test tool
node test_fcm_notifications.js

# Run the app
cd .. && flutter run

# Clean build (if issues)
flutter clean && flutter pub get
```

---

**Ready to test? Run the app and get your FCM token!** 🚀
