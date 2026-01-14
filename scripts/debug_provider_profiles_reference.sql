-- Check for any views, triggers, or functions that might reference provider_profiles
-- This will help identify what's causing the error

-- 1. Check for views that reference reviews
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE definition ILIKE '%provider_profiles%'
   OR definition ILIKE '%reviews%';

-- 2. Check for triggers on reviews table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'reviews';

-- 3. Check for functions that reference provider_profiles
SELECT 
    n.nspname as schema,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prokind = 'f'
  AND pg_get_functiondef(p.oid) ILIKE '%provider_profiles%';

-- 4. Check actual table structure of reviews
SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'reviews'
ORDER BY ordinal_position;

-- 5. Check if provider_profiles table actually exists
SELECT EXISTS (
    SELECT FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename = 'provider_profiles'
) as provider_profiles_exists;
