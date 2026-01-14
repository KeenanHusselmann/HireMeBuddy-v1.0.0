# Check and Set Edge Function Secrets
# Run this to verify and update environment variables

Write-Host "🔐 Checking Edge Function Configuration...`n" -ForegroundColor Cyan

# Read Firebase service account
# SECURITY: Use environment variable for service account path
$serviceAccountPath = $env:FIREBASE_SERVICE_ACCOUNT_PATH
if (-not $serviceAccountPath) {
    Write-Host "⚠️  FIREBASE_SERVICE_ACCOUNT_PATH not set" -ForegroundColor Yellow
    Write-Host "   Set it with: `$env:FIREBASE_SERVICE_ACCOUNT_PATH='C:\Secure\HireMeBuddy\your-service-account.json'" -ForegroundColor Gray
    exit 1
}

if (Test-Path $serviceAccountPath) {
    $serviceAccountJson = Get-Content $serviceAccountPath -Raw
    $serviceAccount = $serviceAccountJson | ConvertFrom-Json
    
    Write-Host "✅ Service account found" -ForegroundColor Green
    Write-Host "   Project ID: $($serviceAccount.project_id)" -ForegroundColor Gray
    
    # Base64 encode
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($serviceAccountJson)
    $base64 = [Convert]::ToBase64String($bytes)
    
    Write-Host "`n📋 Setting Edge Function Secrets..." -ForegroundColor Yellow
    
    # Set secrets directly
    # SECURITY: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-provided by Supabase
    $secretsCmd = "supabase secrets set --project-ref vjpaolkqlumpyuxxmmvr SERVICE_ACCOUNT_JSON=`"$base64`" PROJECT_ID=`"$($serviceAccount.project_id)`""
    
    Write-Host $secretsCmd
    Invoke-Expression $secretsCmd
    
    Write-Host "`n🚀 Redeploying process_queue function..." -ForegroundColor Yellow
    supabase functions deploy process_queue --project-ref vjpaolkqlumpyuxxmmvr
    
} else {
    Write-Host "❌ Service account not found at: $serviceAccountPath" -ForegroundColor Red
}
