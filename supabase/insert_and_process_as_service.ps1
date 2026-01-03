$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
if (-not (Test-Path $envFile)) { Write-Output "ENV_FILE_NOT_FOUND: $envFile"; exit 2 }
$envText = Get-Content -Raw $envFile
$srLine = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_ROLE_KEY' }
$surlLine = ($envText -split "\r?\n") | Where-Object { $_ -match '^\s*SUPABASE_URL' }
if (-not $srLine -or -not $surlLine) { Write-Output 'MISSING_CFG'; exit 2 }
$sr = ($srLine -split '=')[-1].Trim()
$surl = ($surlLine -split '=')[-1].Trim()
if (-not $sr -or -not $surl) { Write-Output 'MISSING_CFG2'; exit 2 }

 $recipient = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'
 $payload = @{ recipient_id = $recipient; message_payload = @{ type='booking'; title='Client booking (server-inserted)'; body = 'Booking created — server queued test' } }
$json = @($payload) | ConvertTo-Json -Depth 10
Write-Output "JSON_PAYLOAD: $json"
Write-Output "Inserting notification for recipient $recipient"
try {
    try {
        $ins = Invoke-RestMethod -Uri "$surl/rest/v1/notification_queue" -Method Post -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr"; 'Content-Type'='application/json'; 'Prefer'='return=representation' } -Body $json -ErrorAction Stop
        Write-Output "INSERT_OK: $($ins | ConvertTo-Json -Depth 5)"
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($resp -ne $null) {
            $srdr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $body = $srdr.ReadToEnd()
            Write-Output "INSERT_HTTP_ERR_BODY: $body"
        }
        throw $_
    }
} catch {
    Write-Output "INSERT_ERR: $_"
    exit 2
}

# Call process_queue
try {
    Write-Output "Calling process_queue"
    $proc = Invoke-RestMethod -Uri "$surl/functions/v1/process_queue" -Method Post -Headers @{ 'Authorization' = "Bearer $sr"; 'apikey' = $sr } -ErrorAction Stop
    Write-Output "PROCESS_OK: $($proc | ConvertTo-Json -Depth 10)"
} catch {
    Write-Output "PROCESS_ERR: $_"
    exit 2
}
