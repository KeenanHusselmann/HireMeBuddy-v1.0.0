# HireMeBuddy v1.0.0

> **Connect skilled professionals with clients seamlessly in Namibia**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-Notifications-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

## 📱 Overview

HireMeBuddy is a comprehensive service marketplace platform connecting clients with verified service providers across Namibia. The platform features real-time chat, booking management, secure payments, and push notifications.

### Key Features

✅ **Multi-Role System**: Client, Provider, Admin roles with distinct interfaces  
✅ **Service Categories**: 20+ categories from Plumbing to Photography  
✅ **Real-Time Chat**: Instant messaging with image/video support  
✅ **Booking System**: Complete lifecycle from request to completion  
✅ **Payment Processing**: Secure transaction management  
✅ **Push Notifications**: FCM integration for real-time updates  
✅ **Reviews & Ratings**: 5-star rating system with detailed reviews  
✅ **Location Services**: Google Maps integration for service area  
✅ **Portfolio Management**: Providers showcase work with media  
✅ **Admin Dashboard**: Complete platform management capabilities  

---

## 🏗️ Architecture

### Tech Stack

**Frontend**
- Flutter 3.9.2 (Cross-platform: Android, iOS, Web)
- Riverpod (State Management)
- Go Router (Navigation)

**Backend**
- Supabase (PostgreSQL, Auth, Storage, Real-time)
- Firebase Cloud Messaging (Push Notifications)
- Edge Functions (Serverless Functions)

**Maps & Location**
- Google Maps Flutter Plugin
- Geolocator & Geocoding

**Media**
- Image Picker & Caching
- Video Player & Thumbnails

### Project Structure

```
lib/
├── core/               # Core utilities & config
│   ├── config/         # Supabase, FCM config
│   ├── constants/      # App-wide constants
│   └── utils/          # Logger, validators, helpers
├── features/           # Feature modules
│   ├── auth/           # Authentication screens
│   ├── bookings/       # Booking management
│   ├── chat/           # Real-time messaging
│   ├── home/           # Home screens (client/provider)
│   ├── admin/          # Admin dashboard
│   ├── profile/        # User profiles
│   ├── providers/      # Provider directory
│   ├── reviews/        # Rating & reviews
│   └── wallet/         # Payment & transactions
└── shared/             # Shared components
    ├── models/         # Data models
    ├── services/       # API services
    └── widgets/        # Reusable widgets
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2+
- Dart SDK 3.0+
- Android Studio / VS Code
- Git
- Supabase Project
- Firebase Project (for FCM)
- Google Maps API Key

### Installation

1. **Clone Repository**
```bash
git clone https://github.com/yourusername/hiremebuddy.git
cd hiremebuddy
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Configure Environment**
Create `.env` file in root:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

4. **Configure Firebase**
- Download `google-services.json` (Android)
- Download `GoogleService-Info.plist` (iOS)
- Place in respective platform folders

5. **Run Database Migrations**
Execute all SQL files in `supabase/migrations/` via Supabase Dashboard

### Running the App

**Client App**
```bash
flutter run --flavor client --target lib/main.dart
```

**Provider App**
```bash
flutter run --flavor client --target lib/main_provider.dart
```

**Admin App**
```bash
flutter run --flavor client --target lib/main_admin.dart
```

### Building for Production

**Android APK**
```bash
flutter build apk --release --flavor client --target lib/main.dart
```

**Android App Bundle**
```bash
flutter build appbundle --release --flavor client --target lib/main.dart
```

**iOS**
```bash
flutter build ios --release
```

---

## 🔒 Security

### Current Status

| Security Feature | Status | Priority |
|-----------------|--------|----------|
| Environment Variables | ✅ Complete | HIGH |
| Firebase Credentials | ✅ Secured (Jan 4, 2026) | CRITICAL |
| RLS Policies | ⚠️ Needs Testing | CRITICAL |
| Authentication | ✅ Implemented | HIGH |
| Email Verification | ⚠️ Partial | HIGH |
| Password Strength | ❌ Not Implemented | HIGH |
| Payment Security | ⚠️ Placeholder | CRITICAL |
| File Upload Validation | ⚠️ Basic | MEDIUM |
| Rate Limiting | ❌ Not Implemented | MEDIUM |

### ⚠️ URGENT ACTION REQUIRED

**Firebase Service Account Key Rotation Needed**
- Exposed credentials were removed from repository (Jan 4, 2026)
- **You must rotate the Firebase key immediately**
- See [SECURITY_FIX_SUMMARY.md](SECURITY_FIX_SUMMARY.md) for step-by-step instructions
- See [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md) for complete configuration guide

### Critical Tasks Before Production

**MUST COMPLETE:**
1. ✅ Remove exposed Firebase credentials (COMPLETED Jan 4, 2026)
2. ⏳ **Rotate Firebase service account key** (URGENT - within 24 hours)
3. ⏳ Configure Supabase Edge Function secrets
4. ⏳ Test RLS policies on all tables
5. ⏳ Implement password strength validation
6. ⏳ Complete email verification flow
7. ⏳ Integrate payment gateway (Paystack/Flutterwave)
8. ⏳ Add rate limiting on authentication
9. ⏳ Implement file type/size validation
10. ⏳ Enable storage bucket security

See [SECURITY.md](SECURITY.md) for detailed security guidelines and [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for complete security analysis.

---

## 📊 Performance

### Current Metrics

**Build Size**
- Android APK: ~45MB
- Android App Bundle: ~35MB
- iOS IPA: ~50MB (estimated)

**Performance**
- App startup: <2s on mid-range devices
- Real-time messaging: <500ms latency
- Image loading: Cached with flutter_cache_manager
- Database queries: Optimized with indexes

### Optimization Recommendations

**High Priority**
1. Implement code obfuscation for release builds
2. Enable ProGuard/R8 for Android
3. Optimize image assets (WebP format)
4. Implement lazy loading for provider lists
5. Add pagination for chat messages

**Medium Priority**
1. Reduce package dependencies
2. Implement build number automation
3. Add performance monitoring (Firebase Performance)
4. Optimize database queries with explain analyze

---

## 🎯 Google Play Store Readiness

### Current Status: 40% Complete

### ✅ Ready

- [x] App icons & splash screens
- [x] Privacy policy (basic)
- [x] Terms of service (basic)
- [x] Multi-language support (English)
- [x] Responsive UI for different screen sizes
- [x] Back button handling
- [x] Proper permission requests
- [x] Push notification integration

### ⚠️ Needs Work

- [ ] Complete app store listing materials
  - [ ] Feature graphics (1024x500)
  - [ ] Screenshots (phone, 7-inch, 10-inch tablets)
  - [ ] Promotional video
- [ ] Update privacy policy with all data usage
- [ ] Complete terms of service
- [ ] Beta testing with real users
- [ ] Crash reporting integration (Sentry/Firebase Crashlytics)
- [ ] Analytics integration
- [ ] Content rating questionnaire
- [ ] Target API level compliance (API 34+)

### ❌ Critical Blockers

- [ ] Payment gateway integration
- [ ] RLS policy testing and verification
- [ ] Security audit
- [ ] Performance testing on low-end devices
- [ ] Penetration testing
- [ ] GDPR/POPIA compliance review

---

## ⏱️ Launch Timeline

### Phase 1: Pre-Production (4-6 weeks)

**Week 1-2: Security Hardening**
- Complete RLS policy testing
- Implement password validation
- Add rate limiting
- Security audit
- Penetration testing

**Week 3-4: Feature Completion**
- Payment gateway integration
- Email verification completion
- File upload validation
- Performance optimization
- Bug fixes

**Week 5-6: Testing & Polish**
- Beta testing with 50-100 users
- Fix critical bugs
- Performance tuning
- UI/UX refinements
- Documentation updates

### Phase 2: Soft Launch (2 weeks)

- Closed beta in Windhoek only
- Limit to 10 providers, 100 clients
- Monitor metrics daily
- Gather feedback
- Rapid iteration

### Phase 3: Full Launch (2 weeks)

- Open to all Namibia
- Marketing campaign activation
- Press release
- Social media push
- Monitor and scale

### Phase 4: Post-Launch (Ongoing)

- Weekly feature updates
- Monthly major releases
- User support
- Marketing optimization
- Geographic expansion planning

**Estimated Time to Production: 2-3 months**

---

## 📋 Database Schema

### Core Tables

**profiles** - User base information  
**provider_profiles** - Provider-specific data & verification  
**categories** - Service categories  
**provider_services** - Services offered by providers  
**bookings** - Service booking lifecycle  
**chat_conversations** - Chat threads  
**chat_messages** - Individual messages  
**reviews** - Provider ratings & reviews  
**portfolio_images** - Provider portfolio  
**payments** - Transaction records  
**notifications** - In-app notifications  
**device_tokens** - FCM tokens  
**notification_queue** - Push notification queue  

See `supabase/migrations/` for complete schema.

---

## 🔔 Push Notifications

### Architecture

1. **Client Action** → Booking created/status changed
2. **Database Trigger** → Fires on table change
3. **Edge Function** → `enqueue_notification` inserts to queue
4. **Cron Job** → `process_queue` runs every minute
5. **FCM API** → Sends push notification to device

### Notification Types

- Booking requests (to providers)
- Booking confirmations (to clients)
- Status updates (both)
- New messages (both)
- Payment updates (both)
- Review requests (to clients)

---

## 🧪 Testing

### Current Coverage

- Manual testing: ✅ Extensive
- Unit tests: ⚠️ Limited (~20 services)
- Widget tests: ❌ Not implemented
- Integration tests: ⚠️ Basic (provider registration)
- E2E tests: ❌ Not implemented

### Testing Priorities

1. Add unit tests for all services
2. Widget tests for critical screens
3. Integration tests for complete flows
4. E2E tests for user journeys
5. Performance testing

---

## 🐛 Known Issues

### Critical
- Payment integration placeholder only
- Some RLS policies not tested

### High
- Email verification flow incomplete
- No rate limiting on authentication
- File upload lacks size validation

### Medium
- Some print statements remain (30+)
- Limited error handling in some screens
- No offline support

### Low
- UI polish needed on admin screens
- Some loading states missing
- No dark mode

---

## 📈 Monitoring & Analytics

### Recommended Tools

**Error Tracking**
- Sentry (for Dart/Flutter errors)
- Firebase Crashlytics (for native crashes)

**Analytics**
- Firebase Analytics (user behavior)
- Mixpanel (advanced analytics)

**Performance**
- Firebase Performance Monitoring
- New Relic Mobile

**Infrastructure**
- Supabase Dashboard (DB performance)
- Sentry Performance (transaction tracking)

---

## 🤝 Contributing

This is a proprietary project. Internal contributions follow:

1. Create feature branch from `develop`
2. Make changes with clear commits
3. Test thoroughly
4. Create pull request
5. Code review required
6. Merge to `develop`
7. Deploy to staging for QA
8. Merge to `main` for production

---

## 📞 Support

**Technical Issues**
- Email: dev@hiremebuddy.com
- Slack: #hiremebuddy-dev

**Business Queries**
- Email: info@hiremebuddy.com
- Phone: +264 XX XXX XXXX

---

## 📄 License

Copyright © 2025 HireMeBuddy. All rights reserved.

This is proprietary software. Unauthorized copying, modification, distribution, or use is strictly prohibited.

---

## 🎯 Roadmap

### Q1 2026
- ✅ Core platform launch
- ✅ Push notifications
- ☐ Payment gateway integration
- ☐ 100 active providers
- ☐ 1000 active clients

### Q2 2026
- ☐ Advanced search filters
- ☐ Subscription plans for providers
- ☐ In-app wallet
- ☐ Referral program
- ☐ iOS app launch

### Q3 2026
- ☐ Provider verification badges
- ☐ Appointment scheduling
- ☐ Video consultations
- ☐ Multiple languages (Oshiwambo, Afrikaans)

### Q4 2026
- ☐ Expansion to Botswana
- ☐ B2B features
- ☐ API for third-party integrations
- ☐ Advanced analytics dashboard

---

**Version:** 1.0.0  
**Last Updated:** January 4, 2026  
**Status:** Pre-Production  
**Next Milestone:** Security Audit & Beta Launch
