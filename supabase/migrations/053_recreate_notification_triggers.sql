-- =====================================================
-- Recreate notification triggers after RLS reset
-- =====================================================

-- Drop existing triggers (if any)
DROP TRIGGER IF EXISTS trigger_notify_new_message ON chat_messages;
DROP TRIGGER IF EXISTS trigger_notify_new_message ON messages;
DROP TRIGGER IF EXISTS trigger_notify_new_booking ON bookings;
DROP TRIGGER IF EXISTS trigger_notify_booking_status_change ON bookings;

-- Create trigger for new messages (app uses 'messages' table, not 'chat_messages')
CREATE TRIGGER trigger_notify_new_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();

-- Also create on chat_messages in case it's used
CREATE TRIGGER trigger_notify_new_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();

-- Create trigger for new bookings
CREATE TRIGGER trigger_notify_new_booking
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_booking();

-- Create trigger for booking status changes
CREATE TRIGGER trigger_notify_booking_status_change
  AFTER UPDATE OF status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_booking_status_change();
