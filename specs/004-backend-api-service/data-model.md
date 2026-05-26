# Data Model: Backend API Service

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## Overview

The backend API service exposes two primary entities from Google Sheets: Categories and Questions. These entities are fetched server-side from Google Sheets and cached in-memory for 5 minutes before being returned to clients as JSON.

---

## Entities

### Category

Represents a question category with visual styling information.

**Fields**:
- `name: string` — Category display name (e.g., "Famille", "Parent - Enfant", "Couple")
- `color: string` — Hex color code with `#` prefix (e.g., "#FF9800", "#9C27B0")

**Source**: Google Sheets "Categories" sheet

**Validation Rules**:
- `name` must not be null or empty
- `color` must be a valid hex color code (6 characters, case-insensitive, with `#` prefix)
- If color is missing or invalid, default to "#009688" (teal)

**Go Struct Representation**:
```go
type Category struct {
    Name  string `json:"name"`
    Color string `json:"color"`
}
```

**JSON Example**:
```json
{
  "name": "Famille",
  "color": "#FF9800"
}
```

---

### Question

Represents a card question with category association and context flags.

**Fields**:
- `question: string` — Question text displayed on the card
- `category: string` — Category name (must match a Category.name)
- `forCouples: boolean` — Card suitable for couples
- `forFamilies: boolean` — Card suitable for families

**Source**: Google Sheets "Questions" sheet

**Validation Rules**:
- `question` must not be null or empty
- `category` must reference an existing Category name
- Boolean flags default to `false` if not specified or invalid
- `forFamilies` is automatically set to `true` for questions in the "Parent - Enfant" category (parent-child questions are inherently family questions)

**Go Struct Representation**:
```go
type Question struct {
    Question    string `json:"question"`
    Category    string `json:"category"`
    ForCouples  bool   `json:"forCouples"`
    ForFamilies bool   `json:"forFamilies"`
}
```

**JSON Example**:
```json
{
  "question": "Quelle est ta plus grande fierté cette année?",
  "category": "Famille",
  "forCouples": false,
  "forFamilies": true
}
```

---

## Relationships

```text
Question ──> Category (via category name string reference)
```

- **Many-to-One**: Multiple Questions can reference the same Category
- **Referential Integrity**: Question.category must exist in the Categories list
- **No Cascading**: Categories are independent; deleting a category in Google Sheets does not auto-delete questions

---

## Data Flow

### Fetch from Google Sheets

```text
1. API Request → /api/categories or /api/questions
2. Check in-memory cache (5-minute TTL)
3. If cache miss:
   a. Authenticate to Google Sheets using Service Account
   b. Fetch "Categories" or "Questions" sheet
   c. Parse [][]interface{} rows into Category or Question structs
   d. Validate data
   e. Store in cache with 5-minute expiration
   f. Return to client
4. If cache hit:
   a. Return cached data immediately
```

### Google Sheets Format

**Categories Sheet**:
```
| Catégorie       | Couleur  |
|-----------------|----------|
| Famille         | #FF9800  |
| Parent - Enfant | #9C27B0  |
| Couple          | #E91E63  |
```

**Questions Sheet**:
```
| Question                        | Catégorie       | Pour Couples | Pour Familles |
|---------------------------------|-----------------|--------------|---------------|
| Quelle est ta plus grande...   | Famille         | Non          | Oui           |
| Qu'est-ce qui te fait...        | Couple          | Oui          | Non           |
```

**Parsing Logic**:
- Header row (row 1) is skipped
- Column mapping by index (not by header name for simplicity)
- Boolean columns: "Oui" (case-insensitive) → `true`, anything else → `false`
- `forFamilies` is automatically set to `true` for "Parent - Enfant" category questions

---

## Validation & Error Handling

### Server-Side Validation

**Categories**:
- Reject categories with empty names
- Validate hex color format (regex: `^#[0-9A-Fa-f]{6}$`)
- Deduplicate categories by name (keep first occurrence)

**Questions**:
- Reject questions with empty text
- Reject questions with non-existent categories
- Coerce invalid boolean values to `false`

### Error Scenarios

| Scenario | HTTP Status | Response |
|----------|-------------|----------|
| Google Sheets API unavailable | 503 Service Unavailable | `{"error": "Unable to fetch data from source"}` |
| Invalid credentials | 500 Internal Server Error | `{"error": "Authentication failed"}` |
| Rate limit exceeded | 429 Too Many Requests | `{"error": "Rate limit exceeded, try again later"}` |
| Malformed spreadsheet data | 500 Internal Server Error | `{"error": "Data validation failed"}` |
| Empty spreadsheet | 200 OK | `{"categories": []}` or `{"questions": []}` |

---

## Caching Strategy

**Cache Implementation**: 
- **Primary**: Redis (optional, recommended for production)
- **Fallback**: In-memory using `github.com/patrickmn/go-cache`
- Cache backend auto-detected at startup based on `REDIS_ADDR` configuration

**Cache Selection**:
- If `REDIS_ADDR` is set and Redis is reachable: Use Redis cache
- If `REDIS_ADDR` is empty or Redis is unreachable: Fall back to in-memory cache
- Fallback is automatic and transparent to the application

**Cache Keys**:
- `"categories"`: Stores `[]Category`
- `"questions"`: Stores `[]Question`

**TTL**: 5 minutes (300 seconds)

**Redis Benefits**:
- Shared cache across multiple backend instances (horizontal scaling)
- Persistent cache survives backend restarts
- Better memory management for large datasets

**Invalidation**: Automatic expiration after TTL, no manual invalidation endpoint

**Cache Miss Behavior**:
- Synchronous fetch from Google Sheets
- Block request until data is fetched and cached
- Return data to client
- Subsequent requests within TTL serve from cache

**Cache Hit Behavior**:
- Immediate return (sub-millisecond latency for in-memory, <10ms for Redis)
- No Google Sheets API call

---

## State Transitions

### Category Lifecycle

```text
[Google Sheets Update] → [Cache Expiration (5 min)] → [API Fetch] → [Cache Refresh] → [Client Sees New Data]
```

**Timeline**:
1. Admin updates Categories sheet in Google Sheets
2. Existing cache remains valid for up to 5 minutes
3. After TTL expires, next request fetches fresh data
4. New category data cached for another 5 minutes

**Note**: No real-time updates. Maximum staleness is 5 minutes.

### Question Lifecycle

Same as Category lifecycle above.

---

## Performance Considerations

**Google Sheets API Latency**:
- Typical response time: 200-500ms (varies by spreadsheet size and network)
- Our constraint: <2s for fresh fetch (spec requirement SC-002)

**Cache Hit Performance**:
- Target: <100ms for cached data (spec requirement SC-001)
- Expected: <10ms in practice (in-memory lookup + JSON serialization)

**Concurrent Request Handling**:
- Cache is thread-safe (go-cache uses sync.RWMutex internally)
- Multiple simultaneous requests for same resource served from single cache entry
- No thundering herd problem (cache hit serves all requests)

---

## Data Consistency

**Single Source of Truth**: Google Sheets spreadsheet

**Consistency Guarantees**:
- **Eventually Consistent**: Changes in Google Sheets appear in API within 5 minutes (worst case)
- **Read-Your-Writes**: Not guaranteed (cache may serve stale data immediately after spreadsheet update)
- **Monotonic Reads**: Not guaranteed (different requests may hit different cache states during refresh)

**Acceptable Trade-offs**:
- 5-minute staleness is acceptable for card game content (content changes are infrequent)
- No need for real-time updates or strong consistency
- Simplicity over complex cache invalidation strategies

---

## Future Enhancements (Out of Scope)

- **Webhook-based cache invalidation**: Google Sheets triggers cache refresh on edits
- **Partial cache updates**: Update only changed categories/questions instead of full refresh
- **Cache warmup**: Pre-populate cache on service startup

These enhancements are not needed for the MVP and add significant complexity.

**Note**: Redis caching is now implemented as an optional feature with automatic fallback to in-memory cache.

---

## Summary

**Two Core Entities**:
- Category: Name + color code
- Question: Text + category reference + boolean flags

**Simple Data Model**:
- Flat structures (no nested objects)
- String references (no foreign keys or joins)
- Boolean flags from spreadsheet columns

**Caching Strategy**:
- 5-minute in-memory TTL
- Automatic expiration
- No manual invalidation

**Validation**:
- Server-side validation before caching
- Graceful error handling for malformed data
- Default values for missing/invalid fields
