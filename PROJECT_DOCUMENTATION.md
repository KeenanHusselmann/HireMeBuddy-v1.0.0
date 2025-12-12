# HireMeBuddy - Project Documentation

**Last Updated:** December 12, 2025  
**Project Type:** Flutter Mobile Application (Service Marketplace Platform)  
**Version:** 1.0.0+1  
**Status:** Active Development - Production Ready (Beta)

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Database Schema](#database-schema)
6. [Features & Functionality](#features--functionality)
7. [Development Roadmap](#development-roadmap)
8. [Setup & Installation](#setup--installation)
9. [Key Components](#key-components)
10. [API Integration](#api-integration)
11. [State Management](#state-management)
12. [Testing Strategy](#testing-strategy)

---

## 🎯 Project Overview

**HireMeBuddy** is a comprehensive service marketplace platform connecting clients with service providers in Namibia. The ecosystem consists of three applications:

1. **Client Mobile App** (Current Project) - For customers seeking services
2. **Provider Mobile App** - For service providers managing bookings
3. **Admin Web Dashboard** - For platform administration

### Core Business Model
- Service-based marketplace (plumbing, cleaning, electrical, etc.)
- Location-based provider matching
- Real-time booking and chat system
- Review and rating system
- Secure payment processing with escrow

---

## 🏗️ Architecture

### Application Architecture
```
┌─────────────────────────────────────────────────────┐
│                  Flutter Apps                        │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │
│  │   Client   │  │  Provider  │  │    Admin     │  │
│  │    App     │  │    App     │  │   Dashboard  │  │
│  └────────────┘  └────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              Supabase Backend                        │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐   │
│  │PostgreSQL│  │   Auth   │  │   Storage      │   │
│  │ Database │  │  System  │  │   (S3-like)    │   │
│  └──────────┘  └──────────┘  └────────────────┘   │
│  ┌──────────┐  ┌──────────┐                        │
│  │ Realtime │  │    RLS   │                        │
│  │Websocket │  │ Policies │                        │
│  └──────────┘  └──────────┘                        │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│           External Services                          │
│  • Google Maps API                                   │
│  • Firebase Cloud Messaging                          │
│  • Payment Gateway (TBD)                            │
└─────────────────────────────────────────────────────┘
```

### Design Pattern
- **Clean Architecture** principles
- **Feature-first** folder structure
- **Provider pattern** with Riverpod for state management
- **Repository pattern** for data access
- **MVVM-inspired** separation of concerns

---

## 🛠️ Technology Stack

### Frontend Framework
- **Flutter** 3.9.2+ (Dart SDK)
- **Material Design** UI components
- Cross-platform (Android, iOS, Web, Desktop)

### State Management
- **flutter_riverpod** 2.6.1 - Modern reactive state management
- Provides dependency injection and state observation

### Navigation
- **go_router** 14.6.2 - Declarative routing with deep linking support

### Backend as a Service
- **Supabase** 2.9.3
  - PostgreSQL database
  - Built-in authentication
  - Row Level Security (RLS)
  - Real-time subscriptions
  - File storage

### Key Dependencies

#### Networking & API
- **dio** 5.7.0 - HTTP client for REST APIs

#### Location Services
- **google_maps_flutter** 2.10.0 - Interactive maps
- **geolocator** 13.0.2 - Device location tracking
- **geocoding** 3.0.0 - Address to coordinates conversion

#### Media & Images
- **cached_network_image** 3.4.1 - Optimized image loading with caching
- **image_picker** 1.1.2 - Camera and gallery access
- **flutter_svg** 2.0.10 - SVG rendering

#### Forms & Validation
- **flutter_form_builder** 9.4.2 - Advanced form handling

#### Notifications
- **flutter_local_notifications** 18.0.1 - Local push notifications
- **workmanager** 0.9.0+3 - Background task scheduling

#### UI Enhancements
- **flutter_animate** 4.5.0 - Declarative animations
- **shimmer** 3.0.0 - Loading skeleton screens

#### Utilities
- **url_launcher** 6.3.1 - Open external URLs and apps
- **uuid** 4.5.1 - Unique identifier generation
- **intl** 0.19.0 - Internationalization and date formatting
- **timeago** 3.7.0 - Human-readable time differences
- **shared_preferences** 2.3.4 - Key-value local storage

---

## 📁 Project Structure

```
hiremebuddy_flutter/
│
├── android/                      # Android native configuration
├── ios/                          # iOS native configuration
├── web/                          # Web platform support
├── linux/                        # Linux desktop support
├── macos/                        # macOS desktop support
├── windows/                      # Windows desktop support
│
├── assets/                       # Static assets
│   └── images/
│       └── hiremebuddy-logo.png
│
├── docs/                         # Project documentation
│   ├── database_schema.md
│   └── implementation_roadmap.md
│
├── supabase/                     # Backend configuration
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   └── 003_seed_data.sql
│   └── README.md
│
├── lib/                          # Main application code
│   ├── main.dart                 # Client app entry point
│   ├── main_provider.dart        # Provider app entry point
│   │
│   ├── core/                     # Core application infrastructure
│   │   ├── config/               # App-wide configuration
│   │   │   ├── app_router.dart           # Client routing
│   │   │   ├── provider_router.dart      # Provider routing
│   │   │   └── supabase_config.dart      # Backend config
│   │   │
│   │   ├── constants/            # App constants
│   │   │
│   │   ├── providers/            # Global providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── provider_provider.dart
│   │   │   └── supabase_providers.dart
│   │   │
│   │   ├── theme/                # UI theming
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   │
│   │   └── utils/                # Utility functions
│   │
│   ├── features/                 # Feature modules (feature-first)
│   │   │
│   │   ├── auth/                 # Authentication feature
│   │   │   ├── data/             # Data layer (repositories)
│   │   │   ├── models/           # Feature-specific models
│   │   │   ├── providers/        # Feature state providers
│   │   │   ├── screens/          # UI screens
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   └── widgets/          # Feature widgets
│   │   │
│   │   ├── bookings/             # Booking management
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   │   ├── booking_screen.dart
│   │   │   │   ├── my_bookings_screen.dart
│   │   │   │   └── add_review_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── services/             # Service discovery & browsing
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── service_list_screen.dart
│   │   │   │   └── provider_detail_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── chat/                 # Messaging system
│   │   │   ├── screens/
│   │   │   │   ├── conversations_screen.dart
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── provider_chat_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── profile/              # User profile management
│   │   │   ├── screens/
│   │   │   │   └── profile_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   └── provider/             # Provider-specific features
│   │       ├── screens/
│   │       │   ├── provider_splash_screen.dart
│   │       │   ├── provider_login_screen.dart
│   │       │   ├── provider_signup_screen.dart
│   │       │   ├── provider_registration_screen.dart
│   │       │   ├── provider_dashboard_screen.dart
│   │       │   ├── provider_bookings_screen.dart
│   │       │   └── provider_reviews_screen.dart
│   │       └── widgets/
│   │
│   └── shared/                   # Shared across features
│       ├── models/               # Domain models
│       │   ├── user_profile.dart
│       │   ├── provider_profile.dart
│       │   ├── service_category.dart
│       │   ├── booking.dart
│       │   ├── review.dart
│       │   └── message.dart
│       │
│       ├── services/             # Business logic services
│       │   ├── auth_service.dart
│       │   ├── booking_service.dart
│       │   ├── message_service.dart
│       │   ├── provider_service.dart
│       │   ├── service_category_service.dart
│       │   ├── review_service.dart
│       │   ├── notification_service.dart
│       │   └── workmanager_notification_service.dart
│       │
│       ├── providers/            # Shared state providers
│       │
│       └── widgets/              # Reusable UI components
│           └── app_logo.dart
│
├── test/                         # Unit and widget tests
│   └── widget_test.dart
│
├── analysis_options.yaml         # Dart analyzer configuration
├── pubspec.yaml                  # Dependencies & assets
└── README.md                     # Basic project info
```

---

## 💾 Database Schema

### Entity Relationship Overview

```
┌──────────────┐         ┌──────────────────┐         ┌────────────────┐
│   profiles   │────────▶│ provider_profiles│────────▶│provider_services│
│  (all users) │         │  (service pros)  │         │  (many-to-many)│
└──────────────┘         └──────────────────┘         └────────────────┘
       │                          │                             │
       │                          │                             │
       ▼                          ▼                             ▼
┌──────────────┐         ┌──────────────────┐         ┌────────────────┐
│   bookings   │────────▶│     reviews      │         │service_categories
│              │         │                  │         │                │
└──────────────┘         └──────────────────┘         └────────────────┘
       │
       │
       ▼
┌──────────────┐         ┌──────────────────┐
│   messages   │         │  notifications   │
│              │         │                  │
└──────────────┘         └──────────────────┘
```

### Core Tables

#### 1. **profiles**
Extends Supabase `auth.users` with additional user data.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Foreign key to auth.users |
| role | ENUM | 'client', 'provider', 'admin' |
| full_name | TEXT | User's full name |
| phone | TEXT | Contact phone number |
| profile_photo_url | TEXT | Profile image URL |
| location | GEOGRAPHY | User's location (PostGIS) |
| created_at | TIMESTAMP | Account creation date |
| updated_at | TIMESTAMP | Last profile update |

#### 2. **service_categories**
Categories of services offered on the platform.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique identifier |
| name | TEXT | Category name (e.g., "Plumbing") |
| description | TEXT | Category description |
| icon_url | TEXT | Category icon image |
| is_active | BOOLEAN | Whether category is available |
| created_at | TIMESTAMP | Creation timestamp |

#### 3. **provider_profiles**
Extended information for service providers.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK, FK) | Links to profiles.id |
| bio | TEXT | Provider biography |
| skills | TEXT[] | Array of skills/specializations |
| hourly_rate | DECIMAL | Base hourly rate |
| experience_years | INTEGER | Years of experience |
| is_verified | BOOLEAN | Admin verification status |
| is_available | BOOLEAN | Current availability |
| rating_average | DECIMAL | Average rating (1-5) |
| total_jobs | INTEGER | Completed job count |
| completion_rate | DECIMAL | Job completion percentage |
| service_radius_km | INTEGER | Service area radius |
| created_at | TIMESTAMP | Registration date |
| updated_at | TIMESTAMP | Last update |

#### 4. **provider_services**
Junction table linking providers to service categories.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique identifier |
| provider_id | UUID (FK) | Reference to provider_profiles |
| service_category_id | UUID (FK) | Reference to service_categories |
| custom_rate | DECIMAL | Optional rate override |
| created_at | TIMESTAMP | Link creation date |

#### 5. **bookings**
Service booking requests and their lifecycle.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique booking identifier |
| client_id | UUID (FK) | Reference to profiles (client) |
| provider_id | UUID (FK) | Reference to provider_profiles |
| service_category_id | UUID (FK) | Service type |
| status | ENUM | 'pending', 'accepted', 'in_progress', 'completed', 'cancelled' |
| description | TEXT | Job description from client |
| location | GEOGRAPHY | Job location (PostGIS) |
| location_address | TEXT | Human-readable address |
| scheduled_date | TIMESTAMP | When job is scheduled |
| started_at | TIMESTAMP | Actual start time |
| completed_at | TIMESTAMP | Completion time |
| estimated_duration_hours | DECIMAL | Expected duration |
| final_cost | DECIMAL | Final price |
| payment_status | ENUM | 'pending', 'paid', 'refunded' |
| cancellation_reason | TEXT | If cancelled, why |
| created_at | TIMESTAMP | Booking request time |
| updated_at | TIMESTAMP | Last status update |

#### 6. **reviews**
Client reviews and ratings for providers.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique review identifier |
| booking_id | UUID (FK) | Associated booking |
| client_id | UUID (FK) | Reviewer (client) |
| provider_id | UUID (FK) | Reviewed provider |
| rating | INTEGER | Rating (1-5 stars) |
| comment | TEXT | Written review |
| created_at | TIMESTAMP | Review submission date |

#### 7. **messages**
Chat messages between clients and providers.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique message identifier |
| booking_id | UUID (FK) | Associated booking |
| sender_id | UUID (FK) | Message sender |
| receiver_id | UUID (FK) | Message recipient |
| content | TEXT | Message text |
| is_read | BOOLEAN | Read status |
| created_at | TIMESTAMP | Message timestamp |

#### 8. **notifications**
Push notifications for all users.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique notification ID |
| user_id | UUID (FK) | Recipient user |
| title | TEXT | Notification title |
| body | TEXT | Notification content |
| type | ENUM | 'booking', 'message', 'payment', 'system' |
| is_read | BOOLEAN | Read status |
| data | JSONB | Additional context data |
| created_at | TIMESTAMP | Notification time |

#### 9. **payments**
Payment transaction records.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique payment ID |
| booking_id | UUID (FK) | Associated booking |
| amount | DECIMAL | Payment amount |
| currency | TEXT | Currency code (default 'NAD') |
| payment_method | TEXT | Payment method used |
| transaction_id | TEXT | External transaction reference |
| status | ENUM | 'pending', 'completed', 'failed', 'refunded' |
| created_at | TIMESTAMP | Payment time |

#### 10. **admin_actions**
Audit log for administrative activities.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID (PK) | Unique action ID |
| admin_id | UUID (FK) | Admin who performed action |
| action_type | TEXT | Type of action |
| target_type | TEXT | Entity type ('user', 'booking', etc.) |
| target_id | UUID | Target entity ID |
| details | JSONB | Additional action details |
| created_at | TIMESTAMP | Action timestamp |

### Database Indexes
Optimized for common query patterns:
- `profiles(role)`
- `provider_profiles(is_available, is_verified)`
- `bookings(client_id, status)`
- `bookings(provider_id, status)`
- `bookings(created_at)`
- `reviews(provider_id)`
- `messages(booking_id, created_at)`

### Row Level Security (RLS)
Supabase RLS policies ensure data security:
- Users can only read their own profile and public provider data
- Bookings are only visible to involved parties and admins
- Messages are private between sender and receiver
- Providers can only update their own availability and booking status
- Admins have elevated access for moderation

---

## ✨ Features & Functionality

### Client App Features

#### 1. **Authentication & Onboarding**
- Email/password registration
- Social authentication (optional)
- Phone number verification
- Profile setup wizard
- Password recovery

#### 2. **Service Discovery**
- Browse service categories
- Search providers by service type
- Filter by:
  - Location/distance
  - Rating
  - Price range
  - Availability
- View featured providers

#### 3. **Provider Details**
- View provider profile
- See ratings and reviews
- Check availability calendar
- View skills and experience
- See completed jobs count
- Initiate booking

#### 4. **Booking Management**
- Create new booking request
- Provide job description
- Set location (map picker)
- Schedule date/time
- Get price estimate
- Track booking status
- View active bookings
- Access booking history
- Cancel bookings with reason

#### 5. **Communication**
- Real-time chat with providers
- Message notifications
- Booking-specific conversations
- Message history

#### 6. **Reviews & Ratings**
- Rate completed jobs (1-5 stars)
- Write detailed reviews
- View own review history
- Browse provider reviews

#### 7. **User Profile**
- Edit personal information
- Upload profile photo
- Update contact details
- Manage preferences
- View booking statistics

#### 8. **Notifications**
- Booking status updates
- New messages alerts
- Payment confirmations
- System announcements
- Background notification checks

### Provider App Features

#### 1. **Provider Registration**
- Extended signup process
- Skill and service selection
- Hourly rate configuration
- Service area definition
- Document upload (ID, certifications)
- Bank account details
- Verification pending status

#### 2. **Dashboard**
- Earnings overview
- Active bookings summary
- Performance metrics
- Quick availability toggle
- Recent reviews

#### 3. **Booking Management**
- View incoming requests
- Accept/decline bookings
- Track active jobs
- Navigate to job location
- Update job status
- Mark jobs complete
- View booking history

#### 4. **Provider Profile**
- Edit bio and skills
- Update hourly rates
- Upload portfolio images
- Manage service offerings
- Set availability schedule
- View analytics

#### 5. **Earnings & Payments**
- Transaction history
- Pending payments
- Completed payments
- Withdrawal requests
- Earnings reports
- Tax documentation

#### 6. **Reviews Management**
- View received reviews
- Respond to reviews (future)
- Track rating trends

#### 7. **Communication**
- Chat with clients
- Respond to inquiries
- Booking-related messaging

### Admin Dashboard Features (Planned)

#### 1. **User Management**
- View all clients and providers
- User details and activity
- Account suspension/ban
- User verification

#### 2. **Provider Verification**
- Pending verification queue
- Review submitted documents
- Approve/reject applications
- Request additional information

#### 3. **Booking Oversight**
- View all platform bookings
- Monitor booking trends
- Dispute resolution
- Refund processing

#### 4. **Analytics & Reports**
- User growth charts
- Booking statistics
- Revenue tracking
- Popular services analysis
- Geographic distribution
- Performance metrics

#### 5. **Content Management**
- Service categories CRUD
- System notifications
- FAQ management
- Terms and conditions
- Privacy policy

#### 6. **Platform Configuration**
- Commission rates
- Payment gateway settings
- Email templates
- App settings

---

## 🗺️ Development Roadmap

### Phase 1: Foundation & Database ✅ (Week 1-2)
**Status:** In Progress

- [x] Design database schema
- [x] Plan implementation roadmap
- [ ] Create Supabase tables (migrations ready)
- [ ] Set up Row Level Security policies
- [ ] Configure storage buckets
- [ ] Test database functions

**Deliverable:** Fully configured Supabase backend

### Phase 2: Shared Models & Services (Week 2-3)
**Status:** Partially Complete

- [x] Create data models
- [x] Set up Supabase service layer
- [x] Implement authentication service
- [x] Create Riverpod providers
- [ ] Complete booking service implementation
- [ ] Finalize chat service
- [ ] Add comprehensive error handling

**Deliverable:** Robust data layer for Client App

### Phase 3: Client App Features (Week 3-5)
**Status:** In Progress

- [x] Authentication screens
- [x] Basic navigation setup
- [ ] Home & service discovery
- [ ] Provider search and filters
- [ ] Provider detail page
- [ ] Complete booking flow
- [ ] My bookings screen
- [ ] Chat implementation
- [ ] Profile management
- [ ] Review system

**Deliverable:** Functional Client App MVP

### Phase 4: Provider App (Week 6-8)
**Status:** Scaffolded

- [x] Create separate entry point
- [x] Provider authentication screens
- [ ] Provider registration flow
- [ ] Provider dashboard
- [ ] Booking management
- [ ] Earnings tracking
- [ ] Profile management
- [ ] Document upload

**Deliverable:** Functional Provider App

### Phase 5: Admin Dashboard (Week 9-10)
**Status:** Not Started

- [ ] Create Flutter web project
- [ ] User management interface
- [ ] Provider verification system
- [ ] Booking oversight
- [ ] Analytics dashboards
- [ ] Content management
- [ ] Platform settings

**Deliverable:** Admin web dashboard

### Phase 6: Real-time & Notifications (Week 11)
**Status:** Partially Complete

- [x] Local notification setup
- [x] Background task scheduler
- [ ] Real-time booking updates
- [ ] Push notification integration (FCM)
- [ ] Location tracking for active bookings
- [ ] Real-time chat implementation

### Phase 7: Payment Integration (Week 12)
**Status:** Not Started

- [ ] Research Namibian payment gateways
- [ ] Implement payment gateway
- [ ] Escrow system
- [ ] Provider payout system
- [ ] Commission calculation
- [ ] Payment history

### Phase 8: Testing & Deployment (Week 13-14)
**Status:** Not Started

- [ ] Unit testing
- [ ] Integration testing
- [ ] User acceptance testing
- [ ] Performance optimization
- [ ] Play Store preparation
- [ ] App Store preparation
- [ ] Web hosting setup

---

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code or IntelliJ IDEA
- Git
- Supabase account

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd hiremebuddy_flutter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Run migrations from `supabase/migrations/` in SQL editor
   - Update `lib/core/config/supabase_config.dart` with your credentials:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   }
   ```

4. **Configure Google Maps (Optional)**
   - Get API key from Google Cloud Console
   - Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
   ```
   - Add to `ios/Runner/AppDelegate.swift`

5. **Run the App**
   
   **Client App:**
   ```bash
   flutter run lib/main.dart
   ```
   
   **Provider App:**
   ```bash
   flutter run lib/main_provider.dart
   ```

### Environment Setup

**For Android:**
```bash
flutter doctor -v
```
Ensure Android SDK and Android Studio are properly configured.

**For iOS:**
```bash
flutter doctor -v
```
Ensure Xcode and CocoaPods are installed.

---

## 🔑 Key Components

### Core Configuration

#### **app_router.dart**
Client app navigation configuration using GoRouter.
```dart
- Routes: /splash, /login, /signup, /home, /bookings, /chat, /profile
- Deep linking support
- Authentication guards
- Named routes for easy navigation
```

#### **provider_router.dart**
Provider app navigation configuration.
```dart
- Routes: /provider/splash, /provider/login, /provider/dashboard, etc.
- Role-based routing
- Separate navigation flow for providers
```

#### **supabase_config.dart**
Backend connection configuration.
```dart
- Supabase URL and API keys
- Auth flow configuration (PKCE)
- Client initialization
```

### Shared Models

#### **user_profile.dart**
```dart
class UserProfile {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

enum UserRole { client, provider, admin }
```

#### **booking.dart**
```dart
class Booking {
  final String id;
  final String clientId;
  final String providerId;
  final String serviceCategoryId;
  final BookingStatus status;
  final String description;
  final double? finalCost;
  final DateTime scheduledDate;
  // ... additional fields
}

enum BookingStatus {
  pending, accepted, inProgress, completed, cancelled
}
```

### Services Layer

#### **auth_service.dart**
Handles authentication logic:
- Sign up with email/password
- Sign in
- Sign out
- Password recovery
- Session management
- Profile creation

#### **booking_service.dart**
Manages bookings:
- Create booking
- Fetch user bookings
- Update booking status
- Cancel booking
- Fetch booking details

#### **message_service.dart**
Chat functionality:
- Send messages
- Fetch conversation history
- Mark messages as read
- Real-time message subscription

#### **provider_service.dart**
Provider-related operations:
- Search providers
- Fetch provider details
- Update provider profile
- Manage availability

### State Management with Riverpod

#### **Providers**
```dart
// Global Supabase client
final supabaseClientProvider = Provider<SupabaseClient>(...);

// Current authenticated user stream
final currentUserProvider = StreamProvider<User?>(...);

// Authentication state
final isAuthenticatedProvider = Provider<bool>(...);

// Auth state notifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
```

### Theming

#### **app_theme.dart**
Material Theme configuration with:
- Primary color: Deep Orange (#FF5722)
- Custom color scheme
- Typography styles
- Component themes (buttons, cards, inputs)
- Dark mode support (future)

#### **app_colors.dart**
Color constants used throughout the app.

---

## 🔌 API Integration

### Supabase Integration

#### Authentication
```dart
// Sign up
await supabase.auth.signUp(
  email: email,
  password: password,
);

// Sign in
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

#### Database Queries
```dart
// Fetch providers
final response = await supabase
  .from('provider_profiles')
  .select('*, profiles(*)')
  .eq('is_available', true);

// Insert booking
await supabase.from('bookings').insert({
  'client_id': clientId,
  'provider_id': providerId,
  'status': 'pending',
  // ...
});
```

#### Real-time Subscriptions
```dart
// Listen to new messages
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('receiver_id', userId)
  .listen((data) {
    // Handle new messages
  });
```

#### Storage
```dart
// Upload profile photo
await supabase.storage
  .from('profiles')
  .upload('public/$userId.jpg', imageFile);

// Get public URL
final url = supabase.storage
  .from('profiles')
  .getPublicUrl('public/$userId.jpg');
```

---

## 🎨 State Management

### Riverpod Architecture

**Provider Types Used:**

1. **Provider** - For simple values and services
   ```dart
   final supabaseClientProvider = Provider<SupabaseClient>(...);
   ```

2. **StreamProvider** - For reactive data streams
   ```dart
   final currentUserProvider = StreamProvider<User?>(...);
   ```

3. **StateNotifierProvider** - For complex state management
   ```dart
   final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
   ```

4. **FutureProvider** - For async operations
   ```dart
   final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>(...);
   ```

### State Flow Example
```
User Action (UI)
    ↓
Consumer Widget reads Provider
    ↓
Provider calls Service
    ↓
Service makes API call to Supabase
    ↓
Response flows back through layers
    ↓
Provider notifies listeners
    ↓
UI rebuilds automatically
```

---

## 🧪 Testing Strategy

### Testing Approach

#### Unit Tests
- Test individual functions and services
- Mock Supabase responses
- Validate business logic
- Test data models serialization

#### Widget Tests
- Test UI components in isolation
- Verify widget behavior
- Test user interactions
- Validate navigation flows

#### Integration Tests
- End-to-end user flows
- Test app with real backend
- Validate complete features
- Performance testing

### Test Structure
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   ├── auth/
│   ├── bookings/
│   └── shared/
└── integration/
    ├── booking_flow_test.dart
    ├── chat_flow_test.dart
    └── auth_flow_test.dart
```

---

## 📝 Development Guidelines

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` package rules
- Write descriptive variable and function names
- Add comments for complex logic

### Git Workflow
- Use feature branches
- Write clear commit messages
- Create pull requests for review
- Keep commits atomic and focused

### File Naming
- Use snake_case for files: `booking_service.dart`
- Use PascalCase for classes: `BookingService`
- Use camelCase for variables: `bookingId`

### Project Conventions
- Feature-first folder structure
- Separate concerns: UI, business logic, data
- Use dependency injection via Riverpod
- Handle errors gracefully with try-catch
- Add loading states for async operations
- Implement proper null safety

---

## 🔒 Security Considerations

### Row Level Security (RLS)
- Implemented at database level (Supabase)
- Users can only access their own data
- Providers see only relevant bookings
- Admins have elevated permissions

### Authentication
- Secure password hashing (handled by Supabase)
- JWT token-based authentication
- PKCE flow for mobile apps
- Automatic token refresh

### Data Validation
- Client-side form validation
- Server-side validation via RLS
- Input sanitization
- Type safety with Dart

### Privacy
- User data encrypted at rest
- HTTPS for all API calls
- Secure storage for sensitive data
- GDPR-compliant data handling (future)

---

## 📊 Performance Optimization

### Implemented Optimizations
- **Cached network images** for faster loading
- **Pagination** for large data lists
- **Lazy loading** of screens and data
- **Shimmer effects** during loading
- **Debouncing** for search inputs
- **Split APKs** by architecture (~45% size reduction)
- **Code obfuscation** for security and size
- **Debug symbol separation** for crash analysis
- **Tree shaking** for unused code removal
- **Build automation** with PowerShell scripts

### Build Optimization Results
| Build Type | Size | Notes |
|------------|------|-------|
| Universal APK | 19.0 MB | Not recommended |
| arm64-v8a APK | 17.8 MB | Modern devices |
| armeabi-v7a APK | 15.3 MB | Older devices |
| Play Store Download | 10-15 MB | ~45% reduction |

### Future Optimizations
- Code splitting for web platform
- Advanced image compression
- Background data sync
- Offline mode with local caching
- Database query optimization
- Implement CDN for media assets

---

## 🐛 Known Issues & Limitations

### Current Limitations
1. ⚠️ **CRITICAL**: Environment variables need to be secured (see SECURITY.md)
2. Payment gateway integration needs production credentials
3. Location tracking for active jobs pending
4. Limited offline functionality
5. No multi-language support yet
6. Git repository not initialized

### Completed Features
✅ Admin dashboard fully implemented  
✅ Real-time chat system working  
✅ Search functionality with service suggestions  
✅ Provider video feed (TikTok-style)  
✅ Portfolio management (images/videos)  
✅ Booking system with status tracking  
✅ Review and rating system  

### Technical Debt
- ⚠️ Replace print statements with logger (30+ instances)
- ⚠️ Implement Row Level Security policies in Supabase
- Add comprehensive unit test coverage
- Improve error handling in edge cases
- Add API response caching
- Initialize Git repository for version control

---

## 🔮 Future Enhancements

### Planned Features
- [ ] Multi-language support (English, Afrikaans)
- [ ] Dark mode
- [ ] Provider portfolio with images
- [ ] Advanced search filters
- [ ] Push notifications with Firebase
- [ ] In-app calling
- [ ] Video chat for consultations
- [ ] Service packages and promotions
- [ ] Referral program
- [ ] Loyalty rewards
- [ ] AI-powered provider matching
- [ ] Offline mode

### Technical Improvements
- [ ] Implement CI/CD pipeline
- [ ] Add comprehensive testing
- [ ] Performance monitoring
- [ ] Crash reporting
- [ ] Analytics integration
- [ ] A/B testing framework

---

## � Security Considerations

### Critical Security Tasks (Before Production)
⚠️ **MUST ADDRESS** - See [SECURITY.md](SECURITY.md) for detailed implementation

1. **Environment Variables**
   - Move Supabase credentials to `.env` file
   - Implement `flutter_dotenv` package
   - Never commit credentials to version control
   - Use separate dev/prod credentials

2. **Row Level Security (RLS)**
   - Execute all Supabase migration files
   - Verify RLS policies on all tables
   - Test access controls with different user roles
   - Enable RLS on storage buckets

3. **Authentication Hardening**
   - Implement password strength requirements
   - Add email verification
   - Enable rate limiting on login
   - Complete forgot password functionality
   - Consider 2FA for providers and admins

4. **Payment Security**
   - Never store card details in database
   - Use Supabase Edge Functions for processing
   - Implement webhook verification
   - Ensure PCI DSS compliance

5. **Code Quality**
   - Replace all `print()` statements with logger
   - Remove sensitive data from logs
   - Implement proper error handling
   - Add input validation and sanitization

### Current Security Status
- ✅ SSL/TLS encryption via Supabase
- ✅ Supabase authentication system
- ✅ Code obfuscation in release builds
- ⚠️ Environment variables need implementation
- ⚠️ RLS policies need verification
- ⚠️ Logging needs improvement

---

## �📞 Support & Contact

### For Developers
- Review `implementation_roadmap.md` for detailed tasks
- Check `database_schema.md` for database structure
- Follow Flutter and Dart best practices
- Use Supabase documentation for backend queries

### Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---

## 📄 License

Copyright © 2025 HireMeBuddy. All rights reserved.

---

**Document Version:** 2.0  
**Last Updated:** December 12, 2025  
**Project Status:** Active Development - Production Ready (Beta)  
**Build Status:** Optimized builds available  
**Security Status:** ⚠️ Requires production hardening  
