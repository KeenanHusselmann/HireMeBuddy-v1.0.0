$saPath = 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\hiremebuddy-850a8-2d033e0c5ff3.json'
$bytes = [IO.File]::ReadAllBytes($saPath)
$b64 = [Convert]::ToBase64String($bytes)
Write-Output "Setting SERVICE_ACCOUNT_JSON secret (base64) for project vjpaolkqlumpyuxxmmvr"
& 'C:\tools\supabase.exe' secrets set SERVICE_ACCOUNT_JSON=$b64 --project-ref vjpaolkqlumpyuxxmmvr
Write-Output "Done."