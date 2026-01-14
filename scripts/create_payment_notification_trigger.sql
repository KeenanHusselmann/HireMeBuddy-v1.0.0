-- =====================================================
-- PAYMENT STATUS NOTIFICATION TRIGGER
-- =====================================================
-- This trigger sends FCM notifications to providers when payment status changes

-- 1. Create or replace the notification function
CREATE OR REPLACE FUNCTION notify_payment_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_notification_title TEXT;
  v_notification_body TEXT;
BEGIN
  -- Only notify if payment_status actually changed
  IF OLD.payment_status IS NOT DISTINCT FROM NEW.payment_status THEN
    RETURN NEW;
  END IF;

  -- Get provider's user_id
  SELECT p.user_id INTO v_provider_user_id
  FROM profiles p
  WHERE p.id = NEW.provider_id;

  IF v_provider_user_id IS NULL THEN
    RAISE WARNING 'Provider user_id not found for booking %', NEW.id;
    RETURN NEW;
  END IF;

  -- Set notification content based on new payment status
  CASE NEW.payment_status
    WHEN 'completed' THEN
      v_notification_title := '💰 Payment Received';
      v_notification_body := 'Client has completed payment for booking';
    WHEN 'failed' THEN
      v_notification_title := '❌ Payment Failed';
      v_notification_body := 'Payment attempt failed for booking';
    WHEN 'refunded' THEN
      v_notification_title := '💸 Payment Refunded';
      v_notification_body := 'Payment has been refunded for booking';
    ELSE
      RETURN NEW;
  END CASE;

  -- Send notification to provider
  PERFORM send_fcm_notification(
    v_provider_user_id,
    v_notification_title,
    v_notification_body,
    'payment_status',
    jsonb_build_object(
      'booking_id', NEW.id,
      'old_status', OLD.payment_status,
      'new_status', NEW.payment_status
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send payment status notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 2. Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_payment_status_change ON bookings;

-- 3. Create the trigger
CREATE TRIGGER on_payment_status_change
  AFTER UPDATE OF payment_status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_payment_status_change();

-- 4. Verify the trigger was created
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_payment_status_change';

-- 5. Test notification (optional - comment out if not testing)
-- UPDATE bookings SET payment_status = 'completed' WHERE id = 'YOUR_TEST_BOOKING_ID';
