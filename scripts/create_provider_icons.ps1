Add-Type -AssemblyName System.Drawing

# Load the original logo
$logoPath = "c:\Users\keena\Projects\hiremebuddy_flutter\assets\images\hiremebuddy-logo.png"
$logo = [System.Drawing.Image]::FromFile($logoPath)

# Define sizes for Android icons
$sizes = @(48, 72, 96, 144, 192)
$folders = @('mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi')

# Orange color for provider app (deep orange)
$orange = [System.Drawing.Color]::FromArgb(255, 255, 111, 0)

for ($i = 0; $i -lt $sizes.Length; $i++) {
    $size = $sizes[$i]
    $folder = $folders[$i]
    
    # Create bitmap with orange background
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fill with orange background
    $brush = New-Object System.Drawing.SolidBrush($orange)
    $graphics.FillRectangle($brush, 0, 0, $size, $size)
    
    # Calculate padding (10% on each side)
    $padding = [int]($size * 0.1)
    $logoSize = $size - (2 * $padding)
    
    # Draw logo centered with padding
    $destRect = New-Object System.Drawing.Rectangle($padding, $padding, $logoSize, $logoSize)
    $graphics.DrawImage($logo, $destRect, 0, 0, $logo.Width, $logo.Height, [System.Drawing.GraphicsUnit]::Pixel)
    
    # Save provider icon
    $outputPath = "c:\Users\keena\Projects\hiremebuddy_flutter\android\app\src\main\res\$folder\ic_launcher_provider.png"
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $graphics.Dispose()
    $bitmap.Dispose()
    $brush.Dispose()
    
    Write-Host "Created $outputPath"
}

$logo.Dispose()
Write-Host ""
Write-Host "Provider icons with orange background created successfully!" -ForegroundColor Green
