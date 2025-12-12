-- Update provider_services table to add missing columns
-- The table needs description, base_price, and is_available columns

-- Add description column if it doesn't exist
ALTER TABLE provider_services
ADD COLUMN IF NOT EXISTS description TEXT;

-- Add base_price column if it doesn't exist
ALTER TABLE provider_services
ADD COLUMN IF NOT EXISTS base_price DECIMAL(10, 2);

-- Add is_available column if it doesn't exist
ALTER TABLE provider_services
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true;

-- Drop custom_rate column if you're not using it (optional)
-- ALTER TABLE provider_services DROP COLUMN IF EXISTS custom_rate;
