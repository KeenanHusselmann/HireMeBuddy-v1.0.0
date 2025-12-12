-- Add unique constraint to prevent duplicate provider services
-- This ensures a provider can't add the same service category twice

-- First, remove any existing duplicates (keep the most recent one)
DELETE FROM provider_services a
USING provider_services b
WHERE a.id < b.id
  AND a.provider_id = b.provider_id
  AND a.service_category_id = b.service_category_id;

-- Add unique constraint
ALTER TABLE provider_services
ADD CONSTRAINT unique_provider_service 
UNIQUE (provider_id, service_category_id);

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_provider_services_provider_id 
ON provider_services(provider_id);

CREATE INDEX IF NOT EXISTS idx_provider_services_category_id 
ON provider_services(service_category_id);

-- Add check constraint to ensure base_price is positive
ALTER TABLE provider_services
ADD CONSTRAINT check_base_price_positive 
CHECK (base_price > 0);

-- Add default value for is_available if not set
ALTER TABLE provider_services
ALTER COLUMN is_available SET DEFAULT true;
