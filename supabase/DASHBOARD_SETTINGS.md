# Supabase Dashboard Security Settings

These settings must be configured in your Supabase dashboard, not via SQL.

## 1. Fix OTP Expiry (WARN)
**Location:** Authentication → Email Auth → Settings

1. Go to Supabase Dashboard → Authentication → Email
2. Find "OTP Expiry" setting
3. Change from current value to **3600 seconds (1 hour)** or less
4. Recommended: **1800 seconds (30 minutes)**
5. Click Save

## 2. Enable Leaked Password Protection (WARN)
**Location:** Authentication → Policies → Password Security

1. Go to Supabase Dashboard → Authentication → Policies
2. Find "Password Security" section
3. Enable "**Leaked Password Protection**"
   - This checks passwords against HaveIBeenPwned.org database
4. Click Save

## 3. Upgrade PostgreSQL Version (WARN - Low Priority)
**Location:** Database → Settings → General

This requires downtime and testing:
1. Go to Supabase Dashboard → Database → Settings
2. Check for available PostgreSQL upgrades
3. Schedule upgrade during low-traffic period
4. Test application after upgrade

**Note:** Current version: `supabase-postgres-17.4.1.054`

---

## Summary
- ✅ **Fix function search_path**: Run `fix_function_security.sql` 
- ⚙️ **OTP expiry**: Set to ≤3600 seconds in dashboard
- ⚙️ **Leaked passwords**: Enable in dashboard
- 📅 **PostgreSQL**: Schedule upgrade when convenient
