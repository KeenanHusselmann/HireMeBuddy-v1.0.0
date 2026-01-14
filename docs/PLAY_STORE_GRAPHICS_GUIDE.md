# HireMeBuddy App Icons and Play Store Graphics

## Required Assets for Play Store Submission

This document outlines the graphics assets needed for Google Play Store submission.

### 📱 App Icons (Required)

**Current Status**: Using default Flutter icons ❌

#### Android Adaptive Icon Requirements:
1. **Foreground Layer**: 432x432 px (PNG, transparent background)
2. **Background Layer**: 432x432 px (PNG, solid color or gradient)
3. **Legacy Icon**: 512x512 px (PNG, for older Android versions)

**Action Required**: Design custom app icons for both Client and Provider apps

#### Recommended Icon Sizes:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
└── mipmap-xxxhdpi/ic_launcher.png (192x192)
```

---

### 🎨 Play Store Listing Graphics (Required)

#### 1. Feature Graphic ⚠️ **REQUIRED**
- **Size**: 1024 x 500 px
- **Format**: PNG or JPEG
- **Purpose**: Displayed at top of Play Store listing
- **Current Status**: MISSING ❌

#### 2. Screenshots ⚠️ **REQUIRED** (Minimum 2)
- **Phone**: 16:9 aspect ratio (1920 x 1080 recommended)
- **Tablet**: 16:10 aspect ratio (2560 x 1600 recommended)
- **Quantity**: 2-8 screenshots
- **Current Status**: Need to capture from running apps ⚠️

#### 3. High-Resolution Icon **REQUIRED**
- **Size**: 512 x 512 px
- **Format**: PNG (32-bit with alpha)
- **Purpose**: Used in Play Store search and app details
- **Current Status**: Can use existing hiremebuddy-logo.png (needs verification) ⚠️

---

### 🎬 Optional but Recommended

#### Promotional Video (YouTube)
- Upload app demo to YouTube
- Add link in Play Console
- Increases conversion rate by ~20%

#### Promotional Graphic
- Size: 180 x 120 px
- Used in promotional campaigns

---

### 🚀 Quick Action Items

**Priority 1 - BLOCKERS**:
1. ❌ Create Feature Graphic (1024x500)
2. ❌ Verify/create High-res Icon (512x512)
3. ❌ Capture 4+ screenshots from both Client and Provider apps

**Priority 2 - Quality**:
4. ⚠️ Design adaptive icons (foreground/background layers)
5. ⚠️ Generate all density variants (mdpi to xxxhdpi)
6. ⚠️ Create promotional video (recommended)

---

### 📝 Tools for Asset Creation

**Recommended Tools**:
- **Icon Generator**: Android Studio > Image Asset Studio
- **Online Tools**: 
  - https://romannurik.github.io/AndroidAssetStudio/
  - https://appicon.co/
- **Graphics**: Figma, Canva, Adobe Illustrator
- **Screenshots**: Android Device/Emulator + Screenshot tool

---

### ✅ Using Android Studio Image Asset Studio

```bash
# In Android Studio:
1. Right-click android/app/src/main/res
2. New > Image Asset
3. Icon Type: Launcher Icons (Adaptive and Legacy)
4. Asset Type: Image (use hiremebuddy-logo.png)
5. Generate all densities
```

---

**Note**: Without Feature Graphic and High-res Icon, you CANNOT submit to Play Store.
