$envFile = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env'
$lines = Get-Content -Raw $envFile -ErrorAction Stop -Encoding UTF8
$map = @{}
foreach ($line in ($lines -split "\r?\n")) {
    if (-not ($line -and $line -match '=')) { continue }
    $idx = $line.IndexOf('=')
    $k = $line.Substring(0,$idx).Trim()
    $v = $line.Substring($idx+1).Trim()
    $map[$k] = $v
}
if (-not $map.ContainsKey('SUPABASE_SERVICE_ROLE_KEY') -or -not $map.ContainsKey('SUPABASE_URL')) { Write-Output 'MISSING_ENV_KEYS'; exit 2 }
$sr = $map['SUPABASE_SERVICE_ROLE_KEY']
$surl = $map['SUPABASE_URL']
$uri = "$surl/rest/v1/notification_queue"
Write-Output "GET $uri"
try {
    $r = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ 'apikey'=$sr; 'Authorization'="Bearer $sr" } -ErrorAction Stop
    $r | ConvertTo-Json -Depth 10
} catch {
    Write-Output "ERR: $_"
}
