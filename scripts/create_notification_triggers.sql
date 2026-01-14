-- Trigger to notify provider when client submits a review
CREATE OR REPLACE FUNCTION notify_review_submitted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_client_name TEXT;
BEGIN
  -- Get provider's user_id from provider_profiles
  SELECT pp.user_id INTO v_provider_user_id
  FROM provider_profiles pp
  WHERE pp.id = NEW.provider_id;
  
  -- Get client name from profiles
  SELECT p.full_name INTO v_client_name
  FROM profiles p
  WHERE p.id = NEW.client_id;
  
  -- Send notification to provider
  IF v_provider_user_id IS NOT NULL THEN
    PERFORM send_fcm_notification(
      v_provider_user_id,
      'New Review Received',
      COALESCE(v_client_name, 'A client') || ' left you a ' || NEW.rating || '-star review',
      'review',
      jsonb_build_object(
        'review_id', NEW.id,
        'booking_id', NEW.booking_id,
        'rating', NEW.rating
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for new reviews
DROP TRIGGER IF EXISTS trigger_review_notification ON reviews;
CREATE TRIGGER trigger_review_notification
  AFTER INSERT ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION notify_review_submitted();


-- Trigger to notify provider when payment status changes
CREATE OR REPLACE FUNCTION notify_payment_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_client_name TEXT;
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- Only notify on payment_status changes (not on INSERT)
  IF TG_OP = 'UPDATE' AND (OLD.payment_status IS DISTINCT FROM NEW.payment_status) THEN
    -- Get provider's user_id from provider_profiles
    SELECT pp.user_id INTO v_provider_user_id
    FROM provider_profiles pp
    WHERE pp.id = NEW.provider_id;
    
    -- Get client name
    SELECT p.full_name INTO v_client_name
    FROM profiles p
    WHERE p.id = NEW.client_id;
    
    -- Build notification based on payment status
    CASE NEW.payment_status
      WHEN 'completed' THEN
        v_title := 'Payment Received';
        v_body := 'Payment of $' || NEW.total_amount || ' from ' || COALESCE(v_client_name, 'client') || ' has been completed';
      WHEN 'pending' THEN
        v_title := 'Payment Pending';
        v_body := 'Payment of $' || NEW.total_amount || ' from ' || COALESCE(v_client_name, 'client') || ' is being processed';
      WHEN 'failed' THEN
        v_title := 'Payment Failed';
        v_body := 'Payment of $' || NEW.total_amount || ' from ' || COALESCE(v_client_name, 'client') || ' has failed';
      WHEN 'refunded' THEN
        v_title := 'Payment Refunded';
        v_body := 'Payment of $' || NEW.total_amount || ' to ' || COALESCE(v_client_name, 'client') || ' has been refunded';
      ELSE
        RETURN NEW; -- Don't notify for other statuses
    END CASE;
    
    -- Send notification to provider
    IF v_provider_user_id IS NOT NULL THEN
      PERFORM send_fcm_notification(
        v_provider_user_id,
        v_title,
        v_body,
        'payment',
        jsonb_build_object(
          'booking_id', NEW.id,
          'payment_status', NEW.payment_status,
          'amount', NEW.total_amount
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for payment status changes
DROP TRIGGER IF EXISTS trigger_payment_notification ON bookings;
CREATE TRIGGER trigger_payment_notification
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_payment_status_change();
