-- SQL Script to manually fix the booking_status enum and data
-- Run this directly in Supabase SQL Editor

-- 1. Check current enum values
SELECT enum_range(NULL::booking_status);

-- 2. Check if any bookings have 'confirmed' status
SELECT COUNT(*) as confirmed_count 
FROM bookings 
WHERE status::text = 'confirmed';

-- 3. DROP the problematic CHECK constraint that doesn't include 'accepted' and 'in_progress'
-- The enum itself provides sufficient validation
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- 4. Update all 'confirmed' to 'accepted'
UPDATE bookings 
SET status = 'accepted'::booking_status
WHERE status::text = 'confirmed';

-- 5. Fix the notification trigger to use 'accepted' instead of 'confirmed'
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_client_user_id UUID;
  v_provider_name TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
BEGIN
  -- Only notify on status changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get client's user_id
  SELECT user_id INTO v_client_user_id
  FROM profiles
  WHERE id = NEW.client_id;

  -- Get provider's name
  SELECT full_name INTO v_provider_name
  FROM profiles
  WHERE id = NEW.provider_id;

  -- Set notification message based on new status
  CASE NEW.status
    WHEN 'accepted' THEN
      v_notification_title := '✅ Booking Accepted';
      v_notification_body := COALESCE(v_provider_name, 'Provider') || ' accepted your booking';
    WHEN 'in_progress' THEN
      v_notification_title := '🔧 Service Started';
      v_notification_body := COALESCE(v_provider_name, 'Provider') || ' started working on your service';
    WHEN 'completed' THEN
      v_notification_title := '✨ Service Completed';
      v_notification_body := 'Your service has been completed';
    WHEN 'cancelled' THEN
      v_notification_title := '❌ Booking Cancelled';
      v_notification_body := 'Your booking has been cancelled';
    ELSE
      RETURN NEW;
  END CASE;

  -- Send notification to client
  PERFORM send_fcm_notification(
    v_client_user_id,
    v_notification_title,
    v_notification_body,
    'booking_status',
    jsonb_build_object(
      'booking_id', NEW.id,
      'old_status', OLD.status,
      'new_status', NEW.status
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send booking status notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 6. Verify the update
SELECT status, COUNT(*) as count
FROM bookings
GROUP BY status
ORDER BY status;

-- 7. Verify the constraint is gone
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'bookings'::regclass 
AND conname = 'bookings_status_check';

-- =====================================================
-- FIX REVIEWS RLS POLICY
-- =====================================================

-- 8. First check what columns exist in reviews table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'reviews' 
ORDER BY ordinal_position;

-- 9. Add missing columns if they don't exist (migration fix)
DO $$
BEGIN
  -- Add client_id if using reviewer_id instead
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reviews' AND column_name = 'client_id'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reviews' AND column_name = 'reviewer_id'
  ) THEN
    ALTER TABLE reviews RENAME COLUMN reviewer_id TO client_id;
    RAISE NOTICE 'Renamed reviewer_id to client_id';
  END IF;

  -- Add provider_id if using reviewed_id instead
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reviews' AND column_name = 'provider_id'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reviews' AND column_name = 'reviewed_id'
  ) THEN
    ALTER TABLE reviews RENAME COLUMN reviewed_id TO provider_id;
    RAISE NOTICE 'Renamed reviewed_id to provider_id';
  END IF;
END $$;

-- 10. Reload the schema cache
NOTIFY pgrst, 'reload schema';

-- 11. Fix reviews table RLS policies
-- The issue: auth.uid() is the user_id, but we need to match to profile
DROP POLICY IF EXISTS "reviews_insert_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_update_policy" ON reviews;

-- Create correct INSERT policy
-- This checks if the user owns the booking being reviewed
CREATE POLICY "reviews_insert_policy"
  ON reviews FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bookings b
      JOIN profiles p ON p.id = b.client_id
      WHERE b.id = booking_id
      AND p.user_id = auth.uid()
    )
  );

-- Create correct UPDATE policy
CREATE POLICY "reviews_update_policy"
  ON reviews FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bookings b
      JOIN profiles p ON p.id = b.client_id
      WHERE b.id = booking_id
      AND p.user_id = auth.uid()
    )
  );

-- 10. Verify reviews policies
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'reviews'
ORDER BY policyname;

-- Note: The booking_status ENUM already provides validation.
-- The CHECK constraint was redundant and outdated (didn't include 'accepted' or 'in_progress').


