# Website Landing Page Screenshot Guide

## Overview
This guide provides the exact specifications for all screenshots needed for the HireMeBuddy marketing website (web/landing/index.html).

---

## 🎯 Required Screenshots

### 1. **hero_app_home.png**
**Location:** Hero section (top of page)
**Purpose:** First impression - show the main app interface

**What to capture:**
- Main home screen with search bar prominent
- Service categories visible
- Clean, professional UI
- Show the "Browse Services" or search functionality
- Ideally with some provider cards/listings visible

**Recommended specs:**
- Dimensions: **1080 x 2340px** (typical Android aspect ratio 19.5:9)
- Format: PNG with high quality
- Device: Real device screenshot or clean mockup
- Content: Actual app interface (not demo/placeholder data)

**Placement:** Center-right of hero section in phone mockup frame

---

### 2. **provider_dashboard.png**
**Location:** "For Service Providers" section
**Purpose:** Show provider experience - profile, earnings, bookings

**What to capture:**
- Provider profile screen showing:
  - Profile photo and verified badge
  - Star rating (4-5 stars preferred)
  - Skills/services offered
  - Portfolio images or videos
  - Recent bookings or earnings summary
  - "Accept Booking" or active bookings visible
- Professional-looking provider data

**Recommended specs:**
- Dimensions: **1080 x 2340px**
- Format: PNG with high quality
- Device: Same as hero screenshot for consistency
- Content: Provider dashboard or profile view

**Placement:** Right side of "For Providers" section in phone mockup

---

### 3. **client_booking_flow.png**
**Location:** "For Clients" section
**Purpose:** Show client booking experience

**What to capture:**
- Either:
  - **Option A:** Service search/browse screen with provider listings
  - **Option B:** Booking form showing date/time selection
  - **Option C:** Active booking with provider details and chat option
- Should show ease of use and clear UI

**Recommended specs:**
- Dimensions: **1080 x 2340px**
- Format: PNG with high quality
- Device: Consistent with other screenshots
- Content: Client-facing booking interface

**Placement:** Right side of "For Clients" section in phone mockup

---

## 📐 Technical Specifications

### Image Requirements
- **Format:** PNG (preferred) or high-quality JPG
- **Resolution:** Minimum 1080px width
- **Aspect Ratio:** 19.5:9 (or 9:16 portrait)
- **File Size:** Under 500KB each (compress without losing quality)
- **Color Space:** sRGB
- **Background:** App screenshots (not transparent)

### Phone Mockup Frame
The website automatically adds a phone frame mockup around your screenshots. Your images should be:
- Full app screenshots (no device frame needed)
- Clean edges (no shadows or external frames)
- Centered content (important UI in center, not edges)

---

## 🎨 Content Guidelines

### What to Show
✅ **DO:**
- Use REAL app screenshots from actual running app
- Show authentic data (even if test/demo data)
- Ensure teal/cyan brand colors are visible
- Include HireMeBuddy branding/logo if visible in app
- Show 4-5 star ratings (positive sentiment)
- Use clear, professional provider photos
- Show Namibian context where possible (locations, currency N$)

❌ **DON'T:**
- Use completely blank/empty screens
- Show error messages or broken UI
- Include sensitive real user data (names, phones, addresses)
- Show debug info, toast messages, or development artifacts
- Include status bar with notifications/time if possible (crop it out)

### Demo Data Recommendations
If using test data, make it look realistic:
- **Provider names:** Use common Namibian names
- **Services:** Real service categories (Plumbing, Electrical, etc.)
- **Locations:** Windhoek, Swakopmund, Walvis Bay, etc.
- **Ratings:** 4.0 - 5.0 stars
- **Prices:** N$50-150 per hour (realistic Namibian rates)
- **Reviews:** Professional, positive reviews with reasonable length

---

## 🛠️ How to Capture Screenshots

### Method 1: Android Device (Recommended)
1. Run the client or provider app on a real Android device
2. Navigate to the desired screen
3. Press **Power + Volume Down** simultaneously
4. Find screenshot in Photos/Screenshots folder
5. Transfer to computer via USB or cloud

### Method 2: Android Emulator
1. Run app in Android Studio emulator
2. Navigate to desired screen
3. Click camera icon in emulator toolbar
4. Screenshots saved to: `C:\Users\{user}\.android\avd\{device}\screenshots\`

### Method 3: Flutter DevTools
1. Run app with `flutter run`
2. Open DevTools (press 'v' in terminal)
3. Click "Screenshot" button in DevTools UI
4. Save the PNG file

---

## ✂️ Post-Processing

### Recommended Edits
1. **Crop**: Remove status bar (top) and navigation bar (bottom) if desired
2. **Center**: Ensure main content is vertically centered
3. **Clean**: Remove any debug overlays or developer info
4. **Compress**: Use TinyPNG or similar to reduce file size
5. **Verify**: Check that colors look good and text is readable

### Tools
- **Editing:** Photoshop, GIMP, Figma, or Paint.NET
- **Compression:** [TinyPNG](https://tinypng.com/), [Squoosh](https://squoosh.app/)
- **Mockups:** [Mockuphone](http://mockuphone.com/), [Smartmockups](https://smartmockups.com/)

---

## 📁 File Organization

Save screenshots in this directory structure:
```
web/landing/images/screenshots/
├── hero_app_home.png
├── provider_dashboard.png
└── client_booking_flow.png
```

Update the HTML to reference actual images:
```html
<!-- Replace placeholder div with actual image -->
<img src="images/screenshots/hero_app_home.png" 
     alt="HireMeBuddy App Home Screen" 
     style="width: 100%; height: auto; border-radius: 30px; box-shadow: var(--shadow-xl);">
```

---

## 🎯 Image Descriptions for Each Screenshot

### hero_app_home.png
**Alt text:** "HireMeBuddy app home screen showing service search and verified providers"
**Context:** First thing visitors see - make it impressive and professional

### provider_dashboard.png
**Alt text:** "Service provider dashboard with bookings, ratings, and earnings"
**Context:** Convinces providers to join - show earning potential and ease of use

### client_booking_flow.png
**Alt text:** "Client booking interface with service selection and provider profiles"
**Context:** Shows clients how easy it is to book - emphasize simplicity

---

## 🚀 Optional Enhancement: Device Mockups

For a more polished look, you can place your screenshots inside device mockups:

### Using Mockuphone (Free)
1. Go to [mockuphone.com](http://mockuphone.com/)
2. Upload your screenshot
3. Select device: Samsung Galaxy S21 or similar
4. Download mockup with device frame
5. Use this instead of plain screenshot

### Using Figma (Professional)
1. Find free phone mockup templates on [Figma Community](https://www.figma.com/community)
2. Paste your screenshot into the template
3. Export as PNG at 2x resolution
4. More control over shadows and positioning

---

## ✅ Quality Checklist

Before uploading screenshots, verify:

- [ ] Image dimensions are 1080x2340px or higher
- [ ] File format is PNG
- [ ] No personal/sensitive data visible
- [ ] App UI is clean and polished
- [ ] Brand colors (teal/cyan) are visible
- [ ] Text is readable and sharp
- [ ] File size is under 500KB
- [ ] Screenshots show positive user experience (good ratings, active bookings, etc.)
- [ ] All 3 required screenshots are ready
- [ ] Images are saved in correct directory: `web/landing/images/screenshots/`

---

## 🔄 Updating the Website

Once you have the screenshots:

### Option 1: Using `<img>` tags (Recommended)
Replace the placeholder divs in `index.html`:

```html
<!-- Before -->
<div class="screenshot-placeholder">
    <div class="placeholder-content">...</div>
</div>

<!-- After -->
<img src="images/screenshots/hero_app_home.png" 
     alt="HireMeBuddy App" 
     class="app-screenshot">
```

### Option 2: Using CSS Background
Update the CSS to use actual images:

```css
.screenshot-placeholder {
    background-image: url('../images/screenshots/hero_app_home.png');
    background-size: cover;
    background-position: center;
}
```

---

## 📊 Current Placeholder Status

The website currently shows styled placeholder boxes with:
- 📱 Icon
- Filename (e.g., "hero_app_home.png")
- Description of what to capture
- Recommended dimensions

These placeholders are designed to be replaced with your actual screenshots. The styling already includes:
- Phone mockup frames
- Proper shadows
- Responsive sizing
- Border radius for modern look

---

## 💡 Pro Tips

1. **Consistency:** Use the same device/aspect ratio for all screenshots
2. **Timing:** Capture during optimal lighting if using real device
3. **Content:** Show the app in its best state (good data, no errors)
4. **Context:** Include Namibian elements (locations, currency) where possible
5. **Updates:** Screenshots can be updated anytime - save source files for easy updates

---

## 🆘 Need Help?

If you encounter issues:
1. **Screenshot not saving:** Check device storage permissions
2. **Wrong aspect ratio:** Crop to 9:16 using image editor
3. **File too large:** Compress using TinyPNG without losing quality
4. **UI not showing properly:** Ensure app is in production mode (not debug)
5. **Can't decide what to show:** Focus on the most impressive/useful features

---

## 📈 Impact

Good screenshots will:
- ✅ Increase conversion rates (visitors → downloads)
- ✅ Build trust and credibility
- ✅ Showcase app features visually
- ✅ Reduce bounce rate on landing page
- ✅ Improve Google Play Store rankings (when used there too)

Take your time to get great screenshots - they're worth the investment! 🎯
