$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
$lines = Get-Content -Raw $envFile
$map = @{}
foreach ($line in ($lines -split "\r?\n")) {
    if (-not ($line -and $line -match '=')) { continue }
    $idx = $line.IndexOf('=')
    $k = $line.Substring(0,$idx).Trim()
    $v = $line.Substring($idx+1).Trim()
    $map[$k] = $v
}
$sr = $map['SUPABASE_SERVICE_ROLE_KEY']
$surl = $map['SUPABASE_URL']
$recipient='ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'
$payload = @{ recipient_id = $recipient; message_payload = @{ type='booking'; title='Client booking (httpclient)'; body = 'Test' } }
$json = $payload | ConvertTo-Json -Depth 10

$client = New-Object System.Net.Http.HttpClient
$req = New-Object System.Net.Http.StringContent($json,[System.Text.Encoding]::UTF8,'application/json')
$req.Headers.Add('apikey',$sr)
$req.Headers.Add('Authorization',"Bearer $sr")
$uri = "$surl/rest/v1/notification_queue"
Write-Output "POST $uri"
$res = $client.PostAsync($uri,$req).Result
Write-Output "Status: $($res.StatusCode)"
$body = $res.Content.ReadAsStringAsync().Result
Write-Output "Body: $body"
