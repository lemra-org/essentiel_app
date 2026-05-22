# Quickstart: Pull-to-Refresh Question Data

**Feature**: 001-pull-to-refresh  
**Date**: 2026-05-22  
**Target Users**: Developers, QA testers

## Overview

This guide provides step-by-step instructions for testing the pull-to-refresh feature in the Essentiel app. Follow this guide to validate that manual data refresh works correctly in various scenarios.

## Prerequisites

### Development Environment

- Flutter 3.22.3-stable installed (via `asdf install` from project root)
- Android SDK and emulator configured, OR physical Android device connected
- Google Service Account credentials configured (dev or prod environment)
- Network connectivity for initial test cases

### Verify Setup

```bash
# From project root
flutter doctor          # Ensure no critical issues
flutter pub get         # Install dependencies
flutter analyze         # Should pass with zero issues
```

## Quick Start: Basic Refresh Test

### 1. Launch the App

```bash
# Run in development mode (uses dev.dart with fake credentials)
flutter run

# OR run with production environment (requires real credentials)
flutter run -t lib/environments/prod.dart
```

Wait for the app to load and display the question list screen.

### 2. Perform Pull-to-Refresh

1. On the main game screen showing questions
2. **Pull down** on the question list (swipe down from top)
3. **Observe**: Loading spinner appears
4. **Wait**: Spinner disappears after 1-5 seconds
5. **Verify**: Questions list updates (check timestamp or content changes)

**Expected Result**: ✅ Refresh completes successfully, fresh data loaded

### 3. Verify Cache Update

1. Close the app completely (swipe away from recent apps)
2. **Enable airplane mode** on the device
3. Relaunch the app
4. **Observe**: App loads with cached data (questions visible offline)

**Expected Result**: ✅ Cached data from last refresh persists offline

---

## Test Scenarios

### Scenario 1: Successful Refresh (Online)

**Purpose**: Verify basic pull-to-refresh functionality

**Steps**:
1. Ensure device has network connectivity
2. Launch app and navigate to question list
3. Pull down to refresh
4. Observe loading indicator
5. Wait for completion

**Expected**:
- ✅ Loading spinner appears immediately
- ✅ Refresh completes within 5 seconds (normal network)
- ✅ Questions list updates with latest data from Google Sheets
- ✅ No error messages displayed
- ✅ App remains responsive during refresh

**Validation**:
- Modify a question in the Google Spreadsheet
- Perform pull-to-refresh in app
- Verify modified question appears

---

### Scenario 2: Offline Refresh (No Network)

**Purpose**: Verify graceful degradation when network unavailable

**Steps**:
1. Launch app with network connectivity (load initial cache)
2. **Enable airplane mode** or disable WiFi/mobile data
3. Pull down to refresh
4. Observe behavior

**Expected**:
- ✅ Loading spinner appears briefly
- ✅ Error toast displays in French: "Pas de connexion réseau. Veuillez vérifier votre connexion."
- ✅ Cached questions remain visible (no data loss)
- ✅ App does not crash or freeze
- ✅ User can continue using app normally

**Validation**:
- Count questions before refresh
- Perform offline refresh
- Verify same questions still displayed (cache preserved)

---

### Scenario 3: Network Loss During Refresh

**Purpose**: Verify robust error handling for mid-fetch failures

**Steps**:
1. Launch app with network connectivity
2. Pull down to refresh
3. **Immediately enable airplane mode** (during loading)
4. Observe behavior

**Expected**:
- ✅ Loading spinner appears
- ✅ Error toast displays: "Connexion perdue pendant le chargement."
- ✅ Cached questions preserved (no corruption)
- ✅ App remains stable

---

### Scenario 4: Concurrent Refresh Prevention

**Purpose**: Verify multiple rapid pull gestures don't cause issues

**Steps**:
1. Launch app with network connectivity
2. Pull down to refresh (start first refresh)
3. **Immediately** pull down again while first refresh is in progress
4. Repeat rapid pull gestures 3-5 times
5. Observe behavior

**Expected**:
- ✅ Only one refresh operation executes
- ✅ Subsequent pull gestures ignored while refresh in progress
- ✅ No duplicate network requests (check network logs)
- ✅ No race conditions or data corruption
- ✅ Single completion (one set of updates)

---

### Scenario 5: Slow Network Performance

**Purpose**: Verify refresh timeout and user experience on slow connections

**Setup**:
```bash
# Use Android Dev Tools to throttle network
# OR test on real device with poor signal
```

**Steps**:
1. Enable network throttling (slow 3G or slower)
2. Pull down to refresh
3. Wait for completion or timeout

**Expected**:
- ✅ Loading spinner remains visible during slow fetch
- ✅ App stays responsive (UI not frozen)
- ✅ User can navigate away from screen if desired
- ✅ Refresh completes or times out gracefully
- ✅ Appropriate error message if timeout occurs

---

### Scenario 6: Spreadsheet Permission Error

**Purpose**: Verify handling of Google Sheets access errors

**Setup**:
- Temporarily revoke service account permissions to spreadsheet
- OR use invalid spreadsheet ID in environment config

**Steps**:
1. Launch app (may show cached data or error on initial load)
2. Pull down to refresh
3. Observe behavior

**Expected**:
- ✅ Loading spinner appears
- ✅ Error toast displays: "Impossible d'accéder à la feuille de calcul."
- ✅ Cached data preserved (if any)
- ✅ App does not crash

**Cleanup**: Restore permissions after test

---

### Scenario 7: Malformed Spreadsheet Data

**Purpose**: Verify validation of fetched data

**Setup**:
- Temporarily modify Google Spreadsheet to have invalid data:
  - Empty category names
  - Questions referencing non-existent categories
  - Missing required columns

**Steps**:
1. Pull down to refresh
2. Observe behavior

**Expected**:
- ✅ Loading spinner appears
- ✅ Data validation fails
- ✅ Error toast displays: "Les données reçues sont invalides."
- ✅ Previous cached data preserved (not overwritten with invalid data)

**Cleanup**: Fix spreadsheet data after test

---

### Scenario 8: Rapid App Switching

**Purpose**: Verify refresh state handling when app backgrounded

**Steps**:
1. Launch app
2. Pull down to refresh (start refresh)
3. **Immediately** switch to another app (home screen or different app)
4. Wait 5 seconds
5. Return to Essentiel app

**Expected**:
- ✅ Refresh completes in background OR is safely cancelled
- ✅ App resumes to stable state
- ✅ No crashes or hangs
- ✅ Data integrity maintained

---

## Performance Benchmarks

### Refresh Timing

Measure refresh duration under various conditions:

| Network Condition | Expected Time | Acceptable Range |
|-------------------|---------------|------------------|
| WiFi (good signal) | 1-2 seconds | < 5 seconds |
| 4G/5G mobile | 2-3 seconds | < 5 seconds |
| 3G mobile | 3-5 seconds | < 10 seconds |
| Slow 3G | 5-10 seconds | < 15 seconds |

**Measurement**:
- Note timestamp when pull begins (loading spinner appears)
- Note timestamp when spinner disappears
- Calculate duration

### Frame Rate

- **Target**: 60 fps maintained during pull gesture and animation
- **Tool**: Flutter DevTools performance overlay
- **Validation**: No frame drops >16ms during refresh animation

### Memory

- **Before refresh**: Note memory usage in Flutter DevTools
- **During refresh**: Monitor for spikes
- **After refresh**: Verify memory returns to baseline (no leaks)
- **Expected**: <5 MB increase during refresh (temporary)

---

## Debugging

### Enable Flutter Logging

```bash
flutter run --verbose
```

### Check Shared Preferences Cache

```dart
// Add debug print in code
final prefs = await SharedPreferences.getInstance();
print('Cached categories: ${prefs.getString('categories')}');
print('Cached questions: ${prefs.getString('questions')}');
```

### Monitor Network Requests

- Use Android Studio network profiler
- OR use Charles Proxy / Fiddler to intercept HTTP(S)
- Verify only one request per refresh operation

### Common Issues

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Spinner never appears | RefreshIndicator not wrapping scrollable widget | Check widget tree |
| Refresh never completes | `onRefresh` callback doesn't return Future | Ensure async/await used |
| Data not updating | Cache not being written | Check error logs for validation failures |
| App crashes on refresh | Null pointer in fetch logic | Add null checks, verify data parsing |
| French messages not appearing | Error not caught properly | Verify try-catch blocks |

---

## Acceptance Criteria Checklist

Before marking feature complete, verify all spec requirements:

- [ ] **FR-001**: Pull-down gesture triggers data refresh ✅
- [ ] **FR-002**: Visual loading indicator displays during refresh ✅
- [ ] **FR-003**: Both Categories and Questions sheets fetched ✅
- [ ] **FR-004**: Local cache updated on successful refresh ✅
- [ ] **FR-005**: Cache preserved on failed refresh ✅
- [ ] **FR-006**: French error messages for network failures ✅
- [ ] **FR-007**: Concurrent refresh operations prevented ✅
- [ ] **FR-008**: Refresh completes or times out appropriately ✅
- [ ] **FR-009**: App remains responsive during refresh ✅
- [ ] **FR-010**: Spreadsheet access errors handled gracefully ✅

**Success Criteria**:
- [ ] **SC-001**: Refresh completes within 5 seconds (normal network) ✅
- [ ] **SC-002**: 100% cache integrity on failed refresh ✅
- [ ] **SC-003**: 95%+ success rate when network available ✅
- [ ] **SC-004**: Clear French feedback within 1 second ✅
- [ ] **SC-005**: Non-blocking refresh (responsive UI) ✅

---

## Next Steps

After successful testing:

1. Run full Flutter test suite: `flutter test`
2. Run static analysis: `flutter analyze --suggestions`
3. Validate dependencies: `flutter pub run dependency_validator`
4. Create pull request for review
5. Deploy via standard CI/CD pipeline (no manual builds)

## Support

For issues or questions:
- Check `specs/001-pull-to-refresh/plan.md` for technical details
- Review `specs/001-pull-to-refresh/data-model.md` for data flow
- Consult `.specify/memory/constitution.md` for project principles
