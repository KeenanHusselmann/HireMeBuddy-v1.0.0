-- Fix provider_services constraints to use correct column name
-- The previous migration incorrectly used category_id instead of service_category_id

-- Drop the old constraint if it exists
ALTER TABLE provider_services
DROP CONSTRAINT IF EXISTS unique_provider_service;

-- Drop the old index if it exists
DROP INDEX IF EXISTS idx_provider_services_category_id;

-- Remove any existing duplicates (keep the most recent one)
DELETE FROM provider_services a
USING provider_services b
WHERE a.id < b.id
  AND a.provider_id = b.provider_id
  AND a.service_category_id = b.service_category_id;

-- Add correct unique constraint
ALTER TABLE provider_services
ADD CONSTRAINT unique_provider_service 
UNIQUE (provider_id, service_category_id);

-- Add correct index for better query performance
CREATE INDEX IF NOT EXISTS idx_provider_services_category_id 
ON provider_services(service_category_id);
