# Firebase Credentials Setup Guide
**HireMeBuddy - Secure Configuration**

## ⚠️ Security Notice

**NEVER commit Firebase service account JSON files to git!** This guide shows you how to configure Firebase credentials securely using environment variables.

---

## 🔴 URGENT: If Credentials Were Exposed

If you've previously committed Firebase credentials to git, follow these steps immediately:

### 1. Rotate the Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **HireMeBuddy**
3. Navigate to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the new JSON file (keep it secure, DO NOT commit)
6. Delete the old key from Firebase Console

### 2. Clean Git History (If Needed)

If the credentials exist in git history, you need to remove them:

```bash
# Option 1: Using BFG Repo-Cleaner (Recommended)
# Download BFG from: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --delete-files hiremebuddy-*.json
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Option 2: Using git filter-branch (slower)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch hiremebuddy-850a8-2d033e0c5ff3.json" \
  --prune-empty --tag-name-filter cat -- --all
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

⚠️ **Warning:** This rewrites git history. Coordinate with your team before doing this.

### 3. Force Push (If History Rewritten)

```bash
git push origin --force --all
git push origin --force --tags
```

---

## 🔧 Secure Setup Instructions

### For Development (Local Machine)

#### 1. Store Firebase Credentials Securely

Create a secure directory outside your project:

```bash
# Windows
mkdir C:\Secure\HireMeBuddy
# Move the Firebase JSON file here
move hiremebuddy-*.json C:\Secure\HireMeBuddy\firebase-credentials.json
```

#### 2. Set Environment Variable

**Windows (PowerShell):**
```powershell
# Temporary (current session only)
$env:FIREBASE_CREDENTIALS_PATH = "C:\Secure\HireMeBuddy\firebase-credentials.json"

# Permanent (user level)
[System.Environment]::SetEnvironmentVariable('FIREBASE_CREDENTIALS_PATH', 'C:\Secure\HireMeBuddy\firebase-credentials.json', 'User')

# Verify
Get-ChildItem Env:FIREBASE_CREDENTIALS_PATH
```

**macOS/Linux:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export FIREBASE_CREDENTIALS_PATH="/secure/hiremebuddy/firebase-credentials.json"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

#### 3. Update Flutter Code (Already Configured)

The client-side Flutter app uses the standard Firebase initialization with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). These files should remain in the project as they contain public configuration only.

**✅ Safe to commit:**
- `android/app/google-services.json` (contains API keys only, not credentials)
- `ios/Runner/GoogleService-Info.plist`

**❌ Never commit:**
- Firebase service account JSON files (contain private keys)
- Any file with `private_key` in it

---

### For Supabase Edge Functions (Production)

#### 1. Get Your Service Account JSON

Download from Firebase Console:
1. Go to **Project Settings** → **Service Accounts**
2. Click **Generate New Private Key**
3. Save the JSON file securely

#### 2. Convert to Base64 (Recommended)

```bash
# Windows PowerShell
$content = Get-Content -Path "firebase-credentials.json" -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
$base64 = [Convert]::ToBase64String($bytes)
Write-Output $base64

# macOS/Linux
base64 -i firebase-credentials.json
```

#### 3. Set Supabase Secret

Using Supabase CLI:
```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Set the secret (use base64 string from step 2)
supabase secrets set SERVICE_ACCOUNT_JSON="<base64-encoded-json>"

# Verify
supabase secrets list
```

Using Supabase Dashboard:
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Project Settings** → **Edge Functions**
4. Scroll to **Secrets**
5. Add new secret:
   - Name: `SERVICE_ACCOUNT_JSON`
   - Value: Paste the base64-encoded JSON

#### 4. Optional: Set PROJECT_ID

If your service account JSON doesn't include `project_id`, set it separately:

```bash
supabase secrets set PROJECT_ID="hiremebuddy-850a8"
```

---

## 🧪 Testing the Configuration

### Test Edge Function Locally

1. Create `.env.local` in `supabase/` directory (this file is gitignored):

```bash
# supabase/.env.local
SERVICE_ACCOUNT_JSON=<base64-encoded-json-or-raw-json>
PROJECT_ID=hiremebuddy-850a8
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

2. Test the function:

```bash
cd supabase
supabase functions serve process_queue --env-file .env.local
```

3. Invoke the function:

```bash
curl -X POST http://localhost:54321/functions/v1/process_queue \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### Test in Production

Deploy the function:
```bash
supabase functions deploy process_queue
supabase functions deploy send_fcm
supabase functions deploy enqueue_and_send
```

Check logs:
```bash
supabase functions logs process_queue
```

---

## 🔍 Verification Checklist

- [ ] Firebase credentials removed from git repository
- [ ] `.gitignore` updated to exclude `hiremebuddy-*.json`
- [ ] New Firebase service account key generated (if exposed)
- [ ] Old service account key deleted from Firebase Console
- [ ] Git history cleaned (if credentials were in history)
- [ ] Environment variable `SERVICE_ACCOUNT_JSON` set in Supabase
- [ ] Edge Functions deployed and tested
- [ ] Local development uses secure credential path
- [ ] Team members notified of security incident (if applicable)

---

## 🚨 What NOT To Do

❌ **NEVER** commit files containing:
- `private_key`
- `service_account`
- Firebase Admin SDK credentials
- Any `.json` file with RSA keys

❌ **NEVER** hardcode credentials in:
- Source code files
- Configuration files tracked by git
- PowerShell/bash scripts in the repository
- README files or documentation

✅ **ALWAYS**:
- Use environment variables for secrets
- Store credentials outside the project directory
- Use `.gitignore` to exclude sensitive files
- Rotate keys immediately if exposed
- Use Supabase Secrets for Edge Functions

---

## 📞 If You Need Help

**Security Incident:**
If you believe credentials were exposed:
1. Rotate keys immediately (don't wait)
2. Review access logs in Firebase Console
3. Monitor for unusual activity
4. Contact team lead

**Setup Issues:**
If Edge Functions aren't receiving the credentials:
1. Check Supabase secrets: `supabase secrets list`
2. View function logs: `supabase functions logs process_queue`
3. Verify base64 encoding is correct
4. Ensure no extra whitespace in the secret value

---

## 🔐 Security Best Practices

1. **Principle of Least Privilege**
   - Only give service accounts the minimum permissions needed
   - Use Firebase Custom Tokens for client authentication
   - Never expose service account keys to clients

2. **Key Rotation Schedule**
   - Rotate service account keys every 90 days
   - Set calendar reminders
   - Document rotation procedure

3. **Access Monitoring**
   - Enable Firebase audit logs
   - Monitor service account usage
   - Set up alerts for unusual activity

4. **Team Education**
   - Review this guide with all developers
   - Add security check to PR review process
   - Use pre-commit hooks to prevent credential commits

---

## 📚 Additional Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/provisioning/configure-oauth)
- [Supabase Edge Functions Secrets](https://supabase.com/docs/guides/functions/secrets)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Git Filter-Branch Guide](https://git-scm.com/docs/git-filter-branch)

---

**Last Updated:** January 4, 2026  
**Version:** 1.0  
**Status:** Active Security Configuration
