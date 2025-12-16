param(
  [string]$ProjectRef = '',
  [string]$ServiceAccountPath = '',
  [string]$ServiceRoleKey = '',
  [string]$SupabaseUrl = ''
)

if (-not $ProjectRef) { Write-Host 'Set $ProjectRef (supabase project ref)'; exit 1 }
if (-not $ServiceAccountPath) { Write-Host 'Set $ServiceAccountPath (path to service-account.json)'; exit 1 }
if (-not $ServiceRoleKey) { Write-Host 'Set $ServiceRoleKey'; exit 1 }
if (-not $SupabaseUrl) { Write-Host 'Set $SupabaseUrl'; exit 1 }

[Console]::WriteLine('Encoding service account JSON and setting secrets...')
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ServiceAccountPath))
supabase secrets set SERVICE_ACCOUNT_JSON="$b64" SUPABASE_SERVICE_ROLE_KEY="$ServiceRoleKey" SUPABASE_URL="$SupabaseUrl" PROJECT_ID="" --project-ref $ProjectRef

[Console]::WriteLine('Deploying functions...')
supabase functions deploy send_fcm --project-ref $ProjectRef
supabase functions deploy process_queue --project-ref $ProjectRef

[Console]::WriteLine('Deployment finished. Invoke process_queue to test.')
