$saPath = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\hiremebuddy-850a8-2d033e0c5ff3.json'
$bytes = [IO.File]::ReadAllBytes($saPath)
$b64 = [Convert]::ToBase64String($bytes)
$envFile = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath '.env'
$lines = @(
    "SERVICE_ACCOUNT_JSON=$b64",
    "SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9zZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0",
    "PROJECT_ID=hiremebuddy-850a8",
    "SUPABASE_URL=https://vjpaolkqlumpyuxxmmvr.supabase.co"
)
Set-Content -Path $envFile -Value ($lines -join "`n") -Encoding ASCII
Write-Output "Wrote env file to $envFile"

# Serve functions (requires Docker)
& 'C:\tools\supabase.exe' functions serve --workdir (Split-Path -Parent $MyInvocation.MyCommand.Definition) --env-file $envFile --debug
