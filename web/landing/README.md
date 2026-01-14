# HireMeBuddy Landing Page

Modern, responsive landing page for the HireMeBuddy service marketplace app.

## 📁 Files

```
web/landing/
├── index.html              # Main landing page
├── privacy-policy.html     # Privacy policy
├── terms.html              # Terms of service
├── safety.html             # Safety guidelines
├── support.html            # Support center
├── styles.css              # Stylesheet
├── script.js               # JavaScript
└── assets/                 # Images (add your own)
```

## 🚀 Deployment to Firebase

### Option 1: Deploy via Firebase CLI

```bash
# From project root
firebase deploy --only hosting:landing
```

### Option 2: Deploy to IONOS (hiremebuddy.app)

Upload these files via FTP/SFTP to your IONOS web root:
- All `.html` files
- `styles.css`
- `script.js`
- `assets/` folder

## 📧 Email Addresses Used

The landing page uses these email addresses:
- **General:** info@hiremebuddy.app
- **Safety:** safety@hiremebuddy.app
- **Privacy:** privacy@hiremebuddy.app
- **Legal:** legal@hiremebuddy.app

Make sure these are configured in your IONOS email settings.

## 🔗 Footer Links

All footer links now point to actual pages:
- Privacy Policy → `/privacy-policy.html`
- Terms of Service → `/terms.html`
- Safety Guidelines → `/safety.html`
- Support Center → `/support.html`

## 🎨 Customization

### Update Colors
Edit CSS variables in `styles.css`:
```css
:root {
    --primary: #14B8A6;
    --secondary: #06B6D4;
    /* ... */
}
```

### Update Content
All text is in the HTML files - search and replace as needed.

### Add Real Images
Replace placeholder screenshots in `index.html`:
1. Add images to `assets/` folder
2. Update image sources in HTML

## 📱 Google Play Store Link

Update this link throughout the site:
```
https://play.google.com/store/apps/details?id=com.hiremebuddy.app
```

Replace with your actual Play Store URL when published.

## ✅ Pre-Deployment Checklist

- [ ] Update all email addresses if needed
- [ ] Add real app screenshots to assets/
- [ ] Update Google Play Store link
- [ ] Test all navigation links
- [ ] Test on mobile devices
- [ ] Verify privacy policy is current
- [ ] Test contact forms/modals

## 🌐 Live Site

After deployment, the site will be available at:
- **Firebase:** https://hiremebuddy-850a8.web.app
- **Custom Domain:** https://hiremebuddy.app

---

**Made with ❤️ in Namibia**
