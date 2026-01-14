# HireMeBuddy - Complete Application Documentation

## 📱 Project Overview

**HireMeBuddy** is a comprehensive service marketplace platform connecting Namibian service providers with clients. The system consists of three separate applications:

1. **Client App** - For users seeking services
2. **Provider App** - For service providers
3. **Admin Portal** - For platform management (Windows desktop)

### Technology Stack

- **Framework**: Flutter 3.9.2
- **State Management**: Riverpod 2.6.1
- **Backend**: Supabase (PostgreSQL, Authentication, Storage, Real-time)
- **Navigation**: GoRouter 14.8.1
- **Maps**: Google Maps Flutter
- **Payment Processing**: Custom implementation
- **Notifications**: Firebase Cloud Messaging + WorkManager
- **Video**: Video Player package

---

## 🏗️ Architecture

### Application Structure

```
hiremebuddy_flutter/
├── lib/
│   ├── core/                    # Core functionality
│   │   ├── config/             # App configuration, routing
│   │   └── providers/          # Global providers
│   ├── features/               # Feature modules
│   │   ├── auth/              # Authentication
│   │   ├── services/          # Service browsing
│   │   ├── bookings/          # Booking management
│   │   ├── chat/              # Real-time messaging
│   │   ├── provider/          # Provider features
│   │   ├── admin/             # Admin features
│   │   └── profile/           # User profiles
│   ├── shared/                 # Shared components
│   │   ├── models/            # Data models
│   │   ├── services/          # Business logic
│   │   └── widgets/           # Reusable widgets
│   ├── main.dart              # Client app entry
│   ├── main_provider.dart     # Provider app entry
│   └── main_admin.dart        # Admin app entry
├── assets/
│   └── images/                # App images and logo
├── android/                    # Android configuration
├── ios/                       # iOS configuration
├── windows/                   # Windows configuration
├── supabase/
│   └── migrations/            # Database migrations
└── build/
    └── apk_releases/          # Built APK files

```

### Database Schema

**Core Tables:**
- `profiles` - User accounts
- `provider_profiles` - Provider-specific data
- `service_categories` - Available services
- `provider_services` - Provider-service mappings
- `bookings` - Service bookings
- `reviews` - Provider reviews
- `chat_conversations` - Chat sessions
- `chat_messages` - Chat messages
- `portfolio_images` - Provider portfolios (images/videos)
- `admin_notifications` - Admin alerts
- `payments` - Payment records

---

## 🎯 Features

### Client App Features

#### 1. Authentication & Profile
- Email/password signup and login
- Profile management with avatar upload
- Phone number and location tracking

#### 2. Service Discovery
- Browse service categories
- Search functionality with suggestions
- Service suggestion system (notifies admin)
- Provider video feed (TikTok-style)
- View provider profiles and portfolios

#### 3. Booking System
- Book service providers by hourly rate
- Select date, time, and duration
- Add special instructions
- View booking history (Pending, Confirmed, Completed, Cancelled)
- Real-time booking status updates

#### 4. Communication
- Real-time chat with providers
- WhatsApp integration (message, call)
- Phone calling
- Share provider profiles via WhatsApp

#### 5. Reviews & Ratings
- Write reviews after service completion
- 5-star rating system
- View provider ratings and reviews

#### 6. Payments
- Pay providers after service completion
- View service fee breakdown
- Payment history

#### 7. Notifications
- Real-time booking notifications
- Chat message notifications
- Background notifications via WorkManager

---

### Provider App Features

#### 1. Dashboard
- Earnings overview
- Active bookings count
- Completed jobs tracker
- Rating display
- My Services management (add, edit, delete)

#### 2. Profile Management
- Set hourly rate
- Update bio and skills
- Upload profile avatar
- Add/manage contact number

#### 3. Portfolio
- Upload photos of work
- Upload video demonstrations
- Organize portfolio items
- Delete portfolio content

#### 4. Booking Management
- View booking requests (tabs: Pending, Confirmed, Completed)
- Accept/decline booking requests
- Update booking status
- Real-time booking updates
- View client details

#### 5. Earnings Tracking
- Daily/weekly/monthly earnings
- Earnings charts and graphs
- Transaction history
- Completed jobs count

#### 6. Service Management
- Add services from categories
- Set custom pricing per service
- Update service descriptions
- Toggle service availability
- Delete services

#### 7. Communication
- Chat with clients
- WhatsApp notifications
- Real-time message updates

---

### Admin Portal Features (Windows Desktop)

#### 1. Dashboard
- Platform statistics overview
- Total users, providers, bookings
- Revenue tracking
- Active bookings monitoring

#### 2. User Management
- View all users
- View user roles (client/provider/admin)
- User activity monitoring

#### 3. Provider Management
- Approve/reject providers
- View provider details
- Monitor provider performance
- Manage provider status

#### 4. Service Management
- Add/edit/delete service categories
- Manage service availability
- View service popularity

#### 5. Booking Oversight
- View all bookings
- Monitor booking statuses
- Resolve booking disputes

#### 6. Notifications
- Receive service suggestions from clients
- Bell icon with real-time badge count
- View and manage suggestion requests
- Real-time notification streaming

#### 7. Analytics
- Revenue analytics
- User growth charts
- Booking trends
- Popular services analysis

---

## 🔐 Security Features Implemented

### Authentication
- Supabase Authentication
- Row Level Security (RLS) policies
- Secure session management
- Role-based access control (client/provider/admin)

### Data Protection
- RLS on all database tables
- Secure file upload to Supabase Storage
- Input validation
- SQL injection prevention via Supabase SDK

### Communication Security
- HTTPS for all API calls
- Secure WebSocket connections for real-time features

---

## 🚀 Deployment

### Building APKs

**Separate Client and Provider APKs:**

```bash
# Client APK
flutter build apk --release --flavor client -t lib/main.dart

# Provider APK
flutter build apk --release --flavor provider -t lib/main_provider.dart
```

**Output Location**: `build/apk_releases/`
- `HireMeBuddy-Client.apk` (57.33 MB)
- `HireMeBuddy-Provider.apk` (54.36 MB)

### App Configuration

**Package IDs:**
- Client: `app.hiremebuddy.client`
- Provider: `app.hiremebuddy.provider`

**App Names:**
- Client: "HireMeBuddy Client"
- Provider: "HireMeBuddy Provider"

### Database Setup

**Required Migrations** (in order):
```sql
001_initial_schema.sql
002_create_chat_tables.sql
003_add_booking_fields.sql
...
009_create_portfolio_images.sql
010_update_completed_jobs_count.sql
011_create_admin_notifications.sql
012_add_contact_number_to_provider_profiles.sql
```

**Execute in Supabase Dashboard**: SQL Editor → Run each migration file

---

## 📦 Dependencies

### Core Dependencies
```yaml
flutter_riverpod: ^2.6.1        # State management
go_router: ^14.6.2              # Navigation
supabase_flutter: ^2.9.3        # Backend services
```

### UI & Media
```yaml
google_maps_flutter: ^2.10.0    # Maps
image_picker: ^1.1.2            # Image/video selection
video_player: ^2.9.2            # Video playback
cached_network_image: ^3.4.1    # Image caching
```

### Communication & Notifications
```yaml
flutter_local_notifications: ^18.0.1  # Local notifications
workmanager: ^0.9.0+3                 # Background tasks
url_launcher: ^6.3.1                  # External links/calls
```

### Charts & Analytics
```yaml
fl_chart: ^0.69.0               # Charts and graphs
intl: ^0.19.0                   # Date formatting
```

---

## 🎨 Branding

### App Icon
- **Logo**: HireMeBuddy leaf design with teal gradient
- **Location**: `assets/images/hiremebuddy-logo.png`
- **Generated Icons**: All density variants for Android/iOS

### Color Scheme
- **Primary**: Teal (#009688)
- **Accent**: Cyan/Light Teal
- **Text**: Dark Gray (#37474F)
- **Background**: White/Light Gray

### Tagline
"CONNECT • CREATE • COLLABORATE"

---

## 🧪 Testing

### Manual Testing Checklist

**Client App:**
- [ ] User signup and login
- [ ] Browse services
- [ ] Search for services
- [ ] Suggest new service
- [ ] View provider profiles
- [ ] Book a service
- [ ] Chat with provider
- [ ] WhatsApp integration
- [ ] Write review
- [ ] Make payment
- [ ] Receive notifications

**Provider App:**
- [ ] Provider registration
- [ ] Add services
- [ ] Edit service details
- [ ] Upload portfolio (photos/videos)
- [ ] Accept/decline bookings
- [ ] View earnings
- [ ] Chat with clients
- [ ] Update availability
- [ ] View reviews

**Admin Portal:**
- [ ] View dashboard stats
- [ ] Manage providers
- [ ] Manage services
- [ ] View notifications
- [ ] Analytics review

---

## 🐛 Known Issues & TODOs

### Critical TODOs
1. **Forgot Password** - Not implemented in login screen
2. **Provider Name in Bookings** - Placeholder "Provider" used
3. **Database Migrations** - Need to be executed in production

### Minor Issues
1. Some print statements still in code (should use logger)
2. Video feed only shows if videos exist in database

---

## 📱 Device Compatibility

### Minimum Requirements
- **Android**: API Level 21 (Android 5.0)
- **iOS**: iOS 12.0+
- **Windows**: Windows 10+

### Tested Devices
- Android devices (via physical device testing)
- Windows 10/11 desktop

---

## 🔄 Real-time Features

### Implemented Real-time Streams
1. **Bookings** - Provider and client booking lists
2. **Chat Messages** - Instant message delivery
3. **Notifications** - Admin notification badge
4. **Pending Count** - Real-time booking counts
5. **Unread Messages** - Message badge counts

### Technology
- Supabase Real-time subscriptions
- StreamProvider in Riverpod


---

## 💡 Future Enhancements

### Phase 2 Features
- [ ] In-app video/voice calls
- [ ] Advanced search filters
- [ ] Provider scheduling/calendar
- [ ] Automated reminders
- [ ] Referral system
- [ ] Loyalty program
- [ ] Multiple payment methods
- [ ] Service packages/bundles

### Phase 3 Features
- [ ] AI-powered service matching
- [ ] Augmented reality portfolio preview
- [ ] Blockchain-based reviews
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Offline mode

---

## 📞 Support & Contact

### For Users
- **Email**: support@hiremebuddy.app
- **Phone**: +264 XXX XXXX
- **Website**: www.hiremebuddy.app

### For Developers
- **Repository**: Private GitHub repository
- **Documentation**: This file
- **Security Issues**: security@hiremebuddy.app

---

## 📄 License

Proprietary - All rights reserved
© 2025 HireMeBuddy

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- All contributors and testers

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

**Last Updated**: December 12, 2025
**Version**: 1.0.0
**Build**: Client (57.33 MB), Provider (54.36 MB)
