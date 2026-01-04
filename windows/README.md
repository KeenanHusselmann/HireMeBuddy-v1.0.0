# Windows Build Configuration

This folder contains the Windows desktop build configuration for the **HireMeBuddy Admin App**.

## Important Notes

⚠️ **Firebase Windows Build Issue**: The admin app uses `main_admin.dart` which does NOT include Firebase, avoiding the Windows C++ SDK linking errors.

## Building

### Option 1: Web Build (Recommended)
```bash
flutter build web --target=lib/main_admin.dart --release
cd build\web
python -m http.server 8080
```

### Option 2: Native Windows Build (If Firebase issue resolved)
```bash
flutter build windows --release
```

The Windows runner is configured to use `lib/main_admin.dart` as the entry point.

## Platform Strategy

- **Admin App**: Windows (web build) - NO Firebase, NO push notifications
- **Client App**: Android/iOS - Firebase + push notifications
- **Provider App**: Android/iOS - Firebase + push notifications

See [PLATFORM_ARCHITECTURE.md](../PLATFORM_ARCHITECTURE.md) for complete platform strategy.
