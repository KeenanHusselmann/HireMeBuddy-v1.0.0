# Build script for generating separate Client and Provider APKs
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Building HireMeBuddy APKs" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$outputDir = "build\apk_releases"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Build Client APK
Write-Host "Building Client APK..." -ForegroundColor Yellow
flutter build apk --release --flavor client -t lib/main.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Client APK built successfully" -ForegroundColor Green
    Copy-Item "build\app\outputs\flutter-apk\app-client-release.apk" "$outputDir\HireMeBuddy-Client.apk" -Force
    Write-Host "  Copied to: $outputDir\HireMeBuddy-Client.apk" -ForegroundColor Gray
} else {
    Write-Host "✗ Client APK build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Build Provider APK
Write-Host "Building Provider APK..." -ForegroundColor Yellow
flutter build apk --release --flavor provider -t lib/main_provider.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Provider APK built successfully" -ForegroundColor Green
    Copy-Item "build\app\outputs\flutter-apk\app-provider-release.apk" "$outputDir\HireMeBuddy-Provider.apk" -Force
    Write-Host "  Copied to: $outputDir\HireMeBuddy-Provider.apk" -ForegroundColor Gray
} else {
    Write-Host "✗ Provider APK build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "APKs are located in: $outputDir" -ForegroundColor Cyan
Write-Host "  - HireMeBuddy-Client.apk" -ForegroundColor White
Write-Host "  - HireMeBuddy-Provider.apk" -ForegroundColor White
Write-Host ""

# Get file sizes
$clientSize = (Get-Item "$outputDir\HireMeBuddy-Client.apk").Length / 1MB
$providerSize = (Get-Item "$outputDir\HireMeBuddy-Provider.apk").Length / 1MB

Write-Host "Client APK size: $([math]::Round($clientSize, 2)) MB" -ForegroundColor Gray
Write-Host "Provider APK size: $([math]::Round($providerSize, 2)) MB" -ForegroundColor Gray
