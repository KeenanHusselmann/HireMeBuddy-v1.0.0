$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$line = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
if (-not $line) { Write-Output 'KEY_NOT_FOUND'; exit 2 }
$sr = ($line -split '=')[-1].Trim()
$supline = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_URL' }
$surl = ($supline -split '=')[-1].Trim()
if (-not $sr -or -not $surl) { Write-Output 'MISSING_CFG'; exit 2 }

# generate temp user
$now = Get-Date -UFormat %s
$email = "test.user.$now+assistant@local.test"
$pw = "TestPass!${now}"
Write-Output "Creating temp user: $email"

$createResp = Invoke-RestMethod -Uri "$surl/auth/v1/admin/users" -Method Post -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr"; 'Content-Type'='application/json' } -Body (ConvertTo-Json @{ email=$email; password=$pw }) -ErrorAction Stop
Write-Output "CREATE_OK: $($createResp.id)"

# sign in to get access token
Write-Output 'Signing in to obtain access token'
$tokenResp = Invoke-RestMethod -Uri "$surl/auth/v1/token?grant_type=password" -Method Post -Headers @{ 'apikey'=$sr; 'Content-Type'='application/x-www-form-urlencoded' } -Body ("email={0}&password={1}" -f [uri]::EscapeDataString($email), [uri]::EscapeDataString($pw)) -ErrorAction Stop
$access = $tokenResp.access_token
if (-not $access) { Write-Output "NO_ACCESS_TOKEN: $($tokenResp | ConvertTo-Json -Depth 5)"; exit 2 }
Write-Output "ACCESS_OK len=${access.Length}"

# call enqueue_and_send with the access token
Write-Output 'Calling enqueue_and_send'
$payload = @{ recipient_id = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'; message_payload = @{ type='booking'; title='Client-test booking'; body='Booking from client flow test' } }
$call = Invoke-RestMethod -Uri "$surl/functions/v1/enqueue_and_send" -Method Post -Headers @{ 'Authorization' = "Bearer $access"; 'Content-Type' = 'application/json' } -Body ($payload | ConvertTo-Json -Depth 10) -ErrorAction Stop
Write-Output 'ENQUEUE_SEND_RESPONSE:'
$call | ConvertTo-Json -Depth 10

# cleanup: delete the temp user (admin)
try {
    $del = Invoke-RestMethod -Uri "$surl/auth/v1/admin/users/$($createResp.id)" -Method Delete -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr" } -ErrorAction Stop
    Write-Output 'CLEANUP_OK'
} catch { Write-Output "CLEANUP_ERR: $_" }
