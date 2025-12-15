# 🔧 Fix Booking Cancellation RLS Policy

## Issue
Clients cannot cancel bookings due to Row-Level Security (RLS) policy restriction. The error occurs because the old policy only allowed updates when `status = 'pending'`, but cancelling changes the status to 'cancelled', which violates the policy.

## Solution
Migration `024_fix_booking_cancellation_rls.sql` implements:

1. **Updated RLS Policy** - Allows clients to:
   - Cancel bookings when status is 'pending' or 'confirmed'
   - Update other fields only on 'pending' bookings

2. **Automatic Provider Notifications** - Database trigger that:
   - Detects when booking status changes to 'cancelled'
   - Creates notification for provider instantly
   - Includes booking date/time details in notification

## How to Apply

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file: `supabase/migrations/024_fix_booking_cancellation_rls.sql`
4. Copy the entire SQL content
5. Paste into SQL Editor
6. Click **Run** (or press Ctrl+Enter)

### Option 2: Supabase CLI
```bash
# From project root
supabase db push
```

## What This Fixes

### Before
❌ Client tries to cancel booking → RLS policy blocks update → Error shown  
❌ No notification sent to provider

### After
✅ Client cancels booking → Update succeeds → Booking marked as cancelled  
✅ Provider receives instant notification with booking details  
✅ Notification includes date, time, and booking reference

## Testing After Migration

1. **Test Client Cancellation**:
   - Open client app
   - Go to "My Bookings"
   - Find a pending or confirmed booking
   - Click "Cancel Booking"
   - ✅ Should succeed without errors

2. **Test Provider Notification**:
   - After cancellation, switch to provider app
   - Check notifications
   - ✅ Should see "Booking Cancelled" notification

## Migration Details

**File**: `024_fix_booking_cancellation_rls.sql`  
**Changes**:
- Drops old restrictive policy
- Creates flexible policy with status transition rules
- Adds database trigger for real-time notifications
- Grants necessary permissions

## Security Considerations

✅ Clients can only cancel THEIR OWN bookings (auth.uid() = client_id)  
✅ Clients can only cancel from 'pending' or 'confirmed' status  
✅ Providers still control their assigned bookings  
✅ All other RLS policies remain unchanged

## Need Help?

If you encounter issues:
1. Check Supabase logs for error details
2. Verify migration ran successfully (no red errors in SQL Editor)
3. Test with simple booking first
4. Check that user is properly authenticated

---

**Status**: Ready to apply ✅  
**Impact**: Low risk - only affects booking cancellation flow  
**Rollback**: Can drop new policy and recreate old one if needed
