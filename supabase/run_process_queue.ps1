$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$line = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
if (-not $line) { Write-Output 'KEY_NOT_FOUND'; exit 2 }
$parts = $line -split '='
$sr = $parts[-1].Trim()
if (-not $sr) { Write-Output 'KEY_EMPTY'; exit 2 }
$headers = @{ 'Authorization' = "Bearer $sr"; 'Content-Type' = 'application/json' }

try {
    $resp = Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.functions.supabase.co/process_queue' -Method Post -Headers $headers -Body '{}' -ErrorAction Stop
    Write-Output 'PROCESS_OK'
    $resp | ConvertTo-Json -Depth 10
} catch {
    Write-Output "PROCESS_ERR: $_"
}
