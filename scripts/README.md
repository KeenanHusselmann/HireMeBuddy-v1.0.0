# FCM Testing Scripts

This folder contains tools for testing Firebase Cloud Messaging (FCM) push notifications.

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

This installs `firebase-admin` SDK needed for sending test notifications.

### 2. Run the Test Tool

```bash
node test_fcm_notifications.js
```

### 3. Get Your FCM Token

1. Run the app: `flutter run` (from project root)
2. Look for console log: `ℹ️ FCM token: ...`
3. Copy the entire token

### 4. Send Test Notifications

Use the interactive menu to:
- Send custom notifications
- Test booking notifications
- Test message notifications
- Test payment notifications
- Test verification notifications

## Files

- **test_fcm_notifications.js** - Node.js testing tool (recommended)
- **test_fcm_notifications.ps1** - PowerShell testing tool (requires gcloud CLI)
- **package.json** - Node.js dependencies

## Requirements

- Node.js 16+
- Service account key: `hiremebuddy-850a8-2d033e0c5ff3.json` (in project root)

## Documentation

See [../docs/FCM_TESTING_GUIDE.md](../docs/FCM_TESTING_GUIDE.md) for complete testing documentation.

See [../docs/FCM_QUICK_START.md](../docs/FCM_QUICK_START.md) for quick start guide.

## Troubleshooting

**"Cannot find module 'firebase-admin'"**
```bash
npm install
```

**"Service account key not found"**
- Make sure `hiremebuddy-850a8-2d033e0c5ff3.json` is in project root
- Download from Firebase Console > Project Settings > Service Accounts

**"Invalid token"**
- Get a fresh token by restarting the app
- Make sure you copied the entire token (it's long!)

## Example Usage

```bash
# Install dependencies
npm install

# Run the tool
node test_fcm_notifications.js

# Select option 2 (booking notification)
# Paste your FCM token
# Check your device for the notification!
```

---

Happy testing! 🚀
