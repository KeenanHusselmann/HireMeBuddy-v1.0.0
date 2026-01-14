-- Drop the old function first (parameter names changed)
DROP FUNCTION IF EXISTS create_review(uuid,uuid,uuid,integer,text);

-- Create a function to insert reviews that bypasses PostgREST schema cache issues
CREATE OR REPLACE FUNCTION create_review(
  input_booking_id UUID,
  input_provider_id UUID,
  input_client_id UUID,
  input_rating INTEGER,
  input_comment TEXT
)
RETURNS TABLE (
  review_id UUID,
  review_booking_id UUID,
  review_provider_id UUID,
  review_client_id UUID,
  review_rating INTEGER,
  review_comment TEXT,
  review_created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  INSERT INTO reviews (booking_id, provider_id, client_id, rating, comment)
  VALUES (input_booking_id, input_provider_id, input_client_id, input_rating, input_comment)
  ON CONFLICT (booking_id) 
  DO UPDATE SET
    rating = EXCLUDED.rating,
    comment = EXCLUDED.comment
  RETURNING 
    reviews.id, 
    reviews.booking_id, 
    reviews.provider_id, 
    reviews.client_id, 
    reviews.rating, 
    reviews.comment, 
    reviews.created_at;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_review TO authenticated;
