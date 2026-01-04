# Deploy HireMeBuddy Landing Page to IONOS

## 📋 Prerequisites

1. IONOS account with hosting plan
2. Domain `hiremebuddy.app` pointed to IONOS nameservers
3. FTP/SFTP credentials from IONOS

## 🚀 Deployment Steps

### Step 1: Get IONOS FTP Credentials

1. Log in to [IONOS Control Panel](https://my.ionos.com)
2. Go to **Hosting** → **Your Package**
3. Find FTP Access details:
   - **FTP Server**: example.ionos-server.com
   - **Username**: your-username
   - **Password**: your-password
   - **Port**: 21 (FTP) or 22 (SFTP - recommended)

### Step 2: Prepare Files for Upload

From: `c:\Users\keena\Projects\HireMeBuddy-v1.0.0\web\landing\`

Files to upload:
```
landing/
├── index.html
├── styles.css
├── script.js
└── assets/
    ├── app-screenshot.png
    ├── provider-profile.png
    ├── client-dashboard.png
    ├── google-play-badge.png
    ├── app-store-badge.png
    └── qr-code.png
```

### Step 3: Upload via FileZilla (Recommended)

#### A. Install FileZilla
Download from: https://filezilla-project.org/

#### B. Connect to IONOS
1. Open FileZilla
2. Enter credentials:
   - **Host**: sftp://your-ionos-server.com (use SFTP for security)
   - **Username**: your-username
   - **Password**: your-password
   - **Port**: 22
3. Click **Quickconnect**

#### C. Upload Files
1. Navigate to your domain folder (usually `/` or `/hiremebuddy.app/`)
2. Look for the web root directory:
   - Common paths: `/`, `/htdocs/`, `/public_html/`, `/www/`
3. Upload all files from `web/landing/` to the web root
4. Ensure `index.html` is in the root (not in a subdirectory)

**Expected structure on server:**
```
/hiremebuddy.app/  (or web root)
├── index.html
├── styles.css
├── script.js
└── assets/
    └── (all images)
```

### Step 4: Configure SSL Certificate (HTTPS)

#### Option A: IONOS SSL Certificate (Included)
1. Go to IONOS Control Panel
2. Navigate to **Hosting** → **SSL**
3. Enable **Let's Encrypt SSL** (FREE)
4. Wait 15-30 minutes for activation
5. HTTPS will be automatic: https://hiremebuddy.app

#### Option B: Force HTTPS Redirect
Create `.htaccess` file in web root:

```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Remove www prefix (optional)
RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://%1/$1 [R=301,L]
```

Upload `.htaccess` to same directory as `index.html`

### Step 5: Optimize Performance

#### A. Enable Gzip Compression
Add to `.htaccess`:

```apache
# Enable Gzip compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
</IfModule>
```

#### B. Enable Browser Caching
Add to `.htaccess`:

```apache
# Cache static assets for 1 year
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/webp "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
</IfModule>
```

#### C. Complete `.htaccess` File
Create this file in your web root:

```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Remove www prefix
RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://%1/$1 [R=301,L]

# Enable Gzip compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
</IfModule>

# Browser caching
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/webp "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
</IfModule>

# Security headers
<IfModule mod_headers.c>
  Header set X-Content-Type-Options "nosniff"
  Header set X-Frame-Options "SAMEORIGIN"
  Header set X-XSS-Protection "1; mode=block"
</IfModule>
```

### Step 6: Verify Deployment

1. Visit: https://hiremebuddy.app
2. Check:
   - ✅ Page loads correctly
   - ✅ Images display
   - ✅ Mobile responsive
   - ✅ HTTPS active (green padlock)
   - ✅ All links work

### Step 7: Update DNS (If Not Done)

If your domain isn't pointing to IONOS yet:

1. Go to your domain registrar
2. Update nameservers to IONOS:
   ```
   ns1.ionos.com
   ns2.ionos.com
   ```
3. Wait 24-48 hours for DNS propagation

## 🔧 Alternative Upload Methods

### Method 1: IONOS File Manager (Web-based)
1. Log in to IONOS Control Panel
2. Go to **Hosting** → **File Manager**
3. Navigate to web root
4. Click **Upload** and select all files
5. Ensure proper folder structure

### Method 2: WinSCP (Windows SFTP Client)
1. Download: https://winscp.net/
2. Connect using IONOS SFTP credentials
3. Drag & drop files from left (local) to right (server)

### Method 3: Command Line (PowerShell/SFTP)
```powershell
# Install PSFTP (PuTTY SFTP client)
# Then connect:
psftp your-username@your-ionos-server.com

# Upload files:
cd /web/root/path
put index.html
put styles.css
put script.js
mkdir assets
cd assets
mput assets/*
```

## 📊 Post-Deployment Checklist

- [ ] Site loads at https://hiremebuddy.app
- [ ] SSL certificate is active (HTTPS)
- [ ] All images display correctly
- [ ] Mobile responsive works
- [ ] Navigation links work
- [ ] Download buttons are visible
- [ ] Page loads in < 3 seconds
- [ ] No console errors (F12 DevTools)
- [ ] Social media links updated
- [ ] Google Analytics added (if desired)
- [ ] Contact email is correct

## 🚨 Troubleshooting

### Issue: Page shows IONOS parking page
**Solution**: Ensure files are in correct web root directory

### Issue: 404 errors for CSS/JS
**Solution**: Check file paths are correct (no `/web/landing/` prefix)

### Issue: Images not loading
**Solution**: Verify `assets/` folder uploaded correctly

### Issue: No HTTPS
**Solution**: Enable SSL in IONOS Control Panel → Hosting → SSL

### Issue: www.hiremebuddy.app not working
**Solution**: Add `.htaccess` redirect (see Step 5)

## 📱 Testing

Test on multiple devices:
- Desktop (Chrome, Firefox, Safari, Edge)
- Mobile (iOS Safari, Android Chrome)
- Tablet

Use these tools:
- PageSpeed Insights: https://pagespeed.web.dev/
- SSL Test: https://www.ssllabs.com/ssltest/
- Mobile-Friendly Test: https://search.google.com/test/mobile-friendly

## 🔄 Future Updates

To update the site:
1. Edit files locally in `web/landing/`
2. Re-upload via FTP/SFTP
3. Clear browser cache (Ctrl+F5)

## 💡 IONOS-Specific Tips

1. **Web Root Path**: Usually `/` or `/htdocs/`
2. **PHP Support**: Available if you need contact forms later
3. **Email**: Set up hello@hiremebuddy.app in IONOS Email section
4. **Backups**: IONOS provides automatic backups
5. **Support**: Available 24/7 via IONOS Control Panel

## 📞 Need Help?

- IONOS Support: https://www.ionos.com/help
- FileZilla Guide: https://wiki.filezilla-project.org/
- .htaccess Generator: https://www.htaccessredirect.net/

---

**Your landing page is now live at https://hiremebuddy.app! 🎉**
