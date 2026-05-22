# Quickstart Guide: Flutter Web Deployment

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## Prerequisites

Before starting development:

1. **Flutter SDK**: 3.22.3-stable (managed via asdf, see `.tool-versions`)
2. **Browser**: Chrome/Edge (for testing and DevTools)
3. **Backend API**: Essentiel data service endpoint (provided by team, see [Backend Setup](#backend-setup))
4. **Git**: Branch `002-flutter-web-deployment` checked out
5. **Internet**: Required for backend API access and testing

---

## Quick Start (5 minutes)

### 1. Enable Flutter Web Support

```bash
# Enable web platform for this project
flutter create . --platforms=web
```

**Expected output**: Creates `web/` directory with `index.html`, `manifest.json`, and icon placeholders.

### 2. Verify Web Files Created

```bash
ls -la web/
```

**Expected files**:
- `index.html` — HTML template
- `manifest.json` — PWA manifest
- `favicon.png` — Default favicon
- `icons/` — Icon directory (create if missing)

### 3. Run Development Server

```bash
# Run with development environment (fake credentials)
flutter run -d chrome

# Or specify device explicitly
flutter run -d web-server --web-port=8080
```

**Expected**: Browser opens to `http://localhost:<port>/`, app loads with dev environment.

### 4. Test Basic Functionality

- [ ] Cards display correctly
- [ ] Horizontal card list visible
- [ ] Shuffle button works (speed dial menu)
- [ ] Category filters apply
- [ ] Pull-to-refresh triggers reload (mobile browsers only)

---

## Development Workflow

### File Structure

```text
web/
├── index.html          # HTML template (customize <title>, <meta>)
├── manifest.json       # PWA manifest (customize name, icons)
├── favicon.png         # Browser tab icon
└── icons/
    ├── icon-192.png    # PWA install icon (required)
    └── icon-512.png    # PWA splash screen icon (required)
```

### Customizing the Web App

#### 1. Update PWA Manifest

Edit `web/manifest.json`:

```json
{
  "name": "Essentiel - Questions pour Partages",
  "short_name": "Essentiel",
  "description": "Jeu de cartes de questions pour groupes de partage Essentiel",
  "start_url": "/essentiel_app/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#009688",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

**Required changes**:
- `start_url`: Set to `/essentiel_app/` (GitHub Pages subdirectory)
- `icons`: Add 192x192 and 512x512 PNG icons

#### 2. Create PWA Icons

```bash
# Create icons directory if missing
mkdir -p web/icons

# Generate icons from existing app icon (example using ImageMagick)
convert assets/images/essentiel_logo.svg.png -resize 192x192 web/icons/icon-192.png
convert assets/images/essentiel_logo.svg.png -resize 512x512 web/icons/icon-512.png
```

**Alternative**: Use online tools like [PWA Asset Generator](https://github.com/onderceylan/pwa-asset-generator) or [RealFaviconGenerator](https://realfavicongenerator.net/)

#### 3. Update index.html Metadata

Edit `web/index.html`:

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Jeu de cartes de questions pour groupes de partage Essentiel">
  <title>Essentiel - Questions pour Partages</title>
  <link rel="manifest" href="manifest.json">
  <link rel="icon" type="image/png" href="favicon.png">
  <meta name="theme-color" content="#009688">
  <!-- Base href set by build process -->
  <base href="$FLUTTER_BASE_HREF">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

**Key points**:
- `lang="fr"` for French language
- `<base href>` dynamically set during build (don't modify manually)
- PWA meta tags for installability

---

## Backend Setup

### Development (Local Testing)

**Option A**: Use mock/test backend (recommended for initial development)

The team will provide a test backend endpoint:

```bash
# Configure in lib/environments/dev.dart
const API_BASE_URL = 'https://api-dev.essentiel.example.com';
```

**Option B**: Run local backend (if provided)

If the team provides a local backend setup:

```bash
# Start local backend (example, actual commands from team)
cd ../essentiel-backend
npm install
npm run dev

# Configure Flutter app to use localhost
# In lib/environments/dev.dart:
const API_BASE_URL = 'http://localhost:3000';
```

### Production (CI/CD)

**Backend URL Configuration**:

The production backend URL will be provided by the team and configured in the build:

```bash
# No secrets required - backend URL is public
# Configured in lib/environments/prod.dart or via build argument

# Example:
const API_BASE_URL = 'https://api.essentiel.example.com';
```

**No GitHub Secrets Needed**: Unlike the previous API key approach, the backend URL is public information and doesn't need secret management.

### Security Posture

**Web builds** (Backend API):
- ✅ Zero credentials embedded in client code
- ✅ Backend URL is public (not sensitive)
- ✅ Backend handles all Google Sheets authentication server-side
- ✅ Clean security boundary between client and data source
- ✅ No credential exposure risk in browser devtools

**Mobile builds** (Service Account):
- ✅ Credentials embedded in compiled binary (not readable by users)
- ✅ Follows Google's recommended practices for mobile apps
- ✅ Can optionally migrate to backend API later for consistency

**Rationale**: See [research.md](./research.md) for detailed security analysis. Backend proxy eliminates all credential exposure in web builds while maintaining mobile app's direct access pattern.

---

## Building for Production

### Local Production Build

```bash
# Build with production environment and PWA support
flutter build web \
  --release \
  --base-href "/essentiel_app/" \
  --pwa-strategy offline-first \
  --tree-shake-icons \
  --wasm

# Output directory
ls -la build/web/
```

**Build flags**:
- `--release`: Minified, optimized build
- `--base-href "/essentiel_app/"`: GitHub Pages subdirectory path
- `--pwa-strategy offline-first`: Enable offline caching
- `--tree-shake-icons`: Remove unused icons (reduces bundle size)
- `--wasm`: Compile to WebAssembly (better performance)

**Output**:
- `build/web/`: Deployable static site
- Total size: ~2-3 MB (compressed)

### Test Production Build Locally

```bash
# Serve build directory with local HTTP server
cd build/web
python3 -m http.server 8000

# Open browser to http://localhost:8000
```

**Test checklist**:
- [ ] App loads without errors
- [ ] Service worker registers (check DevTools → Application → Service Workers)
- [ ] PWA installable (install prompt appears on supported browsers)
- [ ] Offline mode works (DevTools → Network → Offline checkbox)
- [ ] All features functional (cards, shuffle, filters, refresh)

---

## CI/CD Deployment

### GitHub Actions Workflow

Create `.github/workflows/deploy-web.yml`:

```yaml
name: Deploy Flutter Web to GitHub Pages

on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.3'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      - name: Build and deploy to GitHub Pages
        uses: bluefireteam/flutter-gh-pages@v9
        with:
          baseHref: /essentiel_app/
          compileToWasm: true
```

**Setup GitHub Pages**:

1. Repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` (auto-created by action)
4. Folder: `/ (root)`
5. Save

**First deployment**:
- Push to `main` branch triggers workflow
- Wait ~5 minutes for build + deployment
- Visit `https://lemra-org.github.io/essentiel_app/`

**Subsequent deployments**:
- Every commit to `main` auto-deploys
- Cached builds complete in ~2 minutes

---

## Testing

### Browser Compatibility Testing

Test on minimum supported versions:

| Browser | Version | Platform |
|---------|---------|----------|
| Chrome | 120+ | Windows, macOS, Linux |
| Firefox | 121+ | Windows, macOS, Linux |
| Safari | 17.2+ | macOS, iOS |
| Edge | 120+ | Windows |

**Testing checklist per browser**:
- [ ] App loads without console errors
- [ ] Cards display correctly
- [ ] Touch gestures work (mobile browsers)
- [ ] Mouse interactions work (desktop browsers)
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Offline mode works after initial load
- [ ] PWA installable

### Responsive Design Testing

Test at these breakpoints:

| Size | Width | Device Example | Focus Area |
|------|-------|----------------|------------|
| Mobile (portrait) | 320px | iPhone SE | Touch targets, readability |
| Mobile (landscape) | 667px | iPhone 8 landscape | Horizontal card list |
| Tablet (portrait) | 768px | iPad | Layout adaptation |
| Tablet (landscape) | 1024px | iPad landscape | Multi-column potential |
| Desktop | 1920px | Full HD monitor | Content constraints, hover states |
| 4K | 3840px | 4K monitor | Scaling, no excessive whitespace |

**Chrome DevTools**:
```text
F12 → Toggle device toolbar → Responsive mode → Enter width
```

### Offline Testing

1. Load app in Chrome
2. Open DevTools (F12)
3. Navigate to **Application** → **Service Workers**
4. Verify service worker registered and activated
5. Navigate to **Network** tab
6. Check **Offline** checkbox
7. Refresh page
8. Verify:
   - [ ] App loads from cache
   - [ ] Cards display (cached data)
   - [ ] UI functional except refresh (network required)
   - [ ] Appropriate offline message shown

### Performance Testing

**Lighthouse audit**:

```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Run audit on deployed site
lighthouse https://lemra-org.github.io/essentiel_app/ \
  --output html \
  --output-path ./lighthouse-report.html

# Open report
open lighthouse-report.html
```

**Target scores**:
- Performance: ≥90
- Accessibility: ≥90
- Best Practices: ≥90
- SEO: ≥90
- PWA: Installable

---

## Troubleshooting

### Issue: Blank Screen on Load

**Symptoms**: Browser shows blank white screen, no errors in console.

**Causes**:
1. Incorrect base href (assets fail to load)
2. Service worker caching old version

**Solutions**:

```bash
# 1. Verify base href in build
grep "base href" build/web/index.html
# Should show: <base href="/essentiel_app/">

# 2. Clear service worker cache
# In browser DevTools → Application → Storage → Clear site data

# 3. Rebuild with correct base href
flutter clean
flutter build web --release --base-href "/essentiel_app/"
```

### Issue: Backend API Connection Error

**Symptoms**: Console error `Failed to load resource: net::ERR_CONNECTION_REFUSED` or similar network errors

**Causes**:
1. Backend API URL incorrect in environment config
2. Backend service is down or unreachable
3. CORS headers not configured on backend

**Solutions**:

```bash
# 1. Verify backend URL is correct
# Check lib/environments/dev.dart or prod.dart
grep "API_BASE_URL" lib/environments/*.dart

# 2. Test backend directly in browser
curl https://api.essentiel.example.com/api/categories

# 3. Check CORS headers in browser DevTools → Network tab
# Response should include:
# Access-Control-Allow-Origin: https://lemra-org.github.io

# 4. Use cached data fallback if backend is temporarily down
# Web app should show cached cards if available
```

**Contact team if**:
- Backend consistently returns 5xx errors
- CORS headers missing from backend responses
- Backend URL needs to be changed

### Issue: PWA Not Installable

**Symptoms**: Install prompt doesn't appear on Chrome mobile.

**Checklist**:
- [ ] HTTPS enabled (required for PWA)
- [ ] `manifest.json` valid and linked in `index.html`
- [ ] Icons 192x192 and 512x512 present
- [ ] `display: "standalone"` in manifest
- [ ] Service worker registered
- [ ] App visited at least twice with 5 minutes between visits

**Debug**:

```text
Chrome DevTools → Application → Manifest
# Check for errors/warnings
```

### Issue: Shake Gesture Not Working

**Expected**: Shake gesture only works on mobile browsers with motion sensors.

**Solution**: Always provide shuffle button fallback (already in speed dial menu). Test on:
- ✅ iOS Safari (requires permission prompt)
- ✅ Chrome Android (works automatically)
- ❌ Desktop browsers (no motion sensors, button only)

### Issue: localStorage Data Lost

**Symptoms**: Category filters reset on each load.

**Causes**:
1. Development server using random port (each port = different origin)
2. User cleared browser cache
3. Incognito/private browsing mode

**Solutions**:

```bash
# 1. Use fixed port for development
flutter run -d web-server --web-port=8080

# 2. Accept that cache clears lose data (expected behavior)
# 3. Document in user guide: "Clearing browser cache resets preferences"
```

---

## Performance Optimization

### Reduce Bundle Size

```bash
# Analyze bundle size
flutter build web --analyze-size

# Look for large dependencies in output
# Consider lazy loading or alternatives for large packages
```

**Common optimizations**:
- Use `--tree-shake-icons` (removes unused Material/Cupertino icons)
- Optimize images (compress PNGs, use WebP for photos)
- Enable `--wasm` compilation (smaller bundle than dart2js)
- Remove unused dependencies from `pubspec.yaml`

### Improve Load Time

**Image optimization**:

```dart
// Use cacheWidth/cacheHeight to downsample images
Image.asset(
  'assets/images/essentiel_logo.svg.png',
  cacheWidth: 192,  // Don't load full resolution for small displays
)
```

**Lazy loading**:

```dart
// Defer non-critical imports
import 'package:flutter/material.dart' deferred as material;

// Load when needed
material.loadLibrary().then((_) => showDialog(...));
```

### Service Worker Caching

The default Flutter service worker uses cache-first for static assets. To customize:

1. Build with `--pwa-strategy none` to skip auto-generated worker
2. Create custom `web/flutter_service_worker.js`
3. Use [Workbox](https://developer.chrome.com/docs/workbox/) for advanced caching strategies

**Example** (network-first for API requests):

```javascript
workbox.routing.registerRoute(
  /^https:\/\/sheets\.googleapis\.com/,
  new workbox.strategies.NetworkFirst()
);
```

---

## Next Steps

After completing quickstart:

1. **Review [plan.md](./plan.md)** for full implementation plan
2. **Read [research.md](./research.md)** for technical decisions and rationale
3. **Check [contracts/web-api.md](./contracts/web-api.md)** for API contracts
4. **Run `/speckit-tasks`** to generate implementation task breakdown
5. **Start implementation** on branch `002-flutter-web-deployment`

---

## Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Build and release a web app](https://docs.flutter.dev/deployment/web)
- [Progressive Web Apps in Flutter](https://docs.flutter.dev/platform-integration/web/progressive-web-apps)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Web.dev PWA Guide](https://web.dev/progressive-web-apps/)
- [Lighthouse Documentation](https://developer.chrome.com/docs/lighthouse/)

---

## Summary Checklist

Before starting implementation:

- [ ] Flutter 3.22.3-stable installed
- [ ] `web/` directory created via `flutter create . --platforms=web`
- [ ] PWA manifest customized with app name and icons
- [ ] Google Sheets API key created and restricted
- [ ] GitHub secret configured for CI/CD
- [ ] Local dev server tested (`flutter run -d chrome`)
- [ ] Production build tested locally
- [ ] GitHub Pages enabled in repository settings
- [ ] Browser compatibility test plan ready

**Estimated setup time**: 30-60 minutes (including Google Cloud configuration)
