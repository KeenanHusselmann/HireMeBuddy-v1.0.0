# Landing Page Screenshot Guide

## Overview
This guide outlines the screenshots needed for the HireMeBuddy landing page to create an engaging and informative user experience.

---

## Required Screenshots

### 1. **screenshot_browse_services.png**
**Location:** How It Works - Step 1
**Purpose:** Show users browsing available services
**What to capture:**
- Service categories grid/list view
- Search functionality visible
- Multiple service categories displayed (Plumbing, Electrical, Cleaning, etc.)
- Clean, organized layout showing service discovery

**Recommended specs:**
- Dimensions: 1080 x 1920 px (9:16 portrait)
- Format: PNG with transparency or JPG
- Content: Services list screen with at least 6-8 visible categories

---

### 2. **screenshot_provider_profile.png**
**Location:** How It Works - Step 2
**Purpose:** Showcase provider profile with ratings and videos
**What to capture:**
- Provider profile header with avatar
- Star rating (4-5 stars preferred)
- "About me" section
- Skills/services offered
- Portfolio videos/images
- Reviews from previous clients
- Contact/Book button visible

**Recommended specs:**
- Dimensions: 1080 x 1920 px (9:16 portrait)
- Format: PNG with transparency or JPG
- Content: Attractive provider profile with complete information

---

### 3. **screenshot_booking_chat.png**
**Location:** How It Works - Step 3
**Purpose:** Display the booking and messaging experience
**What to capture:**
- Either a booking confirmation screen OR chat interface
- Recommended: Split-screen or two-part image showing:
  - TOP: Booking details (date, time, service, provider info)
  - BOTTOM: Chat conversation with provider
- Success indicators (checkmarks, confirmation messages)
- Clean messaging UI

**Recommended specs:**
- Dimensions: 1080 x 1920 px (9:16 portrait)
- Format: PNG with transparency or JPG
- Content: Completed booking with active chat conversation

---

## Additional Recommended Screenshots (Optional but Highly Recommended)

### 4. **screenshot_app_hero.png**
**Purpose:** Hero image for the top banner
**What to capture:**
- App home screen with welcoming interface
- Search bar prominent
- Colorful, inviting design
- Best foot forward - your most polished screen

**Recommended specs:**
- Dimensions: 1200 x 800 px (3:2 landscape) or 1080 x 1920 px (portrait)
- Format: PNG with transparency
- Content: Clean, professional home screen

---

### 5. **screenshot_video_feed.png**
**Purpose:** Show provider video portfolio feature
**What to capture:**
- Provider video feed/gallery
- Multiple video thumbnails
- Play buttons visible
- Provider names/services below videos

**Recommended specs:**
- Dimensions: 1080 x 1920 px (9:16 portrait)
- Format: PNG or JPG
- Content: Engaging video portfolio grid

---

### 6. **screenshot_ratings_reviews.png**
**Purpose:** Highlight the trust factor
**What to capture:**
- Reviews section with multiple 4-5 star reviews
- User avatars (anonymized if needed)
- Review text visible
- Overall rating summary

**Recommended specs:**
- Dimensions: 1080 x 1920 px (9:16 portrait)
- Format: PNG or JPG
- Content: Authentic-looking reviews

---

## How to Add Screenshots

### Option 1: Using Image Assets (Recommended)
1. Take screenshots using your device or emulator
2. Edit/crop screenshots to focus on relevant content
3. Save images to: `assets/images/landing/`
4. Update `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/images/landing/screenshot_browse_services.png
       - assets/images/landing/screenshot_provider_profile.png
       - assets/images/landing/screenshot_booking_chat.png
   ```
5. Replace placeholder in `home_screen.dart`:
   ```dart
   // Replace the Container placeholder with:
   ClipRRect(
     borderRadius: BorderRadius.circular(12),
     child: Image.asset(
       'assets/images/landing/$imageName',
       height: 200,
       width: double.infinity,
       fit: BoxFit.cover,
     ),
   )
   ```

### Option 2: Using Network Images
1. Upload screenshots to your server/CDN
2. Use `Image.network()` instead of `Image.asset()`
3. Add caching for better performance

### Option 3: Using Mockups (Professional Look)
1. Use tools like:
   - **Mockuphone** (mockuphone.com)
   - **Smartmockups** (smartmockups.com)
   - **Figma** with device mockup templates
2. Place your screenshots inside device frames
3. Export as PNG with transparent background

---

## Design Tips

### Screenshot Quality
- Use **high resolution** (at least 1080px width)
- Ensure **good lighting** if using real device photos
- **Remove sensitive data** (real names, phone numbers, addresses)
- Use **demo/test data** that looks realistic but is clearly fake

### Content Guidelines
- Show **happy path** scenarios (successful bookings, 5-star reviews)
- Use **diverse provider profiles** (different services, genders, ages)
- Include **Namibian context** where possible (local services, currency, locations)
- Keep UI **clean and uncluttered** - hide debug info, notification bars if possible

### Branding
- Ensure **teal/cyan theme** is consistent across screenshots
- Show **HireMeBuddy branding** (logo, colors)
- Maintain **professional appearance** - no bugs, broken layouts, or errors visible

---

## Implementation Checklist

- [ ] Capture screenshot_browse_services.png
- [ ] Capture screenshot_provider_profile.png
- [ ] Capture screenshot_booking_chat.png
- [ ] (Optional) Capture additional screenshots
- [ ] Edit/crop screenshots to highlight key features
- [ ] Remove sensitive information
- [ ] Add screenshots to `assets/images/landing/` folder
- [ ] Update `pubspec.yaml` to include image assets
- [ ] Update `home_screen.dart` to load actual images instead of placeholders
- [ ] Test on different screen sizes to ensure images display correctly
- [ ] Optimize image file sizes (compress without losing quality)

---

## Current Placeholders

The landing page currently shows **gray placeholder boxes** with the image filenames. These will be replaced when you add the actual screenshot images.

**Placeholder locations in the app:**
1. **Browse Services** - After "How It Works" Step 1 text
2. **Provider Profile** - After "How It Works" Step 2 text
3. **Booking & Chat** - After "How It Works" Step 3 text

---

## Need Help?

If you need assistance with:
- Taking screenshots on specific devices
- Editing images
- Creating mockups
- Optimizing file sizes

Just let me know and I can provide more specific guidance!
