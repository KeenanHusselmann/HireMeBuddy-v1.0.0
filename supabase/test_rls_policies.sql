# RLS Policy Quick Test Script
# Run this in Supabase SQL Editor to verify RLS policies

-- =====================================================
-- 1. VERIFY RLS IS ENABLED
-- =====================================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Expected: All tables should have rls_enabled = true

-- =====================================================
-- 2. LIST ALL RLS POLICIES
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL THEN 'USING clause present'
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'WITH CHECK clause present'
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected: Should show all policies for each table

-- =====================================================
-- 3. CHECK TABLES WITHOUT RLS POLICIES
-- =====================================================

SELECT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND p.policyname IS NULL
GROUP BY t.tablename;

-- Expected: Should return empty (all tables should have policies)

-- =====================================================
-- 4. COUNT POLICIES PER TABLE
-- =====================================================

SELECT 
    tablename,
    COUNT(*) as policy_count,
    STRING_AGG(DISTINCT cmd::text, ', ') as operations_covered
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected: Each table should have multiple policies

-- =====================================================
-- 5. DETAILED POLICY ANALYSIS
-- =====================================================

-- Check profiles table policies
SELECT 
    policyname,
    cmd as operation,
    roles,
    SUBSTRING(qual::text, 1, 100) as using_clause_preview
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY cmd, policyname;

-- Check provider_profiles policies
SELECT 
    policyname,
    cmd as operation,
    roles,
    SUBSTRING(qual::text, 1, 100) as using_clause_preview
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'provider_profiles'
ORDER BY cmd, policyname;

-- Check bookings policies
SELECT 
    policyname,
    cmd as operation,
    roles,
    SUBSTRING(qual::text, 1, 100) as using_clause_preview
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'bookings'
ORDER BY cmd, policyname;

-- Check messages policies
SELECT 
    policyname,
    cmd as operation,
    roles,
    SUBSTRING(qual::text, 1, 100) as using_clause_preview
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'messages'
ORDER BY cmd, policyname;

-- =====================================================
-- 6. TEST RLS WITH MOCK USER (DO NOT RUN IN PRODUCTION!)
-- =====================================================

-- WARNING: Only run in development/test environment
-- This simulates a user session for testing

-- Step 1: Get a real user ID from your database
-- SELECT id FROM profiles LIMIT 1;

-- Step 2: Set local session to act as that user (replace USER_ID)
-- SET LOCAL ROLE authenticated;
-- SET LOCAL request.jwt.claims TO '{"sub": "USER_ID_HERE", "role": "authenticated"}';

-- Step 3: Try to access data
-- SELECT * FROM profiles WHERE id != 'USER_ID_HERE';
-- Expected: Should only see public data or error

-- Step 4: Try to update another user's data
-- UPDATE profiles SET full_name = 'Test Hack' WHERE id != 'USER_ID_HERE';
-- Expected: Should affect 0 rows or fail

-- Step 5: Reset to normal
-- RESET ROLE;

-- =====================================================
-- 7. VERIFY STORAGE BUCKET POLICIES
-- =====================================================

SELECT 
    name as bucket_name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
ORDER BY name;

-- Check storage policies
SELECT 
    bucket_id,
    name as policy_name,
    definition
FROM storage.policies
ORDER BY bucket_id, name;

-- =====================================================
-- 8. CHECK FOR SECURITY GAPS
-- =====================================================

-- Tables with RLS enabled but no INSERT policy
SELECT DISTINCT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND p.cmd = 'INSERT'
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND p.policyname IS NULL
  AND t.tablename NOT IN ('service_categories', 'admin_actions')  -- Exclude admin-only tables
ORDER BY t.tablename;

-- Tables with RLS enabled but no SELECT policy
SELECT DISTINCT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND p.cmd = 'SELECT'
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND p.policyname IS NULL
ORDER BY t.tablename;

-- =====================================================
-- 9. SUMMARY REPORT
-- =====================================================

WITH rls_status AS (
    SELECT 
        t.tablename,
        t.rowsecurity as rls_enabled,
        COUNT(DISTINCT p.policyname) as policy_count,
        BOOL_OR(p.cmd = 'SELECT') as has_select,
        BOOL_OR(p.cmd = 'INSERT') as has_insert,
        BOOL_OR(p.cmd = 'UPDATE') as has_update,
        BOOL_OR(p.cmd = 'DELETE') as has_delete
    FROM pg_tables t
    LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
    WHERE t.schemaname = 'public'
    GROUP BY t.tablename, t.rowsecurity
)
SELECT 
    tablename,
    rls_enabled,
    policy_count,
    has_select,
    has_insert,
    has_update,
    has_delete,
    CASE 
        WHEN NOT rls_enabled THEN '🔴 RLS NOT ENABLED'
        WHEN policy_count = 0 THEN '🔴 NO POLICIES'
        WHEN NOT has_select THEN '🟡 MISSING SELECT POLICY'
        ELSE '✅ OK'
    END as status
FROM rls_status
ORDER BY 
    CASE 
        WHEN NOT rls_enabled THEN 1
        WHEN policy_count = 0 THEN 2
        WHEN NOT has_select THEN 3
        ELSE 4
    END,
    tablename;

-- =====================================================
-- RESULTS INTERPRETATION
-- =====================================================

/*
✅ Green (OK): Table has RLS enabled and basic policies
🟡 Yellow (Warning): Table may be missing some policy types
🔴 Red (Critical): RLS not enabled or no policies exist

NEXT STEPS:
1. Review any RED or YELLOW items
2. Add missing policies if needed
3. Test with actual user sessions
4. Monitor for "permission denied" errors in app
5. Document any intentional security restrictions
*/
