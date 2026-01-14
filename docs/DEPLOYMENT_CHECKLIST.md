# ✅ Migration Deployment Checklist

## Pre-Deployment

### 1. Backup Database
- [ ] Go to Supabase Dashboard → Settings → Database → Backups
- [ ] Click "Create Backup"
- [ ] Wait for backup to complete
- [ ] Note backup ID: `____________________`
- [ ] Download backup locally (optional): `____________________`

### 2. Review Migration
- [ ] Read `050_optimize_rls_performance.sql`
- [ ] Understand what will change
- [ ] Review `OPTIMIZATION_SUMMARY.md`
- [ ] Review `BEFORE_AFTER_COMPARISON.md`

### 3. Prepare Environment
- [ ] Choose deployment time: `____________________`
- [ ] Inform team members (if applicable)
- [ ] Have rollback plan ready
- [ ] Keep Supabase Dashboard open
- [ ] Keep app logs visible

---

## Deployment

### 4. Apply Migration
- [ ] Open Supabase Dashboard
- [ ] Navigate to SQL Editor
- [ ] Click "New Query"
- [ ] Open `050_optimize_rls_performance.sql`
- [ ] Copy entire file content
- [ ] Paste into SQL Editor
- [ ] Click "Run" (or Ctrl+Enter)
- [ ] Wait for completion (~10-15 seconds)
- [ ] Verify "Success" message appears
- [ ] Check for any error messages
- [ ] Screenshot results (optional)

**Deployment Time:** `____________________`

### 5. Immediate Verification
- [ ] No red error messages in SQL Editor
- [ ] Query executed successfully
- [ ] No warnings in Supabase logs

---

## Post-Deployment Testing

### 6. Database Verification
Run these queries to verify changes:

```sql
-- Check policy count (should be ~40-50, was ~150)
SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public';
-- Result: __________

-- Check policies per table
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY policy_count DESC;
```

- [ ] Policy count significantly reduced
- [ ] No table has >10 policies
- [ ] All tables have at least 1 policy

### 7. Test User Authentication

#### Client Login
- [ ] Open client app
- [ ] Login with test client account
- [ ] Login succeeds
- [ ] Home page loads
- [ ] No error messages

#### Provider Login
- [ ] Open provider app
- [ ] Login with test provider account
- [ ] Login succeeds
- [ ] Dashboard loads
- [ ] No error messages

#### Admin Login
- [ ] Open admin app
- [ ] Login with test admin account
- [ ] Login succeeds
- [ ] Admin panel loads
- [ ] No error messages

### 8. Test Core Features

#### Client Features
- [ ] View provider profiles
- [ ] Create new booking
- [ ] View own bookings
- [ ] Send message
- [ ] View notifications
- [ ] Update profile

#### Provider Features
- [ ] View provider profile
- [ ] Update provider profile
- [ ] View assigned bookings
- [ ] Update booking status
- [ ] View notifications
- [ ] View messages

#### Admin Features
- [ ] View all users
- [ ] View all bookings
- [ ] View all providers
- [ ] Manage service categories
- [ ] View analytics (if applicable)

### 9. Performance Checks
- [ ] App feels faster (subjective)
- [ ] No noticeable slowdowns
- [ ] Queries complete quickly
- [ ] No timeout errors

### 10. Error Monitoring

Check Supabase Dashboard → Logs:
- [ ] No "permission denied" errors
- [ ] No RLS policy errors
- [ ] No unusual errors
- [ ] API response times normal

Check App Logs:
- [ ] No Supabase errors
- [ ] No authentication errors
- [ ] No data fetching errors

---

## Verification Queries

### Run These in SQL Editor

#### 1. Check Auth Function Usage
```sql
-- Verify auth.uid() is wrapped in SELECT
SELECT 
  tablename,
  policyname,
  CASE 
    WHEN qual::text LIKE '%(SELECT auth.uid())%' THEN '✅ Optimized'
    WHEN qual::text LIKE '%auth.uid()%' THEN '❌ Not Optimized'
    ELSE '➖ No auth check'
  END as optimization_status
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```
- [ ] Most policies show "✅ Optimized"

#### 2. Check for Duplicate Policies
```sql
-- No table should have multiple policies with same command
SELECT 
  tablename,
  cmd,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, cmd
HAVING COUNT(*) > 5
ORDER BY policy_count DESC;
```
- [ ] No results (or very few)

#### 3. Check Index Status
```sql
-- Verify duplicate index removed
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'provider_services';
```
- [ ] Only one unique index on (provider_id, service_category_id)
- [ ] No "unique_provider_service" index

#### 4. Performance Test
```sql
-- Test query performance
EXPLAIN ANALYZE 
SELECT * FROM bookings 
WHERE client_id = (SELECT auth.uid())
LIMIT 100;
```
- [ ] Planning time < 20ms
- [ ] Execution time reasonable
- [ ] No full table scan (if data exists)

---

## Linter Verification

### 11. Run Supabase Linter
- [ ] Go to Database → Database Linter
- [ ] Click "Run Linter"
- [ ] Wait for results
- [ ] Check warnings count

**Expected Results:**
- Auth RLS InitPlan: 0 warnings (was 21)
- Multiple Permissive Policies: 0 warnings (was 149)
- Duplicate Index: 0 warnings (was 1)
- **Total: 0-5 warnings** (was 171)

**Actual Results:** `__________ warnings`

If warnings remain:
- [ ] Review remaining warnings
- [ ] Determine if critical
- [ ] Document for follow-up

---

## Production Readiness

### 12. Monitor Production (if applicable)
For 24-48 hours after deployment:

#### Hour 1
- [ ] Check error logs
- [ ] Monitor API response times
- [ ] Check user reports
- [ ] No issues detected

#### Hour 6
- [ ] Check error logs again
- [ ] Monitor active users
- [ ] Check for patterns
- [ ] No issues detected

#### Hour 24
- [ ] Review daily error summary
- [ ] Check performance metrics
- [ ] Verify no degradation
- [ ] No issues detected

#### Hour 48
- [ ] Final review
- [ ] Mark migration as successful
- [ ] Update documentation

---

## Rollback (If Needed)

### 13. Rollback Procedure
Only if critical issues occur:

- [ ] Stop new deployments
- [ ] Document issues encountered
- [ ] Go to Settings → Database → Backups
- [ ] Select backup from step 1
- [ ] Click "Restore"
- [ ] Wait for restore to complete
- [ ] Test app functionality
- [ ] Notify team
- [ ] Plan corrective action

**Rollback Time:** `____________________`  
**Reason:** `____________________`

---

## Final Sign-Off

### 14. Deployment Success
- [ ] All tests passed
- [ ] No critical errors
- [ ] Performance improved
- [ ] Users not impacted
- [ ] Linter warnings fixed
- [ ] Documentation updated

### 15. Update Documentation
- [ ] Update CHANGELOG.md (if exists)
- [ ] Note migration applied date
- [ ] Update project README (if needed)
- [ ] Inform team of success

**Migration Applied By:** `____________________`  
**Date/Time:** `____________________`  
**Status:** ✅ Success / ❌ Rolled Back / ⏸️ Pending

---

## Metrics to Track

### Before Migration (Baseline)
- Linter Warnings: 171
- Policy Count: ~150
- Average Query Time: `__________ ms`
- Database CPU: `__________ %`
- Error Rate: `__________ /day`

### After Migration (Results)
- Linter Warnings: `__________`
- Policy Count: `__________`
- Average Query Time: `__________ ms`
- Database CPU: `__________ %`
- Error Rate: `__________ /day`

### Improvement
- Warnings Reduced: `__________ %`
- Policies Reduced: `__________ %`
- Query Time Improved: `__________ %`
- CPU Reduced: `__________ %`

---

## Notes / Issues

Use this space to document any issues or observations:

```
____________________________________________________________________
____________________________________________________________________
____________________________________________________________________
____________________________________________________________________
____________________________________________________________________
```

---

## Contact Information

**Deployed By:** `____________________`  
**Email:** `____________________`  
**Phone:** `____________________`  
**Date:** `____________________`

---

## Summary

✅ **Deployment Status:** _________________  
✅ **All Tests Passed:** Yes / No  
✅ **Performance Improved:** Yes / No  
✅ **Would Recommend:** Yes / No  

**Overall Grade:** A+ / A / B / C / D / F

---

*Checklist Version: 1.0*  
*Migration: 050_optimize_rls_performance.sql*  
*Last Updated: January 4, 2026*
