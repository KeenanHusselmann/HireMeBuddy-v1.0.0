-- Test query to debug the provider listing issue
-- This should be run in Supabase SQL editor to check the data

-- First, let's see what's in the provider_profiles table
SELECT 
  pp.id,
  pp.bio,
  pp.is_verified,
  pp.is_available,
  pp.hourly_rate,
  pp.created_at,
  p.full_name,
  p.email,
  p.phone,
  p.role
FROM provider_profiles pp
LEFT JOIN profiles p ON pp.id = p.id
ORDER BY pp.created_at DESC;

-- Check if there are any provider_profiles without matching profiles
SELECT COUNT(*) as orphaned_provider_profiles
FROM provider_profiles pp
LEFT JOIN profiles p ON pp.id = p.id
WHERE p.id IS NULL;

-- Check if there are any profiles with provider role but no provider_profile
SELECT COUNT(*) as profiles_without_provider_profile
FROM profiles p
LEFT JOIN provider_profiles pp ON p.id = pp.id
WHERE p.role = 'provider' AND pp.id IS NULL;