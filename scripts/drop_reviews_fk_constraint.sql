-- Drop the foreign key constraint on reviews.provider_id
-- PostgREST's schema cache is stuck trying to validate this FK to provider_profiles
-- We'll keep the column but remove the constraint to bypass the cache issue

-- First, find the constraint name
SELECT conname 
FROM pg_constraint 
WHERE conrelid = 'reviews'::regclass 
  AND contype = 'f' 
  AND conkey @> ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid = 'reviews'::regclass AND attname = 'provider_id')];

-- Drop the constraint (use the name from above, usually something like reviews_provider_id_fkey)
-- Replace 'reviews_provider_id_fkey' with actual name if different
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_provider_id_fkey;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_provider_fkey;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS fk_reviews_provider;

-- Verify it's gone
SELECT conname 
FROM pg_constraint 
WHERE conrelid = 'reviews'::regclass 
  AND contype = 'f';
