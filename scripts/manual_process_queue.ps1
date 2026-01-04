# Manually process pending notifications in the queue
# This directly calls the edge function for queued notifications

Write-Host "`nProcessing pending notifications...`n" -ForegroundColor Cyan

$supabaseUrl = "https://vjpaolkqlumpyuxxmmvr.supabase.co"
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0"

# Get unprocessed notifications
$query = "select=*&processed=eq.false&order=created_at.desc&limit=5"
$notificationsUrl = "$supabaseUrl/rest/v1/notification_queue?$query"

Write-Host "Fetching unprocessed notifications..." -ForegroundColor Yellow

$notifications = Invoke-RestMethod -Uri $notificationsUrl -Headers @{
    "apikey" = $serviceRoleKey
    "Authorization" = "Bearer $serviceRoleKey"
}

Write-Host "Found $($notifications.Count) pending notification(s)`n" -ForegroundColor Green

foreach ($notif in $notifications) {
    Write-Host "Processing notification ID: $($notif.id)" -ForegroundColor Cyan
    Write-Host "  Recipient: $($notif.recipient_id)" -ForegroundColor Gray
    Write-Host "  Title: $($notif.message_payload.title)" -ForegroundColor Gray
    
    # Call edge function
    $body = @{
        recipient_id = $notif.recipient_id
        message_payload = $notif.message_payload
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$supabaseUrl/functions/v1/enqueue_and_send" `
            -Method Post `
            -Headers @{
                "Authorization" = "Bearer $serviceRoleKey"
                "Content-Type" = "application/json"
            } `
            -Body $body
        
        Write-Host "  OK Sent successfully!`n" -ForegroundColor Green
        
    } catch {
        Write-Host "  ERROR Failed: $($_.Exception.Message)`n" -ForegroundColor Red
    }
}

Write-Host "Done! Check provider device for notifications." -ForegroundColor Green
