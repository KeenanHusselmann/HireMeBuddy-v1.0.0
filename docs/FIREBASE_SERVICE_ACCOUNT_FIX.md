# Firebase Service Account Fix Guide

## Problem
The Firebase service account key is returning "invalid_grant: account not found" when trying to authenticate with Google Cloud.

## Solution Steps

### 1. Go to Firebase Console
https://console.firebase.google.com/project/hiremebuddy-850a8/settings/serviceaccounts/adminsdk

### 2. Generate a NEW Service Account Key

1. Click "Generate New Private Key"
2. Click "Generate Key" to confirm
3. Save the JSON file as: `hiremebuddy-850a8-NEW.json`
4. Keep this file secure!

### 3. Update Supabase Secrets

Run this PowerShell script (in your project directory):

```powershell
# Read the NEW service account JSON
$serviceAccountPath = "C:\Users\keena\Projects\HireMeBuddy-v1.0.0\hiremebuddy-850a8-NEW.json"
$serviceAccountJson = Get-Content $serviceAccountPath -Raw
$serviceAccount = $serviceAccountJson | ConvertFrom-Json

# Base64 encode
$bytes = [System.Text.Encoding]::UTF8.GetBytes($serviceAccountJson)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "Setting new Firebase credentials..."
npx supabase secrets set --project-ref vjpaolkqlumpyuxxmmvr `
  SERVICE_ACCOUNT_JSON="$base64" `
  PROJECT_ID="$($serviceAccount.project_id)"

Write-Host "Redeploying Edge Functions..."
npx supabase functions deploy process_queue --project-ref vjpaolkqlumpyuxxmmvr
npx supabase functions deploy enqueue_and_send --project-ref vjpaolkqlumpyuxxmmvr
npx supabase functions deploy send_fcm --project-ref vjpaolkqlumpyuxxmmvr

Write-Host "✅ Done! Test notifications now."
```

### 4. Test the Fix

After updating, wait 1-2 minutes for functions to refresh, then send a test message in your app.

## Alternative: Check Current Service Account

If you want to verify the current service account is valid:

1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=hiremebuddy-850a8
2. Find the service account email in your current `hiremebuddy-850a8-2d033e0c5ff3.json`
3. Check if it's enabled and has the correct permissions:
   - Firebase Cloud Messaging API
   - Service Account Token Creator

## Why This Happened

The previous service account key rotation may have:
- Deleted the old service account entirely
- Created a key for a disabled service account
- Used a key from the wrong project
