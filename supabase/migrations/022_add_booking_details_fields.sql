-- Add new fields to bookings table for enhanced client booking details
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS job_location TEXT,
ADD COLUMN IF NOT EXISTS job_instructions TEXT,
ADD COLUMN IF NOT EXISTS client_budget DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS secondary_contact TEXT;

-- Add comment for documentation
COMMENT ON COLUMN bookings.job_location IS 'Location/address where the job will be performed';
COMMENT ON COLUMN bookings.job_instructions IS 'Detailed instructions from client about the job';
COMMENT ON COLUMN bookings.client_budget IS 'Client specified budget for the job';
COMMENT ON COLUMN bookings.secondary_contact IS 'Secondary contact number provided by client';
