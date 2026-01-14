-- Migration: Fix booking cancellation RLS policy
-- Allow clients to cancel their own bookings (pending or confirmed)
-- Add trigger to notify provider when booking is cancelled

-- Drop old restrictive policies
DROP POLICY IF EXISTS "Clients can update pending bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can update own bookings" ON bookings;

-- Create new policy allowing clients to cancel their bookings
CREATE POLICY "Clients can update own bookings"
  ON bookings FOR UPDATE
  USING (
    auth.uid() = client_id 
    AND status IN ('pending', 'confirmed')
  )
  WITH CHECK (
    auth.uid() = client_id
    AND status IN ('pending', 'confirmed', 'cancelled')
  );

-- Create function to notify provider when booking is cancelled
CREATE OR REPLACE FUNCTION notify_provider_booking_cancelled()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify if status changed to cancelled
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    -- Insert notification for provider
    INSERT INTO notifications (
      user_id,
      type,
      title,
      body,
      is_read
    )
    VALUES (
      NEW.provider_id,
      'booking_update',
      'Booking Cancelled',
      'A client has cancelled their booking scheduled for ' || 
        TO_CHAR(NEW.booking_date, 'Day, Month DD, YYYY') || ' at ' || 
        TO_CHAR(NEW.booking_time, 'HH24:MI'),
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_booking_cancelled ON bookings;

-- Create trigger for booking cancellation notifications
CREATE TRIGGER on_booking_cancelled
  AFTER UPDATE ON bookings
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION notify_provider_booking_cancelled();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION notify_provider_booking_cancelled() TO authenticated;
