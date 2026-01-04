# Manual Notification Queue Processor
# This script manually processes pending notifications in the queue
# Use this until cron job is set up

Write-Host "🔔 Processing FCM Notification Queue..." -ForegroundColor Cyan

# Read your Supabase project configuration
$supabaseUrl = "YOUR_SUPABASE_URL"  # e.g., https://xxxxx.supabase.co
$serviceRoleKey = "YOUR_SERVICE_ROLE_KEY"  # From Dashboard > Settings > API

# Check if configured
if ($supabaseUrl -eq "YOUR_SUPABASE_URL" -or $serviceRoleKey -eq "YOUR_SERVICE_ROLE_KEY") {
    Write-Host "❌ ERROR: Please configure your Supabase credentials in this script" -ForegroundColor Red
    Write-Host ""
    Write-Host "Update these variables:"
    Write-Host '  $supabaseUrl = "https://YOUR_PROJECT_REF.supabase.co"'
    Write-Host '  $serviceRoleKey = "YOUR_SERVICE_ROLE_KEY"'
    Write-Host ""
    Write-Host "Get your service role key from: Supabase Dashboard > Settings > API"
    exit 1
}

# Call the process_queue edge function
$endpoint = "$supabaseUrl/functions/v1/process_queue"

Write-Host "📡 Calling: $endpoint" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $endpoint `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceRoleKey"
            "Content-Type" = "application/json"
        } `
        -Body '{}' `
        -ErrorAction Stop

    Write-Host "✅ Success!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "✨ Check your provider device now!" -ForegroundColor Green

} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:"
    Write-Host "  1. Edge function is deployed: supabase functions deploy process_queue"
    Write-Host "  2. Service role key is correct"
    Write-Host "  3. Edge function has required environment variables set"
}
