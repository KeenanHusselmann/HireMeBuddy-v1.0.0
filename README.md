# HireMeBuddy - Service Marketplace Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00599C)](https://riverpod.dev)

> A comprehensive Flutter-based service marketplace connecting Namibian clients with verified service providers.

## 🌟 Overview

**HireMeBuddy** is a three-application ecosystem designed to revolutionize service booking in Namibia:

- 📱 **Client App** - Browse and book trusted service providers
- 👨‍🔧 **Provider App** - Manage bookings, portfolios, and earnings
- 💼 **Admin Portal** - Platform management and analytics (Windows)

### Key Features

✅ **15+ Service Categories** - Plumbing, Electrical, Cleaning, and more  
✅ **Real-time Chat** - Direct messaging between clients and providers  
✅ **Smart Search** - Service discovery with suggestion system  
✅ **Location-based Matching** - Find providers in your area  
✅ **Video Portfolios** - TikTok-style provider showcases  
✅ **Secure Bookings** - Complete booking lifecycle management  
✅ **Review System** - Rate and review service providers  
✅ **Multi-role Support** - Client, Provider, and Admin interfaces

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Android Studio / Xcode (for mobile development)
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hiremebuddy_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   # Create .env file in project root
   cp .env.example .env
   # Add your Supabase credentials
   ```

4. **Run database migrations**
   - See [supabase/README.md](supabase/README.md)

5. **Launch the app**
   ```bash
   # Client App
   flutter run -t lib/main.dart
   
   # Provider App
   flutter run -t lib/main_provider.dart
   
   # Admin Portal (Windows)
   flutter run -d windows -t lib/main_admin.dart
   ```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) | Complete technical documentation |
| [DOCUMENTATION.md](DOCUMENTATION.md) | Features and architecture overview |
| [QUICKSTART.md](QUICKSTART.md) | Step-by-step setup guide |
| [SEARCH_FEATURE_DOCUMENTATION.md](SEARCH_FEATURE_DOCUMENTATION.md) | Search implementation details |
| [SECURITY.md](SECURITY.md) | ⚠️ Security requirements and best practices |
| [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md) | Build optimization results |
| [BUILD_REFERENCE.md](BUILD_REFERENCE.md) | Build commands reference |

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Applications             │
│  Client App | Provider App | Admin       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Supabase Backend                 │
│  PostgreSQL | Auth | Storage | Realtime │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      External Services                   │
│  Google Maps | Firebase | Payment API   │
└─────────────────────────────────────────┘
```

### Tech Stack

- **Frontend**: Flutter 3.9.2 (Dart)
- **State Management**: Riverpod 2.6.1
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Navigation**: GoRouter 14.6.2
- **Maps**: Google Maps Flutter 2.10.0
- **Real-time**: Supabase Realtime subscriptions
- **Notifications**: Flutter Local Notifications + WorkManager

## 📦 Project Structure

```
lib/
├── core/                    # Core infrastructure
│   ├── config/             # App configuration & routing
│   ├── providers/          # Global Riverpod providers
│   ├── theme/              # App theming
│   └── utils/              # Utility functions
│
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── services/          # Service browsing
│   ├── bookings/          # Booking management
│   ├── chat/              # Real-time messaging
│   ├── provider/          # Provider-specific features
│   ├── admin/             # Admin dashboard
│   └── profile/           # User profiles
│
├── shared/                 # Shared components
│   ├── models/            # Data models
│   ├── services/          # Business logic services
│   ├── providers/         # Shared providers
│   └── widgets/           # Reusable widgets
│
├── main.dart              # Client app entry point
├── main_provider.dart     # Provider app entry point
└── main_admin.dart        # Admin app entry point
```

## 🗄️ Database Schema

**10 Core Tables:**
- `profiles` - User accounts (client/provider/admin)
- `provider_profiles` - Extended provider information
- `service_categories` - 15 service types
- `provider_services` - Provider-service mappings
- `bookings` - Service booking requests
- `reviews` - Provider ratings and reviews
- `messages` - Real-time chat messages
- `notifications` - Push notifications
- `payments` - Payment transactions
- `admin_actions` - Admin audit log

See [docs/database_schema.md](docs/database_schema.md) for detailed schema.

## 🔧 Development

### Building the Apps

```bash
# Development build
flutter build apk --debug

# Optimized release builds (recommended)
.\build_optimized.ps1 client
.\build_optimized.ps1 provider

# Results: ~45% smaller APKs (10-15 MB vs 19 MB)
```

### Running Tests

```bash
flutter test
```

### Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🎯 Current Status

### ✅ Completed Features
- Full authentication system (email/password)
- Service browsing with search and filters
- Smart service suggestion system
- Real-time booking management
- Provider portfolios (images/videos)
- Chat messaging system
- Review and rating system
- Admin dashboard with analytics
- Location-based provider matching
- Build optimization (45% size reduction)

### ⚠️ Production Requirements
- **CRITICAL**: Secure environment variables (see [SECURITY.md](SECURITY.md))
- Implement Row Level Security policies
- Complete payment gateway integration
- Replace print statements with proper logging
- Add comprehensive testing
- Initialize Git repository
- Email verification system

### 🔜 Upcoming Features
- Multi-language support (English, Afrikaans)
- Dark mode theme
- Advanced search filters
- Push notifications (Firebase)
- In-app calling/video chat
- Service packages and promotions
- Referral program
- Offline mode

## 🐛 Known Issues

1. ⚠️ Supabase credentials hardcoded (requires `.env` implementation)
2. ⚠️ RLS policies need verification in production
3. Payment integration needs production credentials
4. Limited offline functionality
5. No multi-language support yet

## 📊 App Size Optimization

Recent optimizations achieved **~45% size reduction**:

| Build Type | Size | Recommendation |
|------------|------|----------------|
| Universal APK | 19.0 MB | ❌ Not recommended |
| arm64-v8a APK | 17.8 MB | ✅ Modern devices |
| armeabi-v7a APK | 15.3 MB | ✅ Older devices |
| Play Store | 10-15 MB | ✅ Best option |

See [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md) for details.

## 🤝 Contributing

1. Read the [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)
2. Review [SECURITY.md](SECURITY.md) for security guidelines
3. Follow Flutter best practices
4. Write meaningful commit messages
5. Test thoroughly before submitting

## 📄 License

Copyright © 2025 HireMeBuddy. All rights reserved.

---

## 🔗 Quick Links

- 📖 [Full Documentation](PROJECT_DOCUMENTATION.md)
- 🚀 [Setup Guide](QUICKSTART.md)
- 🔒 [Security Guide](SECURITY.md)
- 🛠️ [Build Reference](BUILD_REFERENCE.md)
- 📊 [Database Schema](docs/database_schema.md)
- 🗺️ [Implementation Roadmap](docs/implementation_roadmap.md)

---

**Version:** 1.0.0+1  
**Last Updated:** December 12, 2025  
**Status:** Production Ready (Beta) - Requires security hardening
