# Data Model: Flutter Web Deployment

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## Overview

The Flutter web deployment uses the **same data model** as the existing mobile app. No new entities are introduced by this feature. This document captures the entities and their relationships for reference during web implementation.

---

## Entities

### QuestionCategory

Represents a category of question cards with associated visual styling.

**Fields**:
- `title: String` — Category display name (e.g., "Famille", "Parent - Enfant")
- `color: Color` — Category color from hex string (defaults to teal if not provided)

**Source**: Google Sheets "Categories" sheet (columns: "Catégorie", "Couleur")

**Storage**: In-memory cache (`CategoryStore._cache`) as `Map<String, QuestionCategory>`

**Validation Rules**:
- Title must not be null or empty (enforced by Google Sheets data)
- Color hex string parsed via `ColorUtils.getColorFromHexString()`
- Invalid/missing hex → defaults to `Colors.teal`

**Lifecycle**:
1. Loaded from Google Sheets on app initialization
2. Cached in `CategoryStore` singleton for session duration
3. Referenced by `EssentielCardData` instances

---

### EssentielCardData

Represents a single question card with category and special flags.

**Fields**:
- `category: QuestionCategory?` — Associated category (nullable)
- `question: String?` — Question text displayed on card back (nullable)
- `isForCouples: bool` — Card suitable for couples (default: false)
- `isForFamilies: bool` — Card suitable for families (default: false)
- `isForParentChild: bool` — Card is from "Parent - Enfant" category (default: false)
- `isForInternalMood: bool` — Card contains "météo" keyword for internal mood check (default: false)

**Source**: Google Sheets "Questions" sheet (columns: "Question", "Catégorie", "Pour Couples", "Pour Familles")

**Derivation Logic**:
- `category`: Lookup in `CategoryStore` by "Catégorie" column value
- `isForCouples`: "Pour Couples" column == "Oui" (case-insensitive)
- `isForFamilies`: "Pour Familles" column == "Oui" (case-insensitive)
- `isForParentChild`: "Catégorie" column == "Parent - Enfant" (exact match)
- `isForInternalMood`: "Question" text contains "météo" (case-insensitive)

**Validation Rules**:
- Question text must not be null for display (enforced in UI)
- Category must exist in `CategoryStore` (enforced by lookup)
- Boolean flags validated at parse time (non-"Oui" values → false)

**Display Rules**:
- Front: Essentiel logo (all cards identical)
- Back: Question text in category color, category name footer in category background
- Special icons:
  - `isForFamilies == true` → family icon (top-right, orange)
  - `isForCouples == true` → heart icon (top-right, red)
  - `isForParentChild == true` → childReaching icon (top-right, pink #F06292)

---

### User Preferences

Persistent user settings stored in browser localStorage (web) or SharedPreferences (mobile).

**Fields**:
- `CATEGORY_FILTER_PREF_KEY: String` — Selected category filters as serialized list

**Storage Mechanism**:
- **Mobile**: SharedPreferences (platform-specific native storage)
- **Web**: Browser localStorage (5MB limit, persists across sessions)
- Key prefix: `flutter.` (auto-added by shared_preferences package)

**Validation Rules**:
- Categories must exist in `CategoryStore` when loaded
- Invalid/deleted categories silently filtered out on load
- Empty selection treated as "all categories enabled"

**Lifecycle**:
1. Loaded on app initialization
2. Updated when user changes category filters via UI
3. Applied to filter visible cards in horizontal list
4. Persists across app restarts (until browser cache clear on web)

---

## Relationships

```text
EssentielCardData ──> QuestionCategory
       │                     │
       │                     │
       └─ question          ─┴─ title, color
       └─ special flags
```

- **One-to-Many**: One `QuestionCategory` can be associated with many `EssentielCardData` instances
- **Lookup**: `EssentielCardData.category` resolved via `CategoryStore.findByName()` at parse time
- **Filtering**: User preferences filter which `EssentielCardData` instances are displayed based on category selection

---

## State Transitions

### Card Shuffle Flow

```text
[Initial State: All Cards Loaded]
       │
       v
[User triggers shuffle] ← shake gesture (mobile) / button (web/fallback)
       │
       v
[Random card selection from filtered set]
       │
       v
[Display selected card with flip animation]
```

### Data Refresh Flow

```text
[Cards cached in memory]
       │
       v
[User triggers refresh] ← pull-to-refresh (mobile/mobile web) / menu item
       │
       v
[Fetch from Google Sheets API]
       │
       ├─ Success → Update cache, reset to random card
       └─ Failure → Show error message, keep existing cache
```

### Filter Update Flow

```text
[User opens category filter dialog]
       │
       v
[User toggles category selections]
       │
       v
[Save to localStorage/SharedPreferences]
       │
       v
[Filter visible cards, reset to random from filtered set]
```

---

## Web-Specific Considerations

### Google Sheets API Integration

**Mobile (existing)**:
- Uses Service Account credentials from environment config
- Direct API access via `gsheets` package
- No CORS restrictions (native HTTP clients)

**Web (new)**:
- **Cannot access Google Sheets directly** (CORS restrictions, security violations, see [research.md](./research.md))
- Uses **secure backend API** provided by project team
- Backend handles Google Sheets authentication and data fetching
- Web app calls REST API endpoints (no Google Sheets SDK or credentials needed)
- Zero sensitive data embedded in web builds

### Local Storage Limits

**Mobile (existing)**:
- SharedPreferences: Platform-specific limits (typically unlimited for reasonable data sizes)
- Category filters + metadata: <1KB

**Web (new)**:
- localStorage: 5MB per origin limit
- Category filters + metadata: <1KB (well within limits)
- Data lost on browser cache clear (acceptable tradeoff)

---

## Validation Summary

| Entity | Required Fields | Optional Fields | Validation Rules |
|--------|----------------|-----------------|------------------|
| `QuestionCategory` | `title` | `color` | Title non-empty, color hex valid or default teal |
| `EssentielCardData` | `question`, `category` | All boolean flags | Question non-null, category exists in CategoryStore |
| User Preferences | — | `CATEGORY_FILTER_PREF_KEY` | Categories must exist when loaded, invalid entries filtered |

---

## No Schema Changes Required

This feature introduces **zero changes** to the data model. The web deployment reuses existing:
- Google Sheets source structure ("Categories" and "Questions" sheets)
- Dart entity classes (`QuestionCategory`, `EssentielCardData`)
- Storage key names (`CATEGORY_FILTER_PREF_KEY`)
- Parsing and validation logic

**Implementation Impact**: Data layer code requires no modifications for web deployment, only environment-specific credential loading (API key vs Service Account).
