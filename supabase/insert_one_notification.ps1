$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$line = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
if (-not $line) { Write-Output 'KEY_NOT_FOUND'; exit 2 }
$parts = $line -split '='
$sr = $parts[-1].Trim()
if (-not $sr) { Write-Output 'KEY_EMPTY'; exit 2 }
$headers = @{ 'apikey' = $sr; 'Authorization' = "Bearer $sr"; 'Content-Type' = 'application/json' }
$body = @{
    recipient_id = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'
    message_payload = @{
        type = 'booking'
        title = 'Quick test booking'
        body = 'This is a quick test booking notification.'
    }
    processed = $false
}
try {
    $resp = Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.supabase.co/rest/v1/notification_queue' -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
    Write-Output 'INSERT_OK'
    $resp | ConvertTo-Json -Depth 10
} catch {
    Write-Output "INSERT_ERR: $_"
}
