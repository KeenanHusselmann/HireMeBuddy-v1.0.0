$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$line = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
if (-not $line) { Write-Output 'KEY_NOT_FOUND'; exit 2 }
$parts = $line -split '='
$sr = $parts[-1].Trim()
if (-not $sr) { Write-Output 'KEY_EMPTY'; exit 2 }
$headers = @{ 'apikey' = $sr; 'Authorization' = "Bearer $sr" }

try {
    $q = Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.supabase.co/rest/v1/notification_queue?select=*&order=created_at.desc&limit=10' -Headers $headers -Method Get
    Write-Output 'NOTIFICATION_ROWS:'
    $q | ConvertTo-Json -Depth 10
} catch {
    Write-Output "QUERY_ERR: $_"
}

try {
    $dt = Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.supabase.co/rest/v1/device_tokens?select=*&user_id=eq.ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b' -Headers $headers -Method Get
    Write-Output 'DEVICE_TOKENS:'
    $dt | ConvertTo-Json -Depth 10
} catch {
    Write-Output "TOKENS_ERR: $_"
}