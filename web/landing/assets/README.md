# HireMeBuddy Landing Page Assets

## Current Status
The landing page is using placeholder images. Replace these with actual HireMeBuddy branded assets.

## Images to Replace

### 1. Logo (ALREADY ADDED - Placeholder)
- **Current:** `logo.svg` - Simple SVG placeholder with green circle and handshake
- **Replace with:** Your actual HireMeBuddy logo
- **Recommended size:** 120x120px (square) or width optimized
- **Format:** PNG or SVG preferred
- **Usage:** Navigation header

### 2. App Screenshots (Currently using placeholders)
These are currently using `placehold.co` URLs. Replace with actual screenshots:

#### Hero Section App Screenshot
- **Current:** Blue placeholder with "HireMeBuddy App" text
- **Replace with:** Actual mobile app screenshot showing main feed/homepage
- **Recommended size:** 400x800px (phone mockup aspect ratio)
- **Format:** PNG with transparency
- **Suggested filename:** `app-screenshot-hero.png`

#### Provider Profile Screenshot
- **Current:** Green placeholder with "Provider Profile" text
- **Replace with:** Screenshot showing provider profile interface
- **Recommended size:** 600x700px
- **Format:** PNG
- **Suggested filename:** `provider-profile.png`

#### Client Dashboard Screenshot
- **Current:** Blue placeholder with "Client Dashboard" text
- **Replace with:** Screenshot showing client dashboard/job posting interface
- **Recommended size:** 600x700px
- **Format:** PNG
- **Suggested filename:** `client-dashboard.png`

### 3. Additional Assets Needed

#### App Store Badges
- Google Play badge (add when app is published)
- Apple App Store badge (for future iOS app)
- **Recommended size:** Official badge sizes from Google/Apple
- **Download from:** 
  - Google: https://play.google.com/intl/en_us/badges/
  - Apple: https://developer.apple.com/app-store/marketing/guidelines/

#### QR Code
- QR code linking to Google Play Store
- **Generate at:** https://www.qr-code-generator.com/
- **Link to:** Your app's Play Store URL
- **Recommended size:** 300x300px
- **Suggested filename:** `app-qr-code.png`

#### Social Media Preview Image (Open Graph)
- Image shown when sharing on Facebook, Twitter, WhatsApp
- **Recommended size:** 1200x630px
- **Format:** PNG or JPG
- **Suggested filename:** `og-image.png`
- **Content:** HireMeBuddy logo + tagline

## How to Replace Images

1. **For logo:**
   - Replace `logo.svg` with your actual logo file
   - If using PNG, update `index.html` line 19 to use `.png` extension

2. **For screenshots:**
   - Save your actual screenshots to this `assets/` folder
   - Update the HTML file to use local images instead of placehold.co URLs:

   ```html
   <!-- Hero screenshot -->
   <img src="assets/app-screenshot-hero.png" alt="HireMeBuddy App Interface" class="screenshot">
   
   <!-- Provider profile -->
   <img src="assets/provider-profile.png" alt="Provider Profile Interface" class="feature-image">
   
   <!-- Client dashboard -->
   <img src="assets/client-dashboard.png" alt="Client Dashboard Interface" class="feature-image">
   ```

3. **Optimize images before uploading:**
   - Use https://tinypng.com/ to compress PNG files
   - Consider WebP format for better performance
   - Keep file sizes under 500KB each

## After Adding Real Images

1. Test locally to ensure images load properly
2. Deploy to Firebase:
   ```bash
   cd c:\Users\keena\Projects\HireMeBuddy-v1.0.0\web\landing
   firebase deploy --only hosting
   ```
3. Clear browser cache and verify images appear correctly

## Current Theme Colors

The website now uses HireMeBuddy brand colors:
- **Primary Green:** #4CAF50
- **Secondary Blue:** #2196F3
- **Accent Orange:** #FF9800
- **Dark:** #212121

Make sure your images complement these colors for a cohesive brand experience.
