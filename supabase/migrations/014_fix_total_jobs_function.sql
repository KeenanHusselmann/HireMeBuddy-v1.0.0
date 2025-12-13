-- Fix the update_provider_total_jobs function to use correct column name
-- The column is 'total_jobs' not 'completed_jobs_count'

DROP FUNCTION IF EXISTS update_provider_total_jobs() CASCADE;

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
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_update_provider_total_jobs ON bookings;

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
