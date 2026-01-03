# Row Level Security (RLS) Testing Guide

**Date:** January 3, 2026  
**Project:** HireMeBuddy v1.0.0  
**Purpose:** Verify all RLS policies are working correctly

---

## 🎯 Overview

This document outlines the testing procedures for verifying Row Level Security (RLS) policies in the HireMeBuddy Supabase database. **RLS is CRITICAL** for data security - it ensures users can only access data they're authorized to see.

---

## ⚠️ Critical Security Note

**NEVER use the service role key in client applications!**
- ✅ Service role key: Server-side only (Edge Functions, admin scripts)
- ✅ Anon key: Client applications (bypasses nothing, enforces RLS)
- ❌ Service role in client: **Bypasses ALL RLS policies** (security breach)

---

## 📋 Tables to Test

### 1. **profiles** table
- ✅ Users can read their own profile
- ✅ Users can update their own profile
- ✅ Users cannot modify other users' profiles
- ✅ Public data (name, avatar) readable by all authenticated users
- ✅ Private data (email, phone) only readable by owner

### 2. **provider_profiles** table
- ✅ Anyone can read approved/active provider profiles
- ✅ Only the provider can update their own profile
- ✅ Only admins can approve/verify providers
- ✅ Unapproved profiles not visible to clients

### 3. **bookings** table
- ✅ Clients can only see their own bookings
- ✅ Providers can only see bookings assigned to them
- ✅ Clients can create bookings
- ✅ Providers can update booking status
- ✅ Users cannot delete bookings (only cancel)
- ✅ Cannot modify other users' bookings

### 4. **messages** table
- ✅ Users can only see messages they sent or received
- ✅ Users can only create messages as themselves
- ✅ Cannot read other users' conversations
- ✅ Real-time subscriptions respect RLS

### 5. **reviews** table
- ✅ Anyone can read reviews
- ✅ Only clients who completed a booking can leave reviews
- ✅ One review per booking
- ✅ Cannot edit others' reviews
- ✅ Cannot delete reviews (admin only)

### 6. **notifications** table
- ✅ Users can only read their own notifications
- ✅ Users can mark their notifications as read
- ✅ Cannot access other users' notifications

### 7. **payments** table
- ✅ Users can only see their own payment records
- ✅ Strict read-only for users
- ✅ Only system/admin can create payments

### 8. **service_categories** table
- ✅ Read-only for all users
- ✅ Only admins can modify

### 9. **provider_services** table
- ✅ Anyone can read active services
- ✅ Providers can manage their own services
- ✅ Cannot modify other providers' services

### 10. **portfolio_images** table
- ✅ Anyone can view portfolio images
- ✅ Providers can manage their own portfolio
- ✅ Cannot delete others' portfolio items

### 11. **notification_queue** table (Backend-Only)
- ✅ No user access (system-only table)
- ✅ All operations return empty/fail for users
- ✅ Service role can access for background processing
- ✅ Users should use 'notifications' table instead

### 12. **device_tokens** table
- ✅ Users can only see their own device tokens
- ✅ Users can register their own device tokens
- ✅ Users can update/delete their own tokens
- ✅ Cannot access other users' device tokens

---

## 🧪 Testing Methods

### Method 1: Supabase Dashboard SQL Editor
```sql
-- Test as a specific user (set user context)
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "USER_UUID_HERE"}';

-- Try to access data
SELECT * FROM profiles WHERE id != 'USER_UUID_HERE';
-- Should return empty if RLS is working

-- Try to update another user's data
UPDATE profiles SET full_name = 'Hacked' WHERE id != 'USER_UUID_HERE';
-- Should fail or affect 0 rows
```

### Method 2: Client App Testing
1. **Create two test accounts:**
   - Test Client 1: `client1@test.com`
   - Test Client 2: `client2@test.com`
   - Test Provider: `provider@test.com`

2. **Test scenarios:**
   ```
   ✓ Login as client1@test.com
   ✓ Try to view client2's profile/bookings
   ✓ Try to modify client2's data
   ✓ Verify you can only see YOUR data
   
   ✓ Login as provider@test.com
   ✓ Verify you see only YOUR bookings
   ✓ Verify you can't see client bookings
   ```

### Method 3: API Testing with curl
```bash
# Get anon key and URL from .env
SUPABASE_URL="https://vjpaolkqlumpyuxxmmvr.supabase.co"
ANON_KEY="your-anon-key-here"

# Test 1: Try to read all profiles (should be filtered by RLS)
curl -X GET "$SUPABASE_URL/rest/v1/profiles" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer USER_JWT_TOKEN"

# Test 2: Try to update another user's profile (should fail)
curl -X PATCH "$SUPABASE_URL/rest/v1/profiles?id=eq.OTHER_USER_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer USER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"full_name": "Hacked"}'
```

---

## ✅ RLS Policies Checklist

### profiles Table
- [ ] Policy: Users can SELECT their own profile
- [ ] Policy: Users can UPDATE their own profile
- [ ] Policy: Public fields visible to all authenticated
- [ ] Policy: No DELETE allowed (soft delete only)

### provider_profiles Table
- [ ] Policy: SELECT for approved providers (public)
- [ ] Policy: Providers can UPDATE their own profile
- [ ] Policy: Admins can UPDATE any provider
- [ ] Policy: No DELETE by users

### bookings Table
- [ ] Policy: Clients SELECT their bookings (client_id = auth.uid())
- [ ] Policy: Providers SELECT their bookings (provider_id = auth.uid())
- [ ] Policy: Clients INSERT bookings
- [ ] Policy: Providers UPDATE booking status
- [ ] Policy: Clients UPDATE to cancel only

### messages Table
- [ ] Policy: SELECT where sender = auth.uid() OR receiver = auth.uid()
- [ ] Policy: INSERT where sender = auth.uid()
- [ ] Policy: No UPDATE (messages are immutable)
- [ ] Policy: No DELETE

### reviews Table
- [ ] Policy: SELECT all (public)
- [ ] Policy: INSERT by booking client only
- [ ] Policy: UPDATE own reviews within 24h
- [ ] Policy: No DELETE

### notifications Table
- [ ] Policy: SELECT where user_id = auth.uid()
- [ ] Policy: UPDATE where user_id = auth.uid() (mark as read)
- [ ] Policy: System INSERT only

---

## 🚨 Common RLS Issues

### Issue 1: "permission denied for table"
**Cause:** RLS enabled but no policies exist  
**Fix:** Create appropriate SELECT/INSERT/UPDATE policies

### Issue 2: "new row violates row-level security policy"
**Cause:** INSERT policy doesn't match data being inserted  
**Fix:** Ensure INSERT policy allows the operation

### Issue 3: Real-time not working
**Cause:** Real-time doesn't respect RLS by default  
**Fix:** Add REPLICA IDENTITY and ensure policies are correct

### Issue 4: Can see all data
**Cause:** Using service role key instead of anon key  
**Fix:** **USE ANON KEY IN CLIENT!** Service key bypasses RLS

---

## 📊 Test Results Template

```markdown
## RLS Test Results - [Date]

### Tester: [Name]

#### Test Environment:
- Database: Supabase (vjpaolkqlumpyuxxmmvr)
- Test User 1: client1@test.com
- Test User 2: client2@test.com
- Test Provider: provider@test.com

#### Results:

**profiles Table:**
- ✅ Can read own profile
- ✅ Cannot read others' private data
- ✅ Cannot modify others' profiles
- ❌ Issue found: [describe]

**provider_profiles Table:**
- ✅ Can read approved providers
- ✅ Cannot modify others' provider profiles
- ❌ Issue found: [describe]

**bookings Table:**
- [ ] Client sees only their bookings
- [ ] Provider sees only their bookings
- [ ] Cannot modify others' bookings

... [continue for all tables]

#### Critical Issues:
1. [Issue description]
2. [Issue description]

#### Recommendations:
1. [Recommendation]
2. [Recommendation]
```

---

## 🔧 Quick RLS Fix Commands

### Enable RLS on a table:
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

### Create basic SELECT policy:
```sql
CREATE POLICY "Users can read their own data"
ON table_name
FOR SELECT
USING (user_id = auth.uid());
```

### Create UPDATE policy:
```sql
CREATE POLICY "Users can update their own data"
ON table_name
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

### View existing policies:
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Drop a policy:
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

---

## 📝 Next Steps

1. **Execute Tests:** Run through all test scenarios above
2. **Document Results:** Fill in the test results template
3. **Fix Issues:** Address any RLS policy gaps found
4. **Re-test:** Verify fixes work correctly
5. **Monitor:** Set up logging to catch RLS violations in production

---

## 🔗 Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- Project RLS Policies: `supabase/migrations/002_rls_policies.sql`

---

**Status:** ⏳ Testing Required  
**Priority:** 🔴 HIGH - Security Critical  
**Assigned To:** Development Team
