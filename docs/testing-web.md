# Web Testing Guide

This document provides comprehensive testing instructions for the Essentiel web application.

## Prerequisites

Before testing the web application, ensure you have:

1. **Flutter SDK** installed (see `.tool-versions` for version)
2. **Backend API** running (see [Backend Setup](#backend-setup))
3. **Modern browser** (Chrome 120+, Firefox 121+, Safari 17.2+, Edge 120+)

## Backend Setup

The web app requires the backend API to fetch cards and categories data. Choose one of these options:

### Option 1: Docker Compose (Recommended for Local Testing)

```bash
# From repository root
# Copy environment template
cp .env.example .env

# Edit .env with your Google Service Account credentials
# Required variables:
# - GOOGLE_SERVICE_ACCOUNT_JSON: Full JSON credentials
# - GOOGLE_SPREADSHEET_ID: Your spreadsheet ID

# Start both backend and frontend
docker compose -f compose.yaml -f compose-dev.yaml up --build

# Web app will be available at http://localhost:8080
```

### Option 2: Run Backend Separately

```bash
# Terminal 1: Start backend API
cd backend-api
export GOOGLE_SERVICE_ACCOUNT_JSON=$(cat service-account-dev.json)
go run cmd/server/main.go
# Backend runs on http://localhost:8080

# Terminal 2: Start Flutter web dev server
flutter run -d chrome
# Frontend runs on http://localhost:auto-assigned-port
```

## Running Tests

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test_file.dart

# Run with coverage
flutter test --coverage
```

### Web-Specific Manual Testing

After starting the web application (via Docker Compose or dev server), verify the following:

#### 1. Basic Functionality (User Story 1)
- [ ] App loads without errors
- [ ] Cards are displayed correctly with icons, categories, and colors
- [ ] Click "Tirer une carte" button to draw random cards
- [ ] Verify card switching animation (old card slides up, new card slides up from bottom)
- [ ] Open category filter menu (bottom-right speed dial)
- [ ] Toggle category filters and verify only selected categories appear
- [ ] Pull-to-refresh gesture reloads cards from backend

#### 2. Mobile Browser Experience (User Story 2)
Test on actual mobile devices or Chrome DevTools device emulation:

**iOS Safari**:
- [ ] Navigate to http://localhost:8080 (or deployed URL)
- [ ] Verify viewport fits without horizontal scroll
- [ ] Swipe left/right to scroll through horizontal card list
- [ ] Pull down to trigger refresh animation
- [ ] Tap menu button - verify all items are easily tappable
- [ ] Shake device - verify random card is drawn

**Chrome Mobile / Firefox Mobile**:
- [ ] Same tests as iOS Safari above
- [ ] Verify smooth touch responsiveness
- [ ] Check that font sizes are readable without zooming

**Testing with Chrome DevTools**:
```bash
# Start web app (via Docker Compose or dev server)
# Open Chrome DevTools (F12)
# Click device toolbar icon (Ctrl+Shift+M)
# Test with:
# - iPhone 12 Pro (390x844)
# - Pixel 5 (393x851)
# - Samsung Galaxy S20 (360x800)
```

#### 3. Desktop & Large Screen (User Story 3)
**Desktop Chrome/Firefox/Edge**:
- [ ] Open at 1920x1080 resolution
- [ ] Verify layout uses available space without excessive whitespace
- [ ] Resize window from mobile-width to desktop-width
- [ ] Verify layout adapts smoothly
- [ ] Hover over "Tirer une carte" button - cursor changes to pointer
- [ ] Hover over speed dial menu items - cursor changes to pointer
- [ ] Hover over category chips - cursor changes to pointer
- [ ] Click category chips with mouse

**Tablet (Landscape)**:
- [ ] Test at 1024x768 (iPad landscape)
- [ ] Verify more cards visible in horizontal scroll than mobile portrait

#### 4. Animation Testing
- [ ] **Initial load**: Verify deck animation (20 cards fan out and fade)
- [ ] **Deck-to-list transition**: Smooth fade between deck and horizontal scrollbar
- [ ] **Card switching**: Simultaneous slide (old up to top, new up from bottom)
- [ ] **No card selected**: Blurred logo displayed in center with shake animation overlay (mobile only)
- [ ] **Shuffle button**: Same deck animation as initial load

#### 5. Responsive Breakpoints
Test at these specific widths to verify breakpoint behavior:

```bash
# Mobile: < 600px
# Test at: 375px, 414px, 393px (common phone widths)

# Tablet: 600-1200px
# Test at: 768px, 1024px (common tablet widths)

# Desktop: > 1200px
# Test at: 1366px, 1920px, 2560px (common desktop widths)
```

#### 6. Performance Testing
- [ ] **Load time**: App loads within 5 seconds on broadband
- [ ] **Cached response**: Cards load in <100ms after first fetch
- [ ] **Fresh fetch**: Cards load in <2s from backend
- [ ] **Animation smoothness**: 60fps for all transitions (check DevTools Performance)
- [ ] **Memory usage**: No memory leaks after 20+ card switches (check DevTools Memory)

#### 7. Offline Behavior
```bash
# Open app while online
# Open Chrome DevTools > Network tab
# Set throttling to "Offline"
# Verify graceful error handling
```

- [ ] Offline message displayed when backend unreachable
- [ ] Previously loaded cards remain visible (if cached)
- [ ] Network reconnect restores functionality

#### 8. Cross-Browser Testing

**Required Test Matrix**:

| Browser | Platform | Minimum Version | Test Status |
|---------|----------|-----------------|-------------|
| Chrome | Windows | 120+ | [ ] |
| Chrome | macOS | 120+ | [ ] |
| Chrome | Linux | 120+ | [ ] |
| Firefox | Windows | 121+ | [ ] |
| Firefox | macOS | 121+ | [ ] |
| Safari | macOS | 17.2+ | [ ] |
| Safari | iOS | 17.2+ | [ ] |
| Edge | Windows | 120+ | [ ] |
| Chrome Mobile | Android | Latest | [ ] |
| Firefox Mobile | Android | Latest | [ ] |

**Test Script for Each Browser**:
1. Load app URL
2. Draw 3 random cards
3. Filter by 2 categories
4. Refresh cards
5. Switch between mobile/tablet/desktop viewport (where applicable)
6. Verify animations are smooth
7. Check console for errors

## Automated Testing (Future Enhancement)

For CI/CD integration, consider adding:

```bash
# Integration tests (planned)
flutter drive --driver=test_driver/integration_driver.dart \
  --target=test_driver/app.dart -d web-server

# Visual regression tests (planned)
# Use tools like Percy or Chromatic for screenshot comparison
```

## Troubleshooting

### Backend Connection Issues
**Symptom**: Cards fail to load, "Network error" displayed

**Solutions**:
1. Verify backend is running: `curl http://localhost:8080/healthz`
2. Check backend logs: `docker compose logs backend-api`
3. Verify CORS configuration in backend allows your frontend origin
4. Check browser console for CORS errors

### Animation Issues
**Symptom**: Animations stuttering or not displaying

**Solutions**:
1. Check browser performance (close other tabs)
2. Verify GPU acceleration enabled in browser settings
3. Test in incognito mode (disable extensions)
4. Check Flutter web rendering mode: `flutter run -d chrome --web-renderer html` or `--web-renderer canvaskit`

### Mobile Touch Issues
**Symptom**: Touch gestures not recognized

**Solutions**:
1. Verify viewport meta tag in `web/index.html`
2. Test on actual device (emulators may have different touch behavior)
3. Check for JavaScript console errors blocking event handlers

### Layout Issues
**Symptom**: Cards too large/small, excessive whitespace

**Solutions**:
1. Check browser zoom level (should be 100%)
2. Verify responsive breakpoints with DevTools
3. Check if browser window is at expected dimensions
4. Clear browser cache and hard reload (Ctrl+Shift+R)

## Reporting Issues

When reporting test failures, include:
1. **Browser & Version**: Chrome 120.0.6099.130
2. **Platform & OS**: Windows 11 / macOS 14.2 / iOS 17.2
3. **Viewport Size**: 375x667 (iPhone SE)
4. **Steps to Reproduce**: Exact sequence of actions
5. **Expected Behavior**: What should happen
6. **Actual Behavior**: What actually happened
7. **Screenshots**: Especially for layout/animation issues
8. **Console Logs**: Browser DevTools console output
9. **Network Logs**: DevTools Network tab (for API issues)

## Test Checklist Summary

Use this checklist for comprehensive testing before release:

- [ ] All unit tests pass (`flutter test`)
- [ ] Backend API connectivity verified
- [ ] User Story 1 scenarios complete (basic functionality)
- [ ] User Story 2 scenarios complete (mobile browsers)
- [ ] User Story 3 scenarios complete (desktop/tablet)
- [ ] All animations smooth and correct
- [ ] All responsive breakpoints tested
- [ ] Performance metrics within targets (5s load, <100ms cached)
- [ ] Cross-browser matrix complete (Chrome, Firefox, Safari, Edge)
- [ ] Mobile device testing complete (iOS Safari, Chrome Mobile)
- [ ] Offline behavior verified
- [ ] No console errors or warnings
- [ ] Accessibility checks passed (keyboard navigation, screen reader)
- [ ] Security checks passed (HTTPS, no credentials exposed)

## Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Chrome DevTools Guide](https://developer.chrome.com/docs/devtools/)
- [Web.dev Testing Best Practices](https://web.dev/testing/)
- [MDN Browser Testing Guide](https://developer.mozilla.org/en-US/docs/Learn/Tools_and_testing/Cross_browser_testing)
