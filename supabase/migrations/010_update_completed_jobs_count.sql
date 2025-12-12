-- Migration to automatically update completed jobs count for providers

-- Function to update provider's total_jobs count
CREATE OR REPLACE FUNCTION update_provider_total_jobs()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total_jobs for the provider when a booking is marked as completed
  IF (TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed') OR
     (TG_OP = 'INSERT' AND NEW.status = 'completed') THEN
    
    UPDATE provider_profiles
    SET total_jobs = (
      SELECT COUNT(*)
      FROM bookings
      WHERE provider_id = NEW.provider_id
        AND status = 'completed'
    )
    WHERE id = NEW.provider_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_update_provider_total_jobs ON bookings;

-- Create trigger on bookings table
CREATE TRIGGER trigger_update_provider_total_jobs
  AFTER INSERT OR UPDATE OF status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_provider_total_jobs();

-- Update all existing providers' total_jobs count based on completed bookings
UPDATE provider_profiles pp
SET total_jobs = (
  SELECT COUNT(*)
  FROM bookings b
  WHERE b.provider_id = pp.id
    AND b.status = 'completed'
);

-- Log the update
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM provider_profiles
  WHERE total_jobs > 0;
  
  RAISE NOTICE 'Updated % providers with completed jobs count', updated_count;
END $$;
