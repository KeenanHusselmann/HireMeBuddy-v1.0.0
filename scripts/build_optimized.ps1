# HireMeBuddy Flutter - Optimized Build Script
# This script builds both Client and Provider apps with maximum size optimization

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('client', 'provider', 'both')]
    [string]$App = 'both',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('apk', 'appbundle', 'both')]
    [string]$BuildType = 'both',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipAnalysis
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "HireMeBuddy Optimized Build" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Create debug-info directory if it doesn't exist
if (-not (Test-Path "debug-info")) {
    New-Item -ItemType Directory -Path "debug-info" | Out-Null
}

# Build function
function Build-App {
    param(
        [string]$AppName,
        [string]$EntryPoint
    )
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Building $AppName App" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    
    # Build APKs
    if ($BuildType -eq 'apk' -or $BuildType -eq 'both') {
        Write-Host "Building Split APKs (optimized for size)..." -ForegroundColor Yellow
        flutter build apk `
            -t $EntryPoint `
            --release `
            --split-per-abi `
            --obfuscate `
            --split-debug-info=./debug-info/$AppName
        
        Write-Host ""
        Write-Host "✓ APKs built successfully!" -ForegroundColor Green
        Write-Host "Location: build\app\outputs\flutter-apk\" -ForegroundColor Cyan
        Write-Host ""
        
        # List APK sizes
        Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | ForEach-Object {
            $sizeInMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name): $sizeInMB MB" -ForegroundColor White
        }
    }
    
    # Build App Bundle
    if ($BuildType -eq 'appbundle' -or $BuildType -eq 'both') {
        Write-Host ""
        Write-Host "Building App Bundle (for Play Store)..." -ForegroundColor Yellow
        flutter build appbundle `
            -t $EntryPoint `
            --release `
            --obfuscate `
            --split-debug-info=./debug-info/$AppName
        
        Write-Host ""
        Write-Host "✓ App Bundle built successfully!" -ForegroundColor Green
        Write-Host "Location: build\app\outputs\bundle\release\" -ForegroundColor Cyan
        Write-Host ""
        
        # List Bundle size
        Get-ChildItem "build\app\outputs\bundle\release\*.aab" | ForEach-Object {
            $sizeInMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name): $sizeInMB MB" -ForegroundColor White
        }
    }
    
    # Size analysis
    if (-not $SkipAnalysis) {
        Write-Host ""
        Write-Host "Running size analysis..." -ForegroundColor Yellow
        flutter build apk `
            -t $EntryPoint `
            --analyze-size `
            --target-platform android-arm64
    }
}

# Build based on parameter
switch ($App) {
    'client' {
        Build-App -AppName "Client" -EntryPoint "lib/main.dart"
    }
    'provider' {
        Build-App -AppName "Provider" -EntryPoint "lib/main_provider.dart"
    }
    'both' {
        Build-App -AppName "Client" -EntryPoint "lib/main.dart"
        Build-App -AppName "Provider" -EntryPoint "lib/main_provider.dart"
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test APKs on physical devices" -ForegroundColor White
Write-Host "2. Upload .aab file to Google Play Console" -ForegroundColor White
Write-Host "3. Review size analysis in Dart DevTools" -ForegroundColor White
Write-Host ""
Write-Host "Debug symbols saved in: debug-info\" -ForegroundColor Cyan
Write-Host "Keep these files for crash reporting!" -ForegroundColor Yellow
Write-Host ""
