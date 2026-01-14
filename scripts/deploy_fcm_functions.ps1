# Deploy FCM Edge Functions with Environment Variables
# This deploys the enqueue_and_send edge function with all required secrets

Write-Host "🚀 Deploying FCM Edge Functions..." -ForegroundColor Cyan
Write-Host ""

# Change to project directory
cd "$env:USERPROFILE\Projects\HireMeBuddy-v1.0.0"

# Check if supabase CLI is available
if (!(Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install via npm: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Step 1: Setting environment secrets..." -ForegroundColor Yellow

# Read Firebase service account JSON
# SECURITY: Store service account in secure location, not in project directory
$serviceAccountPath = $env:FIREBASE_SERVICE_ACCOUNT_PATH
if (-not $serviceAccountPath) {
    Write-Host "❌ FIREBASE_SERVICE_ACCOUNT_PATH environment variable not set" -ForegroundColor Red
    Write-Host "   Set it with: `$env:FIREBASE_SERVICE_ACCOUNT_PATH='C:\Secure\HireMeBuddy\your-service-account.json'" -ForegroundColor Yellow
    exit 1
}
if (!(Test-Path $serviceAccountPath)) {
    Write-Host "❌ Firebase service account file not found: $serviceAccountPath" -ForegroundColor Red
    exit 1
}

$serviceAccountJson = Get-Content $serviceAccountPath -Raw | Out-String
$serviceAccountBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($serviceAccountJson))

Write-Host "   Setting SERVICE_ACCOUNT_JSON..." -ForegroundColor Gray
supabase secrets set SERVICE_ACCOUNT_JSON="$serviceAccountBase64"

Write-Host "   Setting SUPABASE_URL..." -ForegroundColor Gray
supabase secrets set SUPABASE_URL="https://vjpaolkqlumpyuxxmmvr.supabase.co"

Write-Host "   Setting SUPABASE_SERVICE_ROLE_KEY..." -ForegroundColor Gray
Write-Host "   NOTE: service_role_key is auto-provided by Supabase to Edge Functions" -ForegroundColor Yellow
# SECURITY: service_role_key should NOT be set as a custom secret
# It's automatically available as SUPABASE_SERVICE_ROLE_KEY in Edge Functions

Write-Host ""
Write-Host "📦 Step 2: Deploying edge functions..." -ForegroundColor Yellow

# Deploy enqueue_and_send function
Write-Host "   Deploying enqueue_and_send..." -ForegroundColor Gray
supabase functions deploy enqueue_and_send

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Run check_pgnet_responses.sql to verify pg_net is working"
Write-Host "   2. Create a test booking to verify notifications"
Write-Host "   3. Check provider device for instant notification"
