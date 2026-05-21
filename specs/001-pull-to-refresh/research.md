# Research: Pull-to-Refresh Question Data

**Feature**: 001-pull-to-refresh  
**Date**: 2026-05-22  
**Status**: Complete

## Overview

This document captures research findings for implementing pull-to-refresh functionality in the Essentiel Flutter app. Research focused on Flutter patterns, error handling, and offline scenarios.

## Research Areas

### 1. Flutter RefreshIndicator Widget

**Decision**: Use Flutter's built-in `RefreshIndicator` widget

**Rationale**:
- Native Flutter Material Design widget optimized for mobile
- Handles pull gesture, animation, and loading indicator automatically
- Well-documented and widely used in production apps
- Minimal code required - wraps existing scrollable widget
- Supports customization (colors, stroke width) to match app theme

**Implementation Pattern**:
```dart
RefreshIndicator(
  onRefresh: _handleRefresh,  // Returns Future<void>
  child: ListView(...),        // Existing scrollable widget
)
```

**Key Findings**:
- `onRefresh` callback must return a `Future<void>` that completes when refresh is done
- RefreshIndicator automatically shows/hides loading spinner
- Works with any scrollable widget (ListView, GridView, CustomScrollView)
- Pull gesture requires sufficient vertical scroll space

**Alternatives Considered**:
- Custom pull-to-refresh implementation: Rejected - unnecessary complexity, worse UX
- Third-party packages (pull_to_refresh, liquid_pull_to_refresh): Rejected - built-in widget sufficient

**References**:
- Flutter RefreshIndicator documentation: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Material Design pull-to-refresh guidelines

---

### 2. Reusing Existing Google Sheets Fetch Logic

**Decision**: Extract and reuse the existing data fetch logic from `lib/game/game.dart` initState

**Rationale**:
- App already fetches Google Sheets data on startup in `Game` widget's `initState`
- Same logic needed for manual refresh: authenticate, fetch sheets, parse data, cache results
- Code reuse reduces bugs and maintenance burden
- Ensures consistent behavior between initial load and refresh

**Implementation Approach**:
1. Extract current fetch logic into a reusable method (e.g., `_fetchQuestionsFromSheets()`)
2. Call from both `initState` (initial load) and `_handleRefresh` (pull-to-refresh)
3. Handle errors in a centralized location
4. Update UI state after successful fetch

**Current Fetch Flow** (from existing code review):
1. Initialize GSheets client with service account credentials
2. Open spreadsheet by ID
3. Fetch "Categories" sheet → parse into Category objects
4. Fetch "Questions" sheet → parse into Question objects  
5. Cache data using `shared_preferences`
6. Update widget state to display questions

**Key Findings**:
- Existing code in `lib/game/game.dart` already handles Google Sheets authentication
- Uses `gsheets` package (forked version) for API access
- Service account credentials from environment config (`lib/env.dart`)
- Data stored in `shared_preferences` for offline access

**Refactoring Required**:
- Minimal - extract fetch logic into separate method, keep error handling centralized
- No changes to data models or cache format

---

### 3. Offline Scenario Handling

**Decision**: Graceful degradation with French error messages and cache preservation

**Rationale**:
- Users often participate in groups in locations with poor connectivity
- Losing cached data would disrupt ongoing sessions
- Clear feedback helps users understand why refresh failed
- Matches Constitution Principle II: Data Integrity & Offline-First

**Error Handling Strategy**:

| Error Type | User Feedback (French) | Technical Action |
|------------|------------------------|------------------|
| No network connectivity | "Pas de connexion réseau. Veuillez vérifier votre connexion." | Preserve cache, dismiss loading indicator |
| Google Sheets timeout | "Le chargement des questions a expiré. Réessayez plus tard." | Preserve cache, log error |
| Spreadsheet not found | "Impossible d'accéder à la feuille de calcul." | Preserve cache, check credentials |
| Malformed data | "Les données reçues sont invalides." | Preserve cache, log details |
| Mid-fetch network loss | "Connexion perdue pendant le chargement." | Preserve cache, cancel fetch |

**Implementation Pattern**:
```dart
Future<void> _handleRefresh() async {
  try {
    // Attempt to fetch fresh data
    await _fetchQuestionsFromSheets();
  } on SocketException {
    _showErrorToast("Pas de connexion réseau...");
    // Cache preserved automatically (no write on error)
  } catch (e) {
    _showErrorToast("Erreur lors du chargement.");
    // Log error for debugging
  }
}
```

**Key Findings**:
- `shared_preferences` cache only updated on successful fetch
- Failed refresh leaves cache intact by default
- `fluttertoast` package already available for user feedback
- Network errors throw `SocketException` in Dart

**Testing Requirements**:
- Test with airplane mode enabled
- Test with slow/flaky network (dev tools throttling)
- Test with invalid spreadsheet ID
- Test with permission errors

---

### 4. Preventing Concurrent Refresh Operations

**Decision**: Use boolean flag to ignore refresh requests while operation in progress

**Rationale**:
- Multiple rapid pull gestures could trigger overlapping network requests
- Concurrent fetches waste bandwidth and battery
- Could cause race conditions in cache updates
- Simple flag-based approach sufficient for single-user app

**Implementation Pattern**:
```dart
bool _isRefreshing = false;

Future<void> _handleRefresh() async {
  if (_isRefreshing) return;  // Ignore if already refreshing
  
  _isRefreshing = true;
  try {
    await _fetchQuestionsFromSheets();
  } finally {
    _isRefreshing = false;  // Always reset, even on error
  }
}
```

**Key Findings**:
- RefreshIndicator doesn't prevent multiple triggers automatically
- Boolean flag is simplest and most reliable approach
- `finally` block ensures flag reset even on exceptions
- No mutex or locking primitives needed for single-threaded Dart

**Alternatives Considered**:
- Debouncing: Rejected - unnecessary complexity, RefreshIndicator already has animation delay
- Request cancellation: Rejected - simpler to prevent concurrent requests entirely

---

### 5. French Error Message Localization

**Decision**: Hardcode French messages for now; prepare for i18n if needed later

**Rationale**:
- App's primary user base is French-speaking (Essentiel groups in France)
- Current app does not have localization infrastructure
- Hardcoding French strings is simplest approach
- Can be refactored to `flutter_localizations` if multi-language support added

**French Error Messages**:
- Network error: "Pas de connexion réseau. Veuillez vérifier votre connexion."
- Timeout: "Le chargement des questions a expiré. Réessayez plus tard."
- Generic error: "Erreur lors du chargement des questions."
- Success (optional): "Questions mises à jour."

**Implementation**:
- Store strings as constants in the widget or a dedicated constants file
- Use `fluttertoast` for displaying messages (already in dependencies)

**Future Consideration**:
- If multi-language support added, migrate to `flutter_localizations` with `.arb` files

---

## Summary of Technical Decisions

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| UI Component | `RefreshIndicator` widget | Native Flutter, minimal code, good UX |
| Data Fetch | Reuse existing Google Sheets logic | Code reuse, consistency, fewer bugs |
| Offline Handling | Preserve cache, French error toast | Graceful degradation, user clarity |
| Concurrency | Boolean flag `_isRefreshing` | Simple, sufficient for single-user app |
| Error Messages | Hardcoded French strings | Matches user base, simplest approach |

## Dependencies

No new dependencies required. Existing packages sufficient:
- `gsheets` - Google Sheets API access
- `shared_preferences` - Local cache
- `fluttertoast` - Error message display
- `googleapis_auth` - Service account authentication

## Performance Considerations

- Network fetch may take 1-5 seconds depending on connection
- RefreshIndicator animation adds ~300-500ms visual feedback
- Cache write is fast (<100ms for small datasets)
- Total perceived time: 1-6 seconds (within spec's 5-second goal for normal network)

## Open Questions

None. All technical unknowns resolved through research.

## Next Steps

Proceed to Phase 1: Design & Contracts
- Create data-model.md (reuse existing models, document refresh flow)
- Create quickstart.md (testing guide for manual refresh)
- Skip contracts/ (no external API exposed)
