-- Nuclear option: Completely bypass PostgREST schema cache with raw SQL execution
-- This function uses EXECUTE to avoid any schema validation at function creation time
-- Gets client_id automatically from auth.uid() to avoid any PostgREST queries

-- Drop both old signatures
DROP FUNCTION IF EXISTS create_review_raw(uuid,uuid,uuid,integer,text);
DROP FUNCTION IF EXISTS create_review_raw(uuid,uuid,integer,text);

CREATE OR REPLACE FUNCTION create_review_raw(
  p_booking_id UUID,
  p_provider_id UUID,
  p_rating INTEGER,
  p_comment TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
  v_client_id UUID;
BEGIN
  -- Get client profile ID from authenticated user (bypass PostgREST)
  SELECT id INTO v_client_id FROM profiles WHERE user_id = auth.uid();
  
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Client profile not found for user';
  END IF;
  
  -- Use EXECUTE to avoid schema validation at function creation
  EXECUTE format(
    'INSERT INTO reviews (booking_id, provider_id, client_id, rating, comment) 
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (booking_id) 
     DO UPDATE SET rating = EXCLUDED.rating, comment = EXCLUDED.comment
     RETURNING row_to_json(reviews.*)'
  ) 
  USING p_booking_id, p_provider_id, v_client_id, p_rating, p_comment
  INTO v_result;
  
  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION create_review_raw TO authenticated;
