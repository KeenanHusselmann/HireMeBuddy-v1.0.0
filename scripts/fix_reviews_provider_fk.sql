-- Fix reviews.provider_id foreign key to point to profiles instead of provider_profiles
-- The initial migration incorrectly referenced provider_profiles table

-- 1. Drop the old foreign key constraint
ALTER TABLE reviews 
DROP CONSTRAINT IF EXISTS reviews_reviewed_id_fkey;

ALTER TABLE reviews 
DROP CONSTRAINT IF EXISTS reviews_provider_id_fkey;

-- 2. Add the correct foreign key constraint pointing to profiles
ALTER TABLE reviews 
ADD CONSTRAINT reviews_provider_id_fkey 
FOREIGN KEY (provider_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;

-- 3. Verify the fix
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'reviews';
