# HireMeBuddy Database Schema

## Overview
This schema supports Client App, Provider App, and Admin Dashboard.

## Tables

### 1. `profiles`
Extends Supabase auth.users with additional user data
```sql
- id (uuid, FK to auth.users)
- role (enum: 'client', 'provider', 'admin')
- full_name (text)
- phone (text)
- profile_photo_url (text)
- location (geography/point)
- created_at (timestamp)
- updated_at (timestamp)
```

### 2. `service_categories`
Categories of services offered
```sql
- id (uuid)
- name (text) - e.g., "Plumbing", "Cleaning", "Electrical"
- description (text)
- icon_url (text)
- is_active (boolean)
- created_at (timestamp)
```

### 3. `provider_profiles`
Extended info for service providers
```sql
- id (uuid, FK to profiles)
- bio (text)
- skills (text[]) - array of skills
- hourly_rate (decimal)
- experience_years (integer)
- is_verified (boolean)
- is_available (boolean)
- rating_average (decimal)
- total_jobs (integer)
- completion_rate (decimal)
- service_radius_km (integer)
- created_at (timestamp)
- updated_at (timestamp)
```

### 4. `provider_services`
Junction table: providers to service categories
```sql
- id (uuid)
- provider_id (uuid, FK to provider_profiles)
- service_category_id (uuid, FK to service_categories)
- custom_rate (decimal) - optional override
- created_at (timestamp)
```

### 5. `bookings`
Service booking requests
```sql
- id (uuid)
- client_id (uuid, FK to profiles)
- provider_id (uuid, FK to provider_profiles)
- service_category_id (uuid, FK to service_categories)
- status (enum: 'pending', 'accepted', 'in_progress', 'completed', 'cancelled')
- description (text)
- location (geography/point)
- location_address (text)
- scheduled_date (timestamp)
- started_at (timestamp)
- completed_at (timestamp)
- estimated_duration_hours (decimal)
- final_cost (decimal)
- payment_status (enum: 'pending', 'paid', 'refunded')
- cancellation_reason (text)
- created_at (timestamp)
- updated_at (timestamp)
```

### 6. `reviews`
Client reviews for providers
```sql
- id (uuid)
- booking_id (uuid, FK to bookings)
- client_id (uuid, FK to profiles)
- provider_id (uuid, FK to provider_profiles)
- rating (integer, 1-5)
- comment (text)
- created_at (timestamp)
```

### 7. `messages`
Chat between clients and providers
```sql
- id (uuid)
- booking_id (uuid, FK to bookings)
- sender_id (uuid, FK to profiles)
- receiver_id (uuid, FK to profiles)
- message (text)
- is_read (boolean)
- created_at (timestamp)
```

### 8. `notifications`
Push notifications for all users
```sql
- id (uuid)
- user_id (uuid, FK to profiles)
- title (text)
- body (text)
- type (enum: 'booking', 'message', 'payment', 'system')
- is_read (boolean)
- data (jsonb) - additional context
- created_at (timestamp)
```

### 9. `payments`
Payment transactions
```sql
- id (uuid)
- booking_id (uuid, FK to bookings)
- amount (decimal)
- currency (text, default 'NAD')
- payment_method (text)
- transaction_id (text)
- status (enum: 'pending', 'completed', 'failed', 'refunded')
- created_at (timestamp)
```

### 10. `admin_actions`
Audit log for admin activities
```sql
- id (uuid)
- admin_id (uuid, FK to profiles)
- action_type (text)
- target_type (text) - 'user', 'booking', etc.
- target_id (uuid)
- details (jsonb)
- created_at (timestamp)
```

## Row Level Security (RLS) Policies

### Profiles
- Clients can read all provider profiles
- Users can update their own profile
- Admins can read/update all profiles

### Bookings
- Clients can create bookings
- Clients can read their own bookings
- Providers can read bookings assigned to them
- Providers can update booking status
- Admins can read all bookings

### Reviews
- Anyone can read reviews
- Clients can create reviews for completed bookings
- Admins can moderate reviews

### Messages
- Only sender and receiver can read messages
- Both parties can create messages for their bookings

## Indexes
- profiles(role)
- provider_profiles(is_available, is_verified)
- bookings(client_id, status)
- bookings(provider_id, status)
- bookings(created_at)
- reviews(provider_id)
- messages(booking_id, created_at)

## Next Steps
1. Create tables in Supabase dashboard
2. Set up RLS policies
3. Create database functions for complex queries
4. Set up real-time subscriptions
