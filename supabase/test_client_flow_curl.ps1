$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$sr = (($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }) -split '=' | Select-Object -Last 1; $sr=$sr.Trim()
$surl = (($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_URL' }) -split '=' | Select-Object -Last 1; $surl=$surl.Trim()
if (-not $sr -or -not $surl) { Write-Output 'MISSING_CFG'; exit 2 }

$now = Get-Date -UFormat %s
$email = "test.user.$now+assistant@local.test"
$pw = "TestPass!$now"
Write-Output "Create user $email"
$createJson = @{ email=$email; password=$pw } | ConvertTo-Json
$create = & curl.exe -s -X POST "$($surl)/auth/v1/admin/users" -H "apikey: $sr" -H "Authorization: Bearer $sr" -H "Content-Type: application/json" -d $createJson -w "\nHTTP_STATUS:%{http_code}\n"
Write-Output "CREATE_RESULT:"; Write-Output $create

Write-Output 'Sign in to get token (curl)'
$tokenResp = & curl.exe -s -X POST "$($surl)/auth/v1/token?grant_type=password" -H "apikey: $sr" -H "Content-Type: application/x-www-form-urlencoded" -d "email=$email&password=$pw" -w "\nHTTP_STATUS:%{http_code}\n"
Write-Output 'TOKEN_RESULT:'; Write-Output $tokenResp

# extract access_token from JSON part (before HTTP_STATUS)
$parts = $tokenResp -split "\nHTTP_STATUS:" 
$body = $parts[0]
$status = $parts[1]
if ($status -notlike '200*') { Write-Output "SIGNIN_FAILED status=$status body=$body"; exit 2 }
try { $json = $body | ConvertFrom-Json; $access = $json.access_token } catch { Write-Output 'PARSE_ERR'; exit 2 }
Write-Output "ACCESS_OK len=$($access.Length)"

Write-Output 'Call enqueue_and_send (curl)'
$payload = @{ recipient_id='ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'; message_payload=@{ type='booking'; title='Client-test booking'; body='Booking from client flow test' } } | ConvertTo-Json -Depth 10
$call = & curl.exe -s -X POST "$($surl)/functions/v1/enqueue_and_send" -H "Authorization: Bearer $access" -H "Content-Type: application/json" -d $payload -w "\nHTTP_STATUS:%{http_code}\n"
Write-Output 'ENQUEUE_SEND_RESULT:'; Write-Output $call

# cleanup
Write-Output 'Deleting test user'
$created = (& echo $create) -split '\n' | Where-Object { $_ -ne '' } | ConvertFrom-Json
$uid = $created.id
if ($uid) { $del = & curl.exe -s -X DELETE "$($surl)/auth/v1/admin/users/$uid" -H "apikey: $sr" -H "Authorization: Bearer $sr" -w "\nHTTP_STATUS:%{http_code}\n"; Write-Output "DELETE_RESULT:"; Write-Output $del } else { Write-Output 'NO_UID_TO_DELETE' }
