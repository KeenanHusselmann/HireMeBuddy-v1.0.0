$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$srLine = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
$surlLine = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_URL' }
if (-not $srLine -or -not $surlLine) { Write-Output 'MISSING_CFG'; exit 2 }
$sr = ($srLine -split '=')[-1].Trim()
$surl = ($surlLine -split '=')[-1].Trim()
if (-not $sr -or -not $surl) { Write-Output 'MISSING_CFG2'; exit 2 }

$now = [int][double]::Parse((Get-Date -UFormat %s))
$email = "tmp.user.$now+assistant@local.test"
$pw = "TmpPass!${now}"
Write-Output "Creating temp user: $email"
try {
    $createResp = Invoke-RestMethod -Uri "$surl/auth/v1/admin/users" -Method Post -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr"; 'Content-Type'='application/json' } -Body (@{ email=$email; password=$pw } | ConvertTo-Json -Depth 3)
    Write-Output "CREATE_OK: $($createResp.id)"
} catch {
    Write-Output "CREATE_ERR: $_"
    exit 2
}

# Sign in to get access token (form-encoded)
try {
    $tokenResp = $null
    try {
        # Try JSON sign-in body (some Supabase setups expect JSON)
        $signinBody = @{ grant_type = 'password'; email = $email; password = $pw } | ConvertTo-Json -Depth 5
        $tokenResp = Invoke-RestMethod -Uri "$surl/auth/v1/token" -Method Post -Headers @{ 'apikey'=$sr; 'Content-Type'='application/json' } -Body $signinBody -ErrorAction Stop
        $access = $tokenResp.access_token
        if (-not $access) { Write-Output "NO_ACCESS_TOKEN: $($tokenResp | ConvertTo-Json -Depth 5)"; throw 'no token' }
        Write-Output "ACCESS_OK len=${($access.Length)}"
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($resp -ne $null) {
            $srdr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $body = $srdr.ReadToEnd()
            Write-Output "SIGNIN_HTTP_ERR_BODY: $body"
        }
        throw $_
    }
} catch {
    Write-Output "SIGNIN_ERR: $_"
    # cleanup user
    try { Invoke-RestMethod -Uri "$surl/auth/v1/admin/users/$($createResp.id)" -Method Delete -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr" } } catch {}
    exit 2
}

# Call enqueue_and_send
try {
    $payload = @{ recipient_id = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'; message_payload = @{ type='booking'; title='Client booking test'; body='Client-triggered booking' } } | ConvertTo-Json -Depth 10
    $call = Invoke-RestMethod -Uri "$surl/functions/v1/enqueue_and_send" -Method Post -Headers @{ 'Authorization' = "Bearer $access"; 'Content-Type' = 'application/json' } -Body $payload -ErrorAction Stop
    Write-Output 'ENQUEUE_SEND_RESPONSE:'
    $call | ConvertTo-Json -Depth 10
} catch {
    Write-Output "ENQUEUE_ERR: $_"
}

# cleanup
try {
    Invoke-RestMethod -Uri "$surl/auth/v1/admin/users/$($createResp.id)" -Method Delete -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr" }
    Write-Output 'CLEANUP_OK'
} catch {
    Write-Output "CLEANUP_ERR: $_"
}
