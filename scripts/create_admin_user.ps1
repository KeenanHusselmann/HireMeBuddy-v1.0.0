# PowerShell script to create admin user via Supabase Admin API
# You need the SERVICE_ROLE_KEY (not the ANON_KEY) for this to work

$SUPABASE_URL = "https://vjpaolkqlumpyuxxmmvr.supabase.co"
$SERVICE_ROLE_KEY = Read-Host "Enter your Supabase SERVICE_ROLE_KEY (found in Project Settings > API)"

$email = "admin@hiremebuddy.app"
$password = ";&k3;QNx8-k?RT_"

Write-Host "Creating admin user..." -ForegroundColor Cyan

# Create the auth user
$createUserBody = @{
    email = $email
    password = $password
    email_confirm = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/auth/v1/admin/users" `
        -Method Post `
        -Headers @{
            "apikey" = $SERVICE_ROLE_KEY
            "Authorization" = "Bearer $SERVICE_ROLE_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $createUserBody

    $userId = $response.id
    Write-Host "✓ Auth user created with ID: $userId" -ForegroundColor Green

    # Update the profile to admin role
    $updateProfileBody = @{
        role = "admin"
        full_name = "Admin User"
        first_name = "Admin"
        last_name = "User"
        phone = "+264000000000"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/profiles?id=eq.$userId" `
        -Method Patch `
        -Headers @{
            "apikey" = $SERVICE_ROLE_KEY
            "Authorization" = "Bearer $SERVICE_ROLE_KEY"
            "Content-Type" = "application/json"
            "Prefer" = "return=minimal"
        } `
        -Body $updateProfileBody

    Write-Host "✓ Profile updated to admin role" -ForegroundColor Green
    Write-Host ""
    Write-Host "Admin user created successfully!" -ForegroundColor Green
    Write-Host "Email: $email" -ForegroundColor Yellow
    Write-Host "Password: $password" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can now log in at: admin.hiremebuddy.app" -ForegroundColor Cyan

} catch {
    Write-Host "✗ Error creating user: $_" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
