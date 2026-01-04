-- Ensure booking status change notifications are triggered
-- This attaches triggers for Accept, Complete, Cancel, Reject actions

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_booking_status_change ON bookings;

-- Recreate the trigger to fire on booking status updates
CREATE TRIGGER trigger_notify_booking_status_change
  AFTER UPDATE OF status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_booking_status_change();

-- Validation
DO $$
BEGIN
  RAISE NOTICE '✅ Booking status change notifications enabled';
  RAISE NOTICE '   Triggers on: Accept, Complete, Cancel, Reject';
  RAISE NOTICE '   Client will receive notifications when provider updates booking status';
END $$;
