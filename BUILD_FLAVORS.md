# Building HireMeBuddy Apps (Client & Provider)

## Overview
The HireMeBuddy project now automatically detects which flavor is running based on the Android package name and routes to the appropriate app (Client or Provider).

## Changes Made
1. **MainActivity.kt** - Added method channel to expose package name to Flutter
2. **main.dart** - Added flavor detection logic that automatically launches the correct app
3. Both flavors now use the same `main.dart` entry point but route internally

## Building APKs

### Build Client App (Release)
```bash
flutter build apk --flavor client --release --dart-define=APP_FLAVOR=client
```
Output: `build/app/outputs/flutter-apk/app-client-release.apk`

### Build Provider App (Release)
```bash
flutter build apk --flavor provider --release --dart-define=APP_FLAVOR=provider
```
Output: `build/app/outputs/flutter-apk/app-provider-release.apk`

### Build Both Apps
```bash
flutter build apk --flavor client --release --dart-define=APP_FLAVOR=client && flutter build apk --flavor provider --release --dart-define=APP_FLAVOR=provider
```

## Running Apps in Development

### Run Client App
```bash
flutter run --flavor client --dart-define=APP_FLAVOR=client
```

### Run Provider App
```bash
flutter run --flavor provider --dart-define=APP_FLAVOR=provider
```

## App Bundles (for Play Store)

### Build Client Bundle
```bash
flutter build appbundle --flavor client --release --dart-define=APP_FLAVOR=client
```
Output: `build/app/outputs/bundle/clientRelease/app-client-release.aab`

### Build Provider Bundle
```bash
flutter build appbundle --flavor provider --release --dart-define=APP_FLAVOR=provider
```
Output: `build/app/outputs/bundle/providerRelease/app-provider-release.aab`

## Package Names
- **Client App**: `app.hiremebuddy.client`
- **Provider App**: `app.hiremebuddy.provider`

## App Names
- **Client App**: "HireMeBuddy Client"
- **Provider App**: "HireMeBuddy Provider"

## How It Works
1. When the app launches, `main.dart` calls the native Android method to get the package name
2. If package name contains `.provider`, it launches `HireMeBuddyProviderApp`
3. If package name contains `.client`, it launches `HireMeBuddyApp`
4. Each app uses its respective router (ProviderAppRouter vs AppRouter)
5. This ensures the correct screens and navigation flow for each app type

## Troubleshooting

### If the wrong app still launches:
1. Clean the build:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Rebuild the APK:
   ```bash
   flutter build apk --flavor provider --release
   ```

### Verify the package name:
Check the logs when the app launches. You should see:
```
📦 Package name: app.hiremebuddy.provider
🚀 Launching provider app...
```
or
```
📦 Package name: app.hiremebuddy.client
🚀 Launching client app...
```

## Testing
1. Install both APKs on a device
2. Launch each app separately
3. Verify they show different screens:
   - Client app should show service browsing/booking screens
   - Provider app should show provider registration/dashboard screens
