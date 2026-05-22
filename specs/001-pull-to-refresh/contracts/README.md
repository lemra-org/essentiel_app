# Contracts: Pull-to-Refresh Question Data

**Feature**: 001-pull-to-refresh  
**Date**: 2026-05-22

## Contract Scope

**No external contracts defined for this feature.**

## Rationale

The pull-to-refresh feature is an internal UI enhancement that does not expose any interfaces to external systems or users. Specifically:

- **No Public API**: This is not a library with public methods
- **No CLI Commands**: No command-line interface exposed
- **No Web Endpoints**: No HTTP endpoints or web services
- **No External Integrations**: Feature only integrates internally with existing Google Sheets fetch logic

## Internal Interfaces (Documentation Only)

While there are no external contracts, the feature does interact with internal components:

### 1. RefreshIndicator Widget Contract (Flutter Framework)

**Interface**: Flutter Material Design widget  
**Type**: Internal Flutter API (not project-specific)  
**Contract**: 
```dart
RefreshIndicator({
  required Widget child,              // Must be scrollable
  required RefreshCallback onRefresh, // Returns Future<void>
  ...
})
```

**Usage in Feature**:
- Wraps existing question list (ListView)
- `onRefresh` callback executes data fetch logic
- Returns `Future<void>` when refresh completes

**Not a Public Contract**: This is Flutter framework usage, not an interface our feature exposes.

---

### 2. Google Sheets Data Source (Existing Integration)

**Interface**: Google Sheets API via `gsheets` package  
**Type**: External data source (read-only for this feature)  
**Contract**: 
- Two sheets: "Categories" and "Questions"
- Sheet structure defined by existing implementation (unchanged by this feature)
- Authentication via Google Service Account credentials

**Not a Public Contract**: This is a consumed interface, not one we expose. The spreadsheet structure is documented in existing codebase, not changed by pull-to-refresh.

---

### 3. Shared Preferences Cache (Existing Storage)

**Interface**: Local key-value storage via `shared_preferences`  
**Type**: Internal persistence layer  
**Contract**:
- Read/write operations for cached questions and categories
- Data serialization format (JSON or similar)
- Keys: `'categories'`, `'questions'` (inferred from existing code)

**Not a Public Contract**: Internal storage mechanism, not exposed to external systems.

---

## Summary

This feature enhances the user interface by adding manual refresh capability. It does not introduce any new public APIs, endpoints, or contracts that external systems would integrate with. All interactions are internal to the app.

For data model details, see `../data-model.md`.  
For testing procedures, see `../quickstart.md`.
