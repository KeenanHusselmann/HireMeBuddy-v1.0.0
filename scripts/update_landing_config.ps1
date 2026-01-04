# Update Landing Page Supabase Config
# This script copies Supabase credentials from .env to landing page script.js

$envPath = "C:\Users\keena\Projects\HireMeBuddy-v1.0.0\.env"
$scriptPath = "C:\Users\keena\Projects\HireMeBuddy-v1.0.0\web\landing\script.js"

# Check if .env exists
if (-not (Test-Path $envPath)) {
    Write-Host "Error: .env file not found at $envPath" -ForegroundColor Red
    Write-Host "Please create .env file with SUPABASE_URL and SUPABASE_ANON_KEY" -ForegroundColor Yellow
    exit 1
}

# Read .env file
$envContent = Get-Content $envPath -Raw

# Extract Supabase URL
if ($envContent -match 'SUPABASE_URL\s*=\s*(.+)') {
    $supabaseUrl = $matches[1].Trim().Trim('"').Trim("'")
    Write-Host "Found SUPABASE_URL: $supabaseUrl" -ForegroundColor Green
} else {
    Write-Host "Error: SUPABASE_URL not found in .env" -ForegroundColor Red
    exit 1
}

# Extract Supabase Anon Key
if ($envContent -match 'SUPABASE_ANON_KEY\s*=\s*(.+)') {
    $supabaseKey = $matches[1].Trim().Trim('"').Trim("'")
    Write-Host "Found SUPABASE_ANON_KEY: $($supabaseKey.Substring(0, 20))..." -ForegroundColor Green
} else {
    Write-Host "Error: SUPABASE_ANON_KEY not found in .env" -ForegroundColor Red
    exit 1
}

# Read script.js
$scriptContent = Get-Content $scriptPath -Raw

# Replace placeholders
$scriptContent = $scriptContent -replace "const SUPABASE_URL = 'YOUR_SUPABASE_URL';", "const SUPABASE_URL = '$supabaseUrl';"
$scriptContent = $scriptContent -replace "const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';", "const SUPABASE_ANON_KEY = '$supabaseKey';"

# Write back to script.js
Set-Content -Path $scriptPath -Value $scriptContent

Write-Host "`n✅ Successfully updated script.js with Supabase credentials!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Run the SQL migration in Supabase dashboard" -ForegroundColor White
Write-Host "2. Deploy: cd web\landing && firebase deploy --only hosting" -ForegroundColor White
Write-Host "3. Test forms on your live site" -ForegroundColor White
Write-Host "4. View signups in Admin app (Waiting List tab)" -ForegroundColor White
