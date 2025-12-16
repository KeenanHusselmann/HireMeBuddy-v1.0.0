$sr = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $sr -or $sr.Length -lt 20) {
    Write-Output 'ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable is not set or too short. Set it and re-run the script.'
    exit 2
}
$headers = @{ 'apikey' = $sr; 'Authorization' = "Bearer $sr"; 'Content-Type' = 'application/json' }
$body1 = @{
    recipient_id = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'
    message_payload = @{
        type = 'booking'
        title = 'New booking'
        body = 'Booking created by Alice'
    }
    processed = $false
}
$body2 = @{
    recipient_id = 'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'
    message_payload = @{
        type = 'message'
        title = 'New message'
        body = 'Hello from Bob'
    }
    processed = $false
}

try {
    Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.supabase.co/rest/v1/notification_queue' -Method Post -Headers $headers -Body ($body1 | ConvertTo-Json -Depth 10)
    Write-Output 'INSERT1_OK'
} catch {
    Write-Output "INSERT1_ERR: $_"
}

try {
    Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.supabase.co/rest/v1/notification_queue' -Method Post -Headers $headers -Body ($body2 | ConvertTo-Json -Depth 10)
    Write-Output 'INSERT2_OK'
} catch {
    Write-Output "INSERT2_ERR: $_"
}

try {
    $proc = Invoke-RestMethod -Uri 'https://vjpaolkqlumpyuxxmmvr.functions.supabase.co/process_queue' -Method Post -ContentType 'application/json' -Body '{}'
    Write-Output 'PROCESS_RESPONSE:'
    $proc | ConvertTo-Json -Depth 10
} catch {
    Write-Output "PROCESS_ERR: $_"
}
