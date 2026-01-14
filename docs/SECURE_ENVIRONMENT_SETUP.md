# Secure Environment Setup Guide - HireMeBuddy

**Created:** January 4, 2026  
**Purpose:** Secure credential management and environment variable setup

---

## 🔐 CRITICAL: DO NOT COMMIT CREDENTIALS

All sensitive credentials have been removed from the codebase. Follow this guide to set up your environment securely.

---

## 📋 Required Environment Variables

### 1. Firebase Service Account Path

**Windows PowerShell:**
```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH = "C:\Secure\HireMeBuddy\hiremebuddy-850a8-firebase-adminsdk-fbsvc-c8920a9f90.json"
```

**Make Permanent (Windows):**
```powershell
[System.Environment]::SetEnvironmentVariable('FIREBASE_SERVICE_ACCOUNT_PATH', 'C:\Secure\HireMeBuddy\hiremebuddy-850a8-firebase-adminsdk-fbsvc-c8920a9f90.json', 'User')
```

### 2. Supabase Service Role Key (for scripts only)

**Windows PowerShell:**
```powershell
$env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key-here"
```

**Make Permanent (Windows):**
```powershell
[System.Environment]::SetEnvironmentVariable('SUPABASE_SERVICE_ROLE_KEY', 'your-service-role-key-here', 'User')
```

**Where to get it:**
- Supabase Dashboard → Settings → API → service_role key (secret)

⚠️ **NEVER commit this key to git!**

---

## 🛡️ Secure File Storage

### Firebase Service Account Files

**Current Location:** `C:\Secure\HireMeBuddy\`

**Files:**
- ✅ `hiremebuddy-850a8-firebase-adminsdk-fbsvc-c8920a9f90.json` (ACTIVE KEY - Jan 2026)
- ❌ `hiremebuddy-850a8-firebase-adminsdk-fbsvc-1215285e3e.json` (OLD - DELETED)

**Security Rules:**
1. Store in secure directory OUTSIDE project folder
2. Set restrictive file permissions (owner read-only)
3. Never copy to project directory
4. Backup securely (encrypted cloud storage)

### Windows File Permissions (Optional but Recommended)

```powershell
# Remove inherited permissions and grant only to current user
$path = "C:\Secure\HireMeBuddy"
$acl = Get-Acl $path
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
$acl.SetAccessRule($rule)
Set-Acl $path $acl
```

---

## 🚀 Using the Scripts

### Manual Process Queue

```powershell
# Set environment variable first
$env:SUPABASE_SERVICE_ROLE_KEY = "your-key"

# Run script
.\scripts\manual_process_queue.ps1
```

### Deploy FCM Functions

```powershell
# Set environment variables
$env:FIREBASE_SERVICE_ACCOUNT_PATH = "C:\Secure\HireMeBuddy\your-service-account.json"

# Run deployment
.\scripts\deploy_fcm_functions.ps1
```

### Test FCM Notifications

```powershell
# Set environment variable
$env:FIREBASE_SERVICE_ACCOUNT_PATH = "C:\Secure\HireMeBuddy\your-service-account.json"

# Run test script
.\scripts\test_fcm_notifications.ps1
```

**OR Node.js version:**

```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH = "C:\Secure\HireMeBuddy\your-service-account.json"
cd scripts
node test_fcm_notifications.js
```

---

## ☁️ Supabase Edge Functions

### Environment Variables (Auto-Provided)

These are **automatically available** in Edge Functions:
- ✅ `SUPABASE_URL`
- ✅ `SUPABASE_SERVICE_ROLE_KEY`
- ✅ `SUPABASE_ANON_KEY`

**You do NOT need to set these manually!**

### Custom Secrets (Manual Setup Required)

Set these in Supabase Dashboard or CLI:

```powershell
# SERVICE_ACCOUNT_JSON (base64 encoded)
$json = Get-Content "C:\Secure\HireMeBuddy\hiremebuddy-850a8-firebase-adminsdk-fbsvc-c8920a9f90.json" -Raw
$json = $json.Replace("`r`n", "`n").Trim()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$base64 = [Convert]::ToBase64String($bytes)

npx supabase secrets set SERVICE_ACCOUNT_JSON=$base64 --project-ref vjpaolkqlumpyuxxmmvr
```

### Verify Secrets

```powershell
npx supabase secrets list --project-ref vjpaolkqlumpyuxxmmvr
```

Expected output:
```
   NAME                      | DIGEST
   ------------------------- | ----------------------------------------------------------------
   SERVICE_ACCOUNT_JSON      | a315bfcbba3595075d197f31342acd99f4dae8f14d41ced22a71ea7b4723167f
```

---

## 🗄️ Database Secrets (Cron Job)

The `process_queue` function is called by a cron job that needs the service_role_key stored in the database.

### Check Current Value

```sql
SELECT name, LEFT(secret, 20) || '...' as secret_preview
FROM public.cron_secrets
WHERE name = 'service_role_key';
```

### Update if Needed

```sql
-- Replace 'YOUR_SERVICE_ROLE_KEY' with actual key from Supabase Dashboard
UPDATE public.cron_secrets
SET secret = 'YOUR_SERVICE_ROLE_KEY'
WHERE name = 'service_role_key';
```

**Verify:**
```sql
SELECT get_service_role_key() IS NOT NULL AS key_set;
```

---

## ✅ Security Checklist

### Before Committing Code

- [ ] No `.json` files with "firebase" or "service-account" in name
- [ ] No hardcoded JWT tokens in scripts
- [ ] No absolute paths to secure directories
- [ ] `.gitignore` up to date
- [ ] Environment variables used instead of hardcoded values

### Before Deployment

- [ ] Firebase service account in secure location
- [ ] `SERVICE_ACCOUNT_JSON` secret set in Supabase
- [ ] `cron_secrets` table has valid service_role_key
- [ ] All Edge Functions deployed with latest code
- [ ] Test notification flow end-to-end

### Regular Maintenance

- [ ] Rotate Firebase service account keys every 90 days
- [ ] Review Supabase access logs for suspicious activity
- [ ] Update `.gitignore` when adding new credential types
- [ ] Audit scripts for hardcoded values quarterly

---

## 🆘 Emergency: Key Compromised

If you suspect a credential has been compromised:

### 1. Revoke Immediately

**Supabase Service Role Key:**
1. Dashboard → Settings → API → "Reset service_role key"
2. Update all references (cron_secrets, environment variables)

**Firebase Service Account:**
1. Firebase Console → Project Settings → Service Accounts
2. Delete compromised key
3. Generate new key
4. Update `SERVICE_ACCOUNT_JSON` secret in Supabase
5. Redeploy all Edge Functions

### 2. Audit Access

- Check Supabase logs for unauthorized access
- Review Firebase usage for suspicious activity
- Check git history for accidental commits

### 3. Update Systems

- Update environment variables on all development machines
- Update CI/CD pipeline secrets
- Notify team members

---

## 📞 Quick Reference

| What | Where | Format |
|------|-------|--------|
| Firebase Service Account | `C:\Secure\HireMeBuddy\` | JSON file |
| Supabase Service Role Key | Environment variable | JWT string |
| SERVICE_ACCOUNT_JSON | Supabase Secrets | Base64 encoded JSON |
| Cron service_role_key | Database `cron_secrets` | JWT string |

---

## 🎯 Testing Your Setup

### 1. Test Environment Variables

```powershell
# Should output path
echo $env:FIREBASE_SERVICE_ACCOUNT_PATH

# Should output key (partial)
echo $env:SUPABASE_SERVICE_ROLE_KEY.Substring(0, 20)
```

### 2. Test Firebase Access

```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH = "C:\Secure\HireMeBuddy\hiremebuddy-850a8-firebase-adminsdk-fbsvc-c8920a9f90.json"
.\scripts\test_fcm_notifications.ps1
```

### 3. Test Edge Functions

```powershell
# Should return ok: true, processed: 0 (or number of notifications)
Invoke-RestMethod -Uri "https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue" -Method Post -Headers @{"Authorization"="Bearer $env:SUPABASE_SERVICE_ROLE_KEY"}
```

---

**Last Updated:** January 4, 2026  
**Maintainer:** Development Team  
**Classification:** Internal - Sensitive
