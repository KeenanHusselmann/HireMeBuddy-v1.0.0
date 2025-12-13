-- Fix update_provider_rating function to use reviewed_id instead of provider_id

CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE provider_profiles
  SET rating_average = (
    SELECT COALESCE(AVG(rating), 0)
    FROM reviews
    WHERE reviewed_id = NEW.reviewed_id
  )
  WHERE id = NEW.reviewed_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
