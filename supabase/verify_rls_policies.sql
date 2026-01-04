-- =====================================================
-- RLS VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to verify all RLS policies are enabled
-- =====================================================

-- 1. CHECK IF RLS IS ENABLED ON ALL CRITICAL TABLES
-- =====================================================
SELECT 
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles',
    'provider_profiles',
    'service_categories',
    'provider_services',
    'bookings',
    'reviews',
    'messages',
    'notifications',
    'payments',
    'admin_actions'
  )
ORDER BY tablename;

-- Expected: ALL tables should have rls_enabled = true
-- If any show false, run: ALTER TABLE tablename ENABLE ROW LEVEL SECURITY;

-- 2. LIST ALL RLS POLICIES WITH DETAILS
-- =====================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd AS command,
  qual AS using_expression,
  with_check AS with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected: Should see policies for all tables listed above

-- 3. COUNT POLICIES PER TABLE
-- =====================================================
SELECT 
  tablename,
  COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected policy counts:
-- profiles: 3 policies
-- provider_profiles: 4 policies
-- service_categories: 2 policies
-- provider_services: 2 policies
-- bookings: 5 policies
-- reviews: 3 policies
-- messages: 3 policies
-- notifications: 3 policies
-- payments: 3 policies
-- admin_actions: 2 policies

-- 4. CHECK FOR TABLES WITHOUT RLS ENABLED
-- =====================================================
SELECT 
  schemaname,
  tablename,
  'WARNING: RLS NOT ENABLED' AS status
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND tablename NOT IN ('schema_migrations', 'device_tokens', 'notification_queue', 'waiting_list')
ORDER BY tablename;

-- Expected: Should return no rows (all tables should have RLS)

-- 5. VERIFY ADMIN ROLE ACCESS
-- =====================================================
-- Test query to check if admin role check works
SELECT EXISTS (
  SELECT 1 FROM profiles
  WHERE role = 'admin'
) AS admin_exists;

-- Expected: true if admin user exists

-- 6. CHECK FOR ORPHANED POLICIES (policies without matching tables)
-- =====================================================
SELECT 
  policyname,
  tablename,
  'Orphaned Policy - Table May Not Exist' AS warning
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename NOT IN (
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  );

-- Expected: Should return no rows

-- 7. DETAILED POLICY BREAKDOWN BY TABLE
-- =====================================================

-- PROFILES
SELECT 'PROFILES' AS table_name, COUNT(*) AS policies FROM pg_policies WHERE tablename = 'profiles'
UNION ALL
-- PROVIDER_PROFILES
SELECT 'PROVIDER_PROFILES', COUNT(*) FROM pg_policies WHERE tablename = 'provider_profiles'
UNION ALL
-- SERVICE_CATEGORIES
SELECT 'SERVICE_CATEGORIES', COUNT(*) FROM pg_policies WHERE tablename = 'service_categories'
UNION ALL
-- PROVIDER_SERVICES
SELECT 'PROVIDER_SERVICES', COUNT(*) FROM pg_policies WHERE tablename = 'provider_services'
UNION ALL
-- BOOKINGS
SELECT 'BOOKINGS', COUNT(*) FROM pg_policies WHERE tablename = 'bookings'
UNION ALL
-- REVIEWS
SELECT 'REVIEWS', COUNT(*) FROM pg_policies WHERE tablename = 'reviews'
UNION ALL
-- MESSAGES
SELECT 'MESSAGES', COUNT(*) FROM pg_policies WHERE tablename = 'messages'
UNION ALL
-- NOTIFICATIONS
SELECT 'NOTIFICATIONS', COUNT(*) FROM pg_policies WHERE tablename = 'notifications'
UNION ALL
-- PAYMENTS
SELECT 'PAYMENTS', COUNT(*) FROM pg_policies WHERE tablename = 'payments'
UNION ALL
-- ADMIN_ACTIONS
SELECT 'ADMIN_ACTIONS', COUNT(*) FROM pg_policies WHERE tablename = 'admin_actions';

-- =====================================================
-- REMEDIATION SCRIPTS (Run if RLS not enabled)
-- =====================================================

-- Uncomment and run these if any tables are missing RLS:

-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE provider_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE provider_services ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STORAGE BUCKET RLS VERIFICATION
-- =====================================================

-- Check storage buckets have proper RLS
SELECT 
  id,
  name,
  public,
  owner
FROM storage.buckets;

-- Expected buckets:
-- - profile-images (private)
-- - service-images (public)
-- - verification-documents (private)

-- =====================================================
-- END OF VERIFICATION
-- =====================================================

-- Summary: Run all queries above and verify:
-- 1. All critical tables have RLS enabled (rls_enabled = true)
-- 2. Each table has appropriate number of policies
-- 3. No orphaned policies exist
-- 4. Admin user exists in profiles table
-- 5. Storage buckets are configured correctly
