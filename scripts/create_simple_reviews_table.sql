-- Create a completely new reviews table with NO foreign keys
-- This bypasses all PostgREST schema cache issues

-- Drop old reviews table and recreate fresh
DROP TABLE IF EXISTS reviews CASCADE;

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL,
  provider_id UUID NOT NULL,
  client_id UUID NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(booking_id)
);

-- Create indexes for performance
CREATE INDEX idx_reviews_provider ON reviews(provider_id);
CREATE INDEX idx_reviews_client ON reviews(client_id);
CREATE INDEX idx_reviews_booking ON reviews(booking_id);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Public can read all reviews
CREATE POLICY "reviews_select_policy" ON reviews
  FOR SELECT USING (true);

-- Clients can insert/update their own reviews
CREATE POLICY "reviews_insert_policy" ON reviews
  FOR INSERT 
  WITH CHECK (
    client_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "reviews_update_policy" ON reviews
  FOR UPDATE 
  USING (
    client_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  );

-- Simple insert function with no FK validation
DROP FUNCTION IF EXISTS submit_review(uuid,uuid,integer,text);

CREATE OR REPLACE FUNCTION submit_review(
  p_booking_id UUID,
  p_provider_id UUID,
  p_rating INTEGER,
  p_comment TEXT
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_client_id UUID;
  v_result json;
BEGIN
  -- Get client ID from auth
  SELECT id INTO v_client_id 
  FROM profiles 
  WHERE user_id = auth.uid();
  
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Simple INSERT with ON CONFLICT
  INSERT INTO reviews (booking_id, provider_id, client_id, rating, comment)
  VALUES (p_booking_id, p_provider_id, v_client_id, p_rating, p_comment)
  ON CONFLICT (booking_id) 
  DO UPDATE SET 
    rating = EXCLUDED.rating,
    comment = EXCLUDED.comment,
    updated_at = now()
  RETURNING row_to_json(reviews.*) INTO v_result;
  
  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION submit_review TO authenticated;

-- Function to get provider reviews with client details (no FK needed)
DROP FUNCTION IF EXISTS get_provider_reviews(uuid);

CREATE OR REPLACE FUNCTION get_provider_reviews(p_provider_id UUID)
RETURNS TABLE (
  id UUID,
  booking_id UUID,
  provider_id UUID,
  client_id UUID,
  rating INTEGER,
  comment TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  client_full_name TEXT,
  client_avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.booking_id,
    r.provider_id,
    r.client_id,
    r.rating,
    r.comment,
    r.created_at,
    r.updated_at,
    p.full_name as client_full_name,
    p.avatar_url as client_avatar_url
  FROM reviews r
  LEFT JOIN profiles p ON p.id = r.client_id
  WHERE r.provider_id = p_provider_id
  ORDER BY r.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_provider_reviews TO authenticated;
