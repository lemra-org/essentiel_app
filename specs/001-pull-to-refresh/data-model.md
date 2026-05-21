# Data Model: Pull-to-Refresh Question Data

**Feature**: 001-pull-to-refresh  
**Date**: 2026-05-22

## Overview

This document describes the data entities and flow for the pull-to-refresh feature. The feature reuses existing data models (`Category`, `Question`) and cache mechanisms, adding only refresh operation state management.

## Data Entities

### Category

**Source**: Existing model in `lib/resources/category.dart` (inferred from spec)

**Description**: Represents a question category from the "Categories" Google Sheet.

**Key Attributes**:
- Category name (String)
- Color/display properties (for UI rendering)
- Potentially: icon, description, sort order

**Relationships**:
- One category contains many questions
- Questions reference their parent category

**Validation Rules** (inferred from existing implementation):
- Category name must not be empty
- Color must be a valid color value

**State Transitions**: None - categories are immutable after fetch

**Storage**:
- Fetched from Google Sheets "Categories" sheet
- Cached in `shared_preferences` as serialized data
- Loaded into memory for UI rendering

---

### Question

**Source**: Existing model in `lib/resources/` directory (inferred from spec)

**Description**: Represents a single question from the "Questions" Google Sheet.

**Key Attributes**:
- Question text (String)
- Category assignment (reference to Category)
- Any associated metadata (e.g., difficulty, tags, author)

**Relationships**:
- Each question belongs to one category
- Questions are displayed in a scrollable list

**Validation Rules** (inferred from existing implementation):
- Question text must not be empty
- Category reference must be valid (exists in Categories list)

**State Transitions**: None - questions are immutable after fetch

**Storage**:
- Fetched from Google Sheets "Questions" sheet
- Cached in `shared_preferences` as serialized data
- Loaded into memory for UI rendering

---

### Cached State

**Source**: Existing `shared_preferences` implementation

**Description**: Local persistence layer that stores questions and categories for offline access.

**Storage Format**: 
- Key-value pairs in `shared_preferences`
- Likely JSON-serialized lists of categories and questions
- Example keys: `'categories'`, `'questions'`, `'last_updated'` (optional)

**Cache Behavior**:
- Written on successful data fetch (initial load or manual refresh)
- Read on app startup if no network available
- Preserved on failed refresh (no write occurs)
- Never invalidated except by successful refresh

**Cache Lifecycle**:
1. **Initial Load**: Fetch from Google Sheets → Serialize → Write to cache
2. **Offline Access**: Read from cache → Deserialize → Display
3. **Manual Refresh**: Fetch → Validate → Serialize → Overwrite cache
4. **Failed Refresh**: Cache unchanged, error displayed to user

---

### Refresh Operation State

**Source**: New - added for pull-to-refresh feature

**Description**: Transient state tracking the refresh operation to prevent concurrent requests.

**Attributes**:
- `isRefreshing` (Boolean): True while fetch is in progress, false otherwise

**Lifecycle**:
1. User initiates pull-to-refresh gesture
2. `isRefreshing` set to `true`
3. Fetch operation executes
4. On completion (success or error), `isRefreshing` set to `false`
5. RefreshIndicator hides loading spinner

**Not Persisted**: This state is in-memory only, resets on app restart.

**Usage**:
```dart
bool _isRefreshing = false;

Future<void> _handleRefresh() async {
  if (_isRefreshing) return;  // Prevent concurrent refresh
  _isRefreshing = true;
  try {
    await _fetchData();
  } finally {
    _isRefreshing = false;
  }
}
```

---

## Data Flow

### Initial App Load (Existing Behavior)

```
1. App starts → Game widget initState
2. Check shared_preferences cache
3. If cache exists:
   - Load cached data → Display questions
4. Fetch from Google Sheets:
   - Authenticate with service account
   - Fetch "Categories" sheet → Parse → Categories list
   - Fetch "Questions" sheet → Parse → Questions list
   - Validate data integrity
5. Serialize and write to cache
6. Update UI with fresh data
```

### Manual Refresh (New Behavior)

```
1. User pulls down on question list
2. RefreshIndicator triggers onRefresh callback
3. Check if _isRefreshing flag is true:
   - If true: Return immediately (ignore concurrent request)
   - If false: Set _isRefreshing = true, continue
4. Fetch from Google Sheets:
   - Authenticate with service account
   - Fetch "Categories" sheet → Parse
   - Fetch "Questions" sheet → Parse
   - Validate data integrity
5. On Success:
   - Serialize and overwrite cache
   - Update UI with fresh data
   - Set _isRefreshing = false
   - Hide loading spinner
6. On Error:
   - Preserve existing cache (no write)
   - Show error toast (French)
   - Set _isRefreshing = false
   - Hide loading spinner
7. UI remains responsive throughout
```

### Offline Scenario

```
1. User pulls down on question list (no network)
2. RefreshIndicator triggers onRefresh callback
3. Attempt to fetch from Google Sheets
4. Network error (SocketException) thrown
5. Catch error:
   - Display French error message: "Pas de connexion réseau..."
   - Cache preserved (no write attempted)
   - Set _isRefreshing = false
6. User continues using cached data
```

---

## Data Integrity Rules

### Source of Truth

Google Sheets is the single source of truth (Constitution Principle II). Local cache is:
- A performance optimization (avoid network on every load)
- An offline fallback (enable usage without connectivity)
- Never authoritative (always replaced on successful refresh)

### Cache Preservation on Error

Failed refreshes MUST NOT modify the cache. This ensures:
- Users never lose existing data due to transient network issues
- App remains functional offline
- Integrity of cached data maintained

**Implementation**: Only call cache write method after successful fetch and validation.

### Data Validation

Before updating cache, validate fetched data:
- Categories sheet contains at least one category
- Questions sheet contains at least one question
- All question category references are valid
- No required fields are empty or null

If validation fails, treat as error: preserve cache, show error toast.

---

## Performance Considerations

### Cache Size

- Expected: ~50-200 questions × ~100 bytes = 5-20 KB
- Expected: ~10-20 categories × ~50 bytes = 0.5-1 KB
- Total: <25 KB (negligible for mobile storage)

### Fetch Time

- Network request: 1-5 seconds (depends on connection)
- Parse and validate: <100ms (small dataset)
- Cache write: <100ms (small data size)
- **Total**: 1-6 seconds (within spec's 5-second goal for normal network)

### Memory Usage

- In-memory data: <1 MB for questions and categories
- No memory leaks - data replaced on refresh, not appended

---

## State Diagram: Refresh Operation

```
[Idle] 
  ↓ (User pulls down)
[Checking _isRefreshing flag]
  ↓ (false)
[Refreshing: _isRefreshing = true]
  ↓
[Fetching from Google Sheets]
  ↓
  ├─→ [Success]
  │     ↓
  │   [Update cache]
  │     ↓
  │   [Update UI]
  │     ↓
  │   [_isRefreshing = false]
  │     ↓
  │   [Idle]
  │
  └─→ [Error]
        ↓
      [Preserve cache]
        ↓
      [Show error toast]
        ↓
      [_isRefreshing = false]
        ↓
      [Idle]

[Checking _isRefreshing flag]
  ↓ (true)
[Return immediately, ignore request]
  ↓
[Idle]
```

---

## Testing Data Scenarios

### Valid Data

- Categories: At least 1 category with name and color
- Questions: At least 1 question with text and valid category reference
- Expected: Successful fetch, cache updated, UI refreshed

### Empty Spreadsheet

- Categories: Empty sheet
- Questions: Empty sheet
- Expected: Validation error, cache preserved, error toast

### Malformed Data

- Missing required fields (category name, question text)
- Invalid category references in questions
- Expected: Validation error, cache preserved, error toast

### Network Errors

- No connectivity
- Timeout
- DNS failure
- Expected: Network error caught, cache preserved, French error toast

---

## Summary

The pull-to-refresh feature reuses all existing data models and cache mechanisms. The only new state is the `_isRefreshing` boolean flag to prevent concurrent operations. Data flow follows the existing pattern: fetch → validate → cache → update UI, with robust error handling to preserve cache integrity.
