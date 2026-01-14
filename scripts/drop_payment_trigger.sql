-- Drop the payment trigger completely to fix the OLD.payment_status error
DROP TRIGGER IF EXISTS trigger_payment_notification ON bookings;
DROP FUNCTION IF EXISTS notify_payment_status_change();

-- Drop the review trigger to fix the pp.user_id error
DROP TRIGGER IF EXISTS trigger_review_notification ON reviews;
DROP FUNCTION IF EXISTS notify_review_submitted();
