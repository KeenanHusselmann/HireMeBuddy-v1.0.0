# Database Setup Instructions

## Required Migrations to Run in Supabase

You need to run these SQL migrations in your Supabase SQL Editor:

### 1. Migration 017: Add Verification Document Fields
**File:** `supabase/migrations/017_add_verification_documents.sql`

This migration adds the following columns to the `provider_profiles` table:
- `id_front_url` - URL of ID document front photo
- `id_back_url` - URL of ID document back photo
- `headshot_url` - URL of provider headshot photo
- `service_photos_urls` - Array of URLs for service portfolio photos
- `documents_status` - Status: pending, approved, rejected (defaults to 'pending')
- `documents_reviewed_at` - Timestamp when documents were reviewed
- `documents_reviewed_by` - Admin user ID who reviewed the documents
- `verification_notes` - Admin notes about verification

```sql
-- Copy and paste the contents of 017_add_verification_documents.sql into Supabase SQL Editor
```

### 2. Migration 018: Admin Notification Triggers
**File:** `supabase/migrations/018_notify_admin_new_provider.sql`

This migration creates:
- Function to notify admins when new providers sign up
- Function to notify admins when documents are ready for review
- Triggers that automatically create notifications

```sql
-- Copy and paste the contents of 018_notify_admin_new_provider.sql into Supabase SQL Editor
```

## Storage Bucket Setup

You need to create a storage bucket in Supabase:

1. Go to **Storage** in Supabase Dashboard
2. Click **Create a new bucket**
3. Name: `verification-documents`
4. Public bucket: **Yes** (or configure RLS policies as needed)
5. File size limit: 5MB (recommended)
6. Allowed MIME types: `image/jpeg, image/png, image/jpg`

### Storage RLS Policies (Optional - if bucket is not public)

If you want to restrict upload access, add these policies:

```sql
-- Policy: Allow authenticated users to upload their own documents
CREATE POLICY "Users can upload their verification documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow admins to view all documents
CREATE POLICY "Admins can view all verification documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
```

## Features Implemented

### 1. Provider Registration with Document Upload
- Providers upload ID photos (front/back), headshot, and service photos during registration
- Documents automatically uploaded to Supabase Storage
- URLs saved to database with status 'pending'

### 2. Admin Notifications
- Admins automatically notified when new providers sign up
- Admins notified when provider documents are ready for review
- Real-time notification count badge on admin dashboard
- Notifications screen with filtering and mark-as-read functionality

### 3. Document Review Workflow
- Admin can click on notification to view provider documents
- Full-screen image viewer for detailed inspection
- Approve/Reject buttons to update document status
- Verification notes field for admin comments
- Automatic verification status update based on document approval

### 4. Fixed Relationship Ambiguity
- Updated queries to explicitly specify foreign key relationship names
- Prevents PostgreSQL errors when multiple relationships exist between tables
- Admin providers screen now loads correctly

## Testing the Feature

1. **Run migrations** in Supabase SQL Editor (migrations 017 and 018)
2. **Create storage bucket** named `verification-documents`
3. **Test provider registration**:
   - Run provider app: `flutter run -d <device> --target lib/main_provider.dart`
   - Complete the 4-step onboarding process
   - Upload ID photos and service photos
   - Complete registration
4. **Check admin notifications**:
   - Run admin app: `flutter run -d windows --target lib/main_admin.dart`
   - Navigate to Notifications screen
   - Should see notification about new provider signup
5. **Review documents**:
   - Click on the notification
   - View uploaded documents
   - Add verification notes
   - Approve or reject documents

## Files Modified/Created

### Modified Files:
1. `lib/features/provider/screens/provider_registration_screen.dart` - Added document upload logic
2. `lib/features/admin/services/admin_service.dart` - Fixed query ambiguity
3. `lib/features/admin/models/provider_info.dart` - Added document fields
4. `lib/features/admin/screens/admin_notifications_screen.dart` - Added navigation to document review

### Created Files:
1. `supabase/migrations/017_add_verification_documents.sql` - Database schema for documents
2. `supabase/migrations/018_notify_admin_new_provider.sql` - Notification triggers
3. `lib/features/admin/screens/provider_documents_review_screen.dart` - Document review UI
4. `SUPABASE_SETUP.md` - This file

## Next Steps

After running the migrations and creating the storage bucket:
1. Test the complete flow from provider registration to admin review
2. Verify that notifications appear in real-time
3. Ensure document URLs are accessible and images load correctly
4. Test the approve/reject workflow
