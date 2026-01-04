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
$serviceAccountPath = "hiremebuddy-850a8-2d033e0c5ff3.json"
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
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0"

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
