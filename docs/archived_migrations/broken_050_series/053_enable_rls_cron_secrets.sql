-- =====================================================
-- Migration: Enable RLS on cron_secrets table
-- Fixes security error: RLS disabled in public schema
-- =====================================================

-- Enable RLS on cron_secrets table
ALTER TABLE cron_secrets ENABLE ROW LEVEL SECURITY;

-- No policies needed - cron_secrets should only be accessible by service role
-- This effectively blocks all public access while allowing service role access
-- (Service role bypasses RLS)

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- This migration has:
-- ✅ Enabled RLS on cron_secrets table
-- ✅ Blocked public access to sensitive cron secrets
-- ✅ Maintained service role access for cron jobs
-- 
-- Expected result: 0 security errors
