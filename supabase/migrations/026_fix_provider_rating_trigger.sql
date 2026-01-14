-- Fix the provider rating update trigger to use correct column name
-- The reviews table uses 'provider_id', not 'reviewed_id'

-- Drop existing trigger
DROP TRIGGER IF EXISTS update_rating_on_review ON reviews;

-- Recreate the function with correct column names
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
DECLARE
  target_provider_id UUID;
BEGIN
  -- Determine which provider to update based on the operation
  IF (TG_OP = 'DELETE') THEN
    target_provider_id := OLD.provider_id;
  ELSE
    target_provider_id := NEW.provider_id;
  END IF;

  -- Update the provider's rating and review count
  UPDATE provider_profiles
  SET 
    rating_average = (
      SELECT COALESCE(AVG(rating), 0)
      FROM reviews
      WHERE provider_id = target_provider_id
    ),
    total_reviews = (
      SELECT COUNT(*)
      FROM reviews
      WHERE provider_id = target_provider_id
    )
  WHERE id = target_provider_id;
  
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT, UPDATE, and DELETE operations
CREATE TRIGGER update_rating_on_review 
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_provider_rating();

-- Drop existing submit_review function if it exists (to change return type)
DROP FUNCTION IF EXISTS submit_review(UUID, UUID, INTEGER, TEXT);

-- Create the submit_review function used by the app
CREATE OR REPLACE FUNCTION submit_review(
  p_booking_id UUID,
  p_provider_id UUID,
  p_rating INTEGER,
  p_comment TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  booking_id UUID,
  client_id UUID,
  provider_id UUID,
  rating INTEGER,
  comment TEXT,
  created_at TIMESTAMPTZ
) AS $$
DECLARE
  v_client_id UUID;
  v_review_id UUID;
BEGIN
  -- Get the client_id from the booking
  SELECT client_id INTO v_client_id
  FROM bookings
  WHERE bookings.id = p_booking_id;

  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  -- Insert the review
  INSERT INTO reviews (booking_id, client_id, provider_id, rating, comment)
  VALUES (p_booking_id, v_client_id, p_provider_id, p_rating, p_comment)
  RETURNING reviews.id INTO v_review_id;

  -- Return the newly created review
  RETURN QUERY
  SELECT 
    r.id,
    r.booking_id,
    r.client_id,
    r.provider_id,
    r.rating,
    r.comment,
    r.created_at
  FROM reviews r
  WHERE r.id = v_review_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recalculate all provider ratings and review counts from existing reviews
UPDATE provider_profiles pp
SET 
  rating_average = (
    SELECT COALESCE(AVG(rating), 0)
    FROM reviews r
    WHERE r.provider_id = pp.id
  ),
  total_reviews = (
    SELECT COUNT(*)
    FROM reviews r
    WHERE r.provider_id = pp.id
  );
