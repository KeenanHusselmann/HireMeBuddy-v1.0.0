-- Add total_reviews column to provider_profiles if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'provider_profiles' 
    AND column_name = 'total_reviews'
  ) THEN
    ALTER TABLE provider_profiles 
    ADD COLUMN total_reviews INTEGER DEFAULT 0;
  END IF;
END $$;

-- Update the function to also update review count
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE provider_profiles
  SET 
    rating_average = (
      SELECT COALESCE(AVG(rating), 0)
      FROM reviews
      WHERE reviewed_id = NEW.reviewed_id
    ),
    total_reviews = (
      SELECT COUNT(*)
      FROM reviews
      WHERE reviewed_id = NEW.reviewed_id
    )
  WHERE id = NEW.reviewed_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS update_rating_on_review ON reviews;
CREATE TRIGGER update_rating_on_review AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_provider_rating();

-- Initialize total_reviews for existing providers
UPDATE provider_profiles pp
SET total_reviews = (
  SELECT COUNT(*)
  FROM reviews r
  WHERE r.reviewed_id = pp.id
);
