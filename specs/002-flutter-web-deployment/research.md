# Research Findings: Flutter Web Deployment

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## Critical Blockers Identified

### 1. Google Sheets API CORS Limitation

**Decision**: Use secure backend proxy to fetch Google Sheets data

**Rationale**:
- Google Sheets API **does not support CORS** for direct browser requests (lacks `Access-Control-Allow-Origin` headers)
- Embedding Service Account credentials in Flutter web builds is **explicitly prohibited** by Google's security best practices
- Service Account private keys would be exposed in browser JavaScript, creating credential leakage vulnerabilities
- API keys, while client-safe, still expose quota limits and can be abused if extracted from client code
- Backend proxy provides clean security boundary: **zero credentials in web builds**

**Solution**:
- **Backend API** provided by project team handles Google Sheets authentication server-side
- Backend exposes simple REST endpoints for categories and questions
- Web app calls backend API (no Google Sheets SDK or credentials needed)
- Mobile app can optionally use same backend or continue direct Google Sheets access
- Backend can implement caching, rate limiting, and data transformation

**Alternatives Considered**:
- **API Keys in web builds**: Still exposes keys to quota abuse, requires domain restrictions
- **Service Account in web**: Security violation, credentials exposed in browser
- **Google Apps Script**: Introduces another deployment target and CORS complexity
- **Published CSV export**: Unreliable, may still hit CORS, loses API features

**Implementation Impact**: 
- Web app requires backend API endpoint configuration (URL in environment)
- No Google Sheets SDK needed in web builds (smaller bundle size)
- Mobile app can continue using Service Account or migrate to backend for consistency

---

### 2. Device Shake Gesture Web Alternative

**Decision**: Implement progressive enhancement with button fallback

**Rationale**:
- Device Motion API has only 88% browser compatibility (primarily mobile browsers)
- Desktop browsers lack motion sensors entirely
- iOS Safari requires HTTPS + explicit user permission via button click (not automatic)
- Existing Flutter shake packages (`shake`, `shake_gesture`) target Android/iOS only, no web support
- Accessibility concerns: motion-based interactions exclude users with disabilities

**Solution**:
- Use `kIsWeb` constant from `package:flutter/foundation.dart` for platform detection
- **Mobile web**: Implement shake via JavaScript interop with DeviceMotionEvent API
  - Calculate acceleration magnitude from x/y/z axes
  - Trigger on spikes >15-20 m/s² (gravity baseline is ~9.8)
  - Request permission on first user tap
- **Desktop/fallback**: Always show shuffle button (FloatingActionButton or menu item)
- **Recommended**: Make shuffle button visible universally for discoverability, even when shake works

**Alternatives Considered**:
- **shake.js library**: Third-party dependency, adds bundle size
- **Shake-only (no fallback)**: Excludes desktop users and accessibility requirements
- **Custom gesture (double-click, swipe)**: Less intuitive than existing shake behavior

**Implementation Impact**: Minimal - shuffle button already exists in speed dial menu, just needs to remain visible on web.

---

## Responsive Design Strategy

**Decision**: Use LayoutBuilder for component-level adaptation + MediaQuery for screen-level decisions

**Rationale**:
- `LayoutBuilder` provides parent-constraint-based sizing, ideal for reusable widgets
- `MediaQuery.sizeOf` better for screen-level decisions (orientation, navigation pattern switching)
- Standard breakpoints: Mobile <600px, Tablet 600-840px, Desktop >1200px
- Large screens (>1200px) need content width constraints to prevent excessive text line lengths on 4K displays

**Best Practices**:
- Constrain card container widths on desktop using `ConstrainedBox + Center`
- Consider `GridView` for multi-column card layout above 840px (optional enhancement)
- Implement hover states with `MouseRegion` for desktop mouse interaction
- Use `FocusableActionDetector` for combined focus/hover/keyboard shortcuts
- Optimize images with `cacheWidth/cacheHeight` parameters (never load 4K images for thumbnails)

**Performance Considerations**:
- Use `--tree-shake-icons` build flag to reduce bundle size
- Images typically represent 60%+ of web payload, optimize aggressively
- Flutter 3.22 includes platform channel latency improvements

**Implementation Impact**: Moderate - requires responsive breakpoints and layout adaptation, but existing mobile-first design provides solid foundation.

---

## Local Storage & Offline Support

### shared_preferences Web Behavior

**Decision**: Use existing `shared_preferences` package for web builds

**Findings**:
- Full web support (your v2.1.0 is compatible)
- Uses browser `localStorage` (not sessionStorage or IndexedDB)
- Keys auto-prefixed with `flutter.` to prevent collisions
- ~5MB storage limit per origin (sufficient for category filters + card cache)
- Data persists across browser restarts
- Data **lost** on browser cache clear (acceptable tradeoff for web apps)

**Considerations**:
- Development: `flutter run` assigns random ports, each port = different origin = separate storage
- Production: Fixed domain (lemra-org.github.io/essentiel_app) ensures consistent storage
- Current usage (category filters + first-launch flags) fits comfortably within 5MB limit

**Migration Notes**: `SharedPreferences` API is legacy (v2.3.0+ introduced `SharedPreferencesAsync`), but current version works fine for this use case.

---

### Progressive Web App (PWA) Configuration

**Decision**: Enable PWA with offline-first caching strategy

**Findings**:
- Flutter **auto-generates** `manifest.json` and `flutter_service_worker.js` when web support is enabled
- Project currently has **no web support** (no `web/` directory exists yet)
- Build flag: `flutter build web --pwa-strategy offline-first` (recommended)
- Service worker uses cache-first strategy for static assets by default

**Implementation Checklist**:
1. Enable Flutter web: `flutter create . --platforms=web`
2. Customize `web/manifest.json` (name, icons, theme_color, display mode)
3. Build with PWA strategy: `flutter build web --pwa-strategy offline-first`
4. Test offline mode:
   - Serve `build/web/` with local HTTP server: `python -m http.server 8000`
   - Chrome DevTools → Application → Service Workers → toggle "offline"
5. Configure cache invalidation via `serviceWorkerVersion` parameter in `index.html`

**Browser Compatibility**: PWAs work across modern browsers (Chrome, Firefox, Safari, Edge last 2 versions)

**Implementation Impact**: Low - Flutter handles most PWA setup automatically, requires minimal configuration.

---

## GitHub Pages Deployment

**Decision**: Use `bluefireteam/flutter-gh-pages@v9` GitHub Action

**Rationale**:
- Most popular Flutter web deployment action (maintained, well-documented)
- Handles base href configuration automatically
- Built-in caching reduces build time from ~5min to ~2min on subsequent runs
- Supports WebAssembly compilation for better performance

**Workflow Configuration**:

```yaml
name: Deploy Web
on:
  push:
    branches: [main]
permissions:
  contents: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: bluefireteam/flutter-gh-pages@v9
        with:
          baseHref: /essentiel_app/
          compileToWasm: true
```

**Base Href Requirement**: For `lemra-org.github.io/essentiel_app`, must use `--base-href "/essentiel_app/"` (must start/end with `/`). Without it, assets fail to load from subdirectories.

**Production Build Flags**:
- `--release`: Minified, tree-shaken, dart2js compiled (default)
- `--tree-shake-icons`: Removes unused icons, reduces bundle size
- `--wasm`: Enables WebAssembly for better performance (recommended for 2026)
- `--pwa-strategy offline-first`: Generates service worker with offline-first caching

**Repository Configuration**: Enable write permissions in Settings → Actions → General → Workflow permissions

**Routing**: GitHub Pages serves static files. Use hash-based routing (`#/`) or 404.html fallback for client-side routing.

**Implementation Impact**: Low - standard GitHub Action integration, follows existing CI/CD patterns.

---

## Environment Separation for Web

**Decision**: Use backend API for web builds, keep Service Account for mobile (optional migration later)

**Security Posture**:
- **Web builds**: Call secure backend API (zero credentials in client)
  - Backend URL configured in environment
  - No Google Sheets credentials or API keys embedded
  - Backend handles authentication, rate limiting, caching
  - Clean separation of concerns
- **Mobile builds**: Continue using Service Account credentials (secure in compiled apps)
  - Credentials not exposed to users
  - Follows Google's recommended practices
  - Can optionally migrate to backend API later for consistency

**Implementation**:
- Add `kIsWeb` detection in environment configuration
- Load backend API URL for web, Service Account for mobile
- Backend API URL is public (no secrets needed)
- Mobile can optionally use backend instead of direct Sheets access

**Risk Assessment**: Minimal risk - no credentials in web builds, backend controls access

---

## Summary of Decisions

| Area | Decision | Risk Level | Implementation Effort |
|------|----------|------------|----------------------|
| Google Sheets Access | Backend API proxy (provided by team) | ✅ Low | Low (backend provided) |
| Shake Gesture | Progressive enhancement with button fallback | ✅ Low | Low |
| Responsive Design | LayoutBuilder + MediaQuery with breakpoints | ✅ Low | Medium |
| Local Storage | shared_preferences → localStorage | ✅ Low | None (existing) |
| PWA/Offline | offline-first caching strategy | ✅ Low | Low |
| CI/CD Deployment | bluefireteam/flutter-gh-pages action | ✅ Low | Low |
| Environment Config | Backend URL for web, Service Account for mobile | ✅ Low | Low |

**All unknowns resolved. Ready for Phase 1: Design & Contracts.**
