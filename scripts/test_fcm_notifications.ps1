# FCM Push Notification Testing Script
# This script helps test Firebase Cloud Messaging notifications for HireMeBuddy

Write-Host "🔔 FCM Push Notification Testing Tool" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$PROJECT_ID = "hiremebuddy-850a8"
$SERVER_KEY_FILE = "hiremebuddy-850a8-2d033e0c5ff3.json"

# Check if service account key exists
if (-not (Test-Path $SERVER_KEY_FILE)) {
    Write-Host "❌ ERROR: Service account key file not found!" -ForegroundColor Red
    Write-Host "   Expected: $SERVER_KEY_FILE" -ForegroundColor Yellow
    Write-Host "   Please download from Firebase Console > Project Settings > Service Accounts" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Service account key found" -ForegroundColor Green
Write-Host ""

# Function to get FCM token from app
function Get-FCMToken {
    Write-Host "📱 To get your FCM token:" -ForegroundColor Cyan
    Write-Host "   1. Run the app on your device/emulator" -ForegroundColor White
    Write-Host "   2. Check the console logs for 'FCM token:'" -ForegroundColor White
    Write-Host "   3. Copy the token (long string starting with 'f' or 'c')" -ForegroundColor White
    Write-Host ""
    Write-Host "   Example log output:" -ForegroundColor DarkGray
    Write-Host "   I/flutter (12345): ℹ️ FCM token: fK3x9Y2m..." -ForegroundColor DarkGray
    Write-Host ""
}

# Function to send test notification using FCM HTTP v1 API
function Send-FCMNotification {
    param(
        [string]$Token,
        [string]$Title,
        [string]$Body,
        [hashtable]$Data = @{}
    )

    Write-Host "🚀 Sending FCM notification..." -ForegroundColor Yellow
    
    # Get access token from service account
    Write-Host "   Getting OAuth2 access token..." -ForegroundColor DarkGray
    
    # Install Google.Apis.Auth if not present
    $gcloudInstalled = Get-Command gcloud -ErrorAction SilentlyContinue
    if (-not $gcloudInstalled) {
        Write-Host "❌ gcloud CLI not found. Installing Firebase Admin SDK..." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install gcloud CLI:" -ForegroundColor Yellow
        Write-Host "   https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or use the Node.js test script instead." -ForegroundColor Yellow
        exit 1
    }

    # Authenticate with service account
    gcloud auth activate-service-account --key-file=$SERVER_KEY_FILE | Out-Null
    
    # Get access token
    $ACCESS_TOKEN = (gcloud auth print-access-token) | Out-String
    $ACCESS_TOKEN = $ACCESS_TOKEN.Trim()

    # Prepare FCM message
    $fcmMessage = @{
        message = @{
            token = $Token
            notification = @{
                title = $Title
                body = $Body
            }
            data = $Data
            android = @{
                priority = "high"
                notification = @{
                    sound = "default"
                    channel_id = "default"
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    # Send notification
    $url = "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send"
    
    try {
        $response = Invoke-RestMethod -Uri $url `
            -Method Post `
            -Headers @{
                "Authorization" = "Bearer $ACCESS_TOKEN"
                "Content-Type" = "application/json"
            } `
            -Body $fcmMessage

        Write-Host "✅ Notification sent successfully!" -ForegroundColor Green
        Write-Host "   Message ID: $($response.name)" -ForegroundColor DarkGray
        return $true
    }
    catch {
        Write-Host "❌ Failed to send notification" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# Main menu
function Show-Menu {
    Write-Host ""
    Write-Host "📋 Test Options:" -ForegroundColor Cyan
    Write-Host "   1. Send test notification (manual token entry)" -ForegroundColor White
    Write-Host "   2. Send booking notification" -ForegroundColor White
    Write-Host "   3. Send message notification" -ForegroundColor White
    Write-Host "   4. Send payment notification" -ForegroundColor White
    Write-Host "   5. Show how to get FCM token" -ForegroundColor White
    Write-Host "   6. Exit" -ForegroundColor White
    Write-Host ""
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select option (1-6)"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            $token = Read-Host "Enter FCM token"
            if ([string]::IsNullOrWhiteSpace($token)) {
                Write-Host "❌ Token cannot be empty" -ForegroundColor Red
                continue
            }
            
            $title = Read-Host "Enter notification title"
            $body = Read-Host "Enter notification body"
            
            Send-FCMNotification -Token $token -Title $title -Body $body
        }
        "2" {
            Write-Host ""
            $token = Read-Host "Enter FCM token"
            if ([string]::IsNullOrWhiteSpace($token)) {
                Write-Host "❌ Token cannot be empty" -ForegroundColor Red
                continue
            }
            
            $data = @{
                type = "booking"
                booking_id = "test-booking-123"
                action = "new_booking"
            }
            
            Send-FCMNotification -Token $token `
                -Title "🎉 New Booking Request!" `
                -Body "You have a new booking request for Plumbing Service" `
                -Data $data
        }
        "3" {
            Write-Host ""
            $token = Read-Host "Enter FCM token"
            if ([string]::IsNullOrWhiteSpace($token)) {
                Write-Host "❌ Token cannot be empty" -ForegroundColor Red
                continue
            }
            
            $data = @{
                type = "message"
                chat_id = "test-chat-456"
                sender_name = "Test Client"
            }
            
            Send-FCMNotification -Token $token `
                -Title "💬 New Message" `
                -Body "Test Client: Hey, are you available tomorrow?" `
                -Data $data
        }
        "4" {
            Write-Host ""
            $token = Read-Host "Enter FCM token"
            if ([string]::IsNullOrWhiteSpace($token)) {
                Write-Host "❌ Token cannot be empty" -ForegroundColor Red
                continue
            }
            
            $data = @{
                type = "payment"
                payment_id = "test-payment-789"
                amount = "150.00"
            }
            
            Send-FCMNotification -Token $token `
                -Title "💰 Payment Received" `
                -Body "You received N$150.00 for Plumbing Service" `
                -Data $data
        }
        "5" {
            Get-FCMToken
        }
        "6" {
            Write-Host ""
            Write-Host "👋 Goodbye!" -ForegroundColor Cyan
            exit 0
        }
        default {
            Write-Host "❌ Invalid option. Please select 1-6." -ForegroundColor Red
        }
    }
}
