Supabase Notifications — deployment and testing

Overview
- Deploys two Supabase Edge Functions:
  - `process_queue` — polls `notification_queue`, sends FCM, marks processed
  - `send_fcm` — direct send helper (optional)

Prerequisites
- `supabase` CLI installed and logged in (`supabase login`).
- A Google service account JSON with `firebase.messaging` scope (create in GCP IAM)
- Your Supabase `SERVICE_ROLE` key (Project Settings -> API)

Steps (PowerShell)

1. Base64 encode service account JSON and set secrets
```powershell
# $PROJECT_REF = 'your-project-ref'
# $SA_PATH = 'C:\path\to\service-account.json'
# $SERVICE_ROLE = 'your-supabase-service-role-key'
# $SUPABASE_URL = 'https://xxxxx.supabase.co'
# $PROJECT_ID = 'your-gcp-project-id' # optional

# $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($SA_PATH))
# supabase secrets set SERVICE_ACCOUNT_JSON="$b64" SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE" SUPABASE_URL="$SUPABASE_URL" PROJECT_ID="$PROJECT_ID" --project-ref $PROJECT_REF
```

2. Deploy functions
```powershell
# supabase functions deploy send_fcm --project-ref $PROJECT_REF
# supabase functions deploy process_queue --project-ref $PROJECT_REF
```

3. Test by inserting a row into `notification_queue` and invoking processor
```powershell
# Example curl to insert (use SERVICE_ROLE key)
# curl -X POST "$SUPABASE_URL/rest/v1/notification_queue" -H "apikey: $SERVICE_ROLE" -H "Authorization: Bearer $SERVICE_ROLE" -H "Content-Type: application/json" -d "{ \"recipient_id\": \"<recipient-uuid>\", \"message_payload\": { \"notification\": { \"title\": \"Test\", \"body\": \"Hello from processor\" } } }"
# Invoke processor
# supabase functions invoke process_queue --project-ref $PROJECT_REF
```

Notes
- Keep your `SERVICE_ROLE` secret private. The functions use it to read `device_tokens` and `notification_queue`.
- Alternatively, enable a DB trigger to insert into `notification_queue` on new messages.
