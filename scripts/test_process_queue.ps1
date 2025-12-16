param(
  [string]$SupabaseUrl = '',
  [string]$ServiceRoleKey = '',
  [string]$RecipientId = ''
)

if (-not $SupabaseUrl -or -not $ServiceRoleKey -or -not $RecipientId) {
  Write-Host 'Usage: .\test_process_queue.ps1 -SupabaseUrl <url> -ServiceRoleKey <key> -RecipientId <uuid>'
  exit 1
}

$payload = @{ recipient_id = $RecipientId; message_payload = @{ notification = @{ title = 'Test from processor'; body = 'Hello from process_queue' } } } | ConvertTo-Json -Depth 6

Write-Host 'Inserting test notification_queue row...'
$resp = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/notification_queue" -Method Post -Headers @{ apikey = $ServiceRoleKey; Authorization = "Bearer $ServiceRoleKey" } -ContentType 'application/json' -Body $payload
Write-Host 'Inserted. Now invoke process_queue (via supabase CLI) or call the function endpoint.'
Write-Host 'If you have supabase CLI configured:'
Write-Host '  supabase functions invoke process_queue --project-ref YOUR_PROJECT_REF'
