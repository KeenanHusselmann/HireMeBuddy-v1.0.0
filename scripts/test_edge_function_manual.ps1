# Test Edge Function Manually
# This bypasses the cron job to test if the function works directly

Write-Host "🧪 Testing process_queue Edge Function directly...`n" -ForegroundColor Cyan

$supabaseUrl = "https://vjpaolkqlumpyuxxmmvr.supabase.co"
# SECURITY: Get service_role_key from environment variable
$serviceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $serviceRoleKey) {
    Write-Host "ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    Write-Host "Set it with: `$env:SUPABASE_SERVICE_ROLE_KEY='your-key'" -ForegroundColor Yellow
    exit 1
}

Write-Host "📡 Calling: $supabaseUrl/functions/v1/process_queue" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/functions/v1/process_queue" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $serviceRoleKey"
            "Content-Type" = "application/json"
        } `
        -Body '{}' `
        -ErrorAction Stop

    Write-Host "✅ Success!" -ForegroundColor Green
    Write-Host "`nResponse:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "❌ Error!" -ForegroundColor Red
    Write-Host "`nStatus Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "`nResponse Body:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "`n📋 Check Supabase Dashboard for logs:" -ForegroundColor Cyan
Write-Host "https://supabase.com/dashboard/project/vjpaolkqlumpyuxxmmvr/functions/process_queue" -ForegroundColor Gray
