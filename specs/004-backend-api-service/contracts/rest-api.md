# REST API Contract: Backend API Service

**Feature**: [../spec.md](../spec.md)  
**Plan**: [../plan.md](../plan.md)  
**Date**: 2026-05-22

## Base URL

```
Production: https://api.essentiel.example.com (TBD - actual domain after Fly.io deployment)
Development: http://localhost:8080
```

## Authentication

**Public Endpoints**: No authentication required (endpoints are publicly accessible)

**Rate Limiting**: 100 requests per minute per IP address (enforced at cloud platform level)

---

## Endpoints

### GET /api/categories

Fetch all question categories with their display names and color codes.

**Request**:
```http
GET /api/categories HTTP/1.1
Host: api.essentiel.example.com
Origin: https://lemra-org.github.io
```

**Response** (200 OK):
```http
HTTP/1.1 200 OK
Content-Type: application/json
Access-Control-Allow-Origin: https://lemra-org.github.io
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
Cache-Control: public, max-age=300
Content-Length: 234

{
  "categories": [
    {
      "name": "Famille",
      "color": "#FF9800"
    },
    {
      "name": "Parent - Enfant",
      "color": "#9C27B0"
    },
    {
      "name": "Couple",
      "color": "#E91E63"
    }
  ]
}
```

**Response Fields**:
- `categories` (array): List of category objects
  - `name` (string, required): Category display name
  - `color` (string, required): Hex color code with `#` prefix

**Error Responses**:

| Status Code | Condition | Response Body |
|-------------|-----------|---------------|
| 503 Service Unavailable | Google Sheets API unavailable | `{"error": "Unable to fetch data from source"}` |
| 500 Internal Server Error | Server-side error (auth, parsing) | `{"error": "Internal server error"}` |
| 429 Too Many Requests | Rate limit exceeded | `{"error": "Rate limit exceeded, try again later"}` |

---

### GET /api/questions

Fetch all question cards with their text, category association, and context flags.

**Request**:
```http
GET /api/questions HTTP/1.1
Host: api.essentiel.example.com
Origin: https://lemra-org.github.io
```

**Response** (200 OK):
```http
HTTP/1.1 200 OK
Content-Type: application/json
Access-Control-Allow-Origin: https://lemra-org.github.io
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
Cache-Control: public, max-age=300
Content-Length: 512

{
  "questions": [
    {
      "question": "Quelle est ta plus grande fierté cette année?",
      "category": "Famille",
      "forCouples": false,
      "forFamilies": true
    },
    {
      "question": "Qu'est-ce qui te fait te sentir aimé(e)?",
      "category": "Couple",
      "forCouples": true,
      "forFamilies": false
    },
    {
      "question": "Qu'as-tu appris récemment que tu aimerais partager?",
      "category": "Parent - Enfant",
      "forCouples": false,
      "forFamilies": false
    }
  ]
}
```

**Response Fields**:
- `questions` (array): List of question objects
  - `question` (string, required): Question text
  - `category` (string, required): Category name (must match a category from `/api/categories`)
  - `forCouples` (boolean, required): Card suitable for couples
  - `forFamilies` (boolean, required): Card suitable for families

**Error Responses**: Same as `/api/categories`

---

### GET /healthz

Liveness probe endpoint for health checks.

**Request**:
```http
GET /healthz HTTP/1.1
Host: api.essentiel.example.com
```

**Response** (200 OK):
```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 25

{"status": "healthy"}
```

**Response** (503 Service Unavailable):
```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json
Content-Length: 27

{"status": "unhealthy"}
```

**Purpose**: Used by Fly.io for determining if the service should receive traffic

---

### GET /readyz

Readiness probe endpoint for deployment health checks.

**Request**:
```http
GET /readyz HTTP/1.1
Host: api.essentiel.example.com
```

**Response** (200 OK):
```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 23

{"status": "ready"}
```

**Response** (503 Service Unavailable):
```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json
Content-Length: 27

{"status": "not ready"}
```

**Purpose**: Checks if the service can access Google Sheets API (validates credentials and connectivity)

---

## CORS Configuration

**Allowed Origin**: `https://lemra-org.github.io`

**Allowed Methods**: `GET`, `OPTIONS`

**Allowed Headers**: `Content-Type`

**Preflight Cache**: `300` seconds (5 minutes)

**Preflight Request Example**:
```http
OPTIONS /api/categories HTTP/1.1
Host: api.essentiel.example.com
Origin: https://lemra-org.github.io
Access-Control-Request-Method: GET
Access-Control-Request-Headers: Content-Type
```

**Preflight Response**:
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://lemra-org.github.io
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 300
Content-Length: 0
```

---

## Caching Headers

All successful data responses (`/api/categories`, `/api/questions`) include caching headers:

```http
Cache-Control: public, max-age=300
```

**Interpretation**:
- `public`: Response can be cached by browsers and CDNs
- `max-age=300`: Cache valid for 5 minutes (300 seconds)

**Rationale**: Matches server-side cache TTL. Browsers can cache responses to reduce redundant requests.

---

## Error Response Format

All errors return JSON with an `error` field:

```json
{
  "error": "Human-readable error message"
}
```

**Error Messages** (Examples):
- `"Unable to fetch data from source"` — Google Sheets API unavailable
- `"Internal server error"` — Server-side failure (credentials, parsing)
- `"Rate limit exceeded, try again later"` — Client exceeded rate limit
- `"Service unavailable"` — Service starting up or shutting down

**Error Logging**: Detailed errors logged server-side, generic messages returned to clients (no sensitive information exposed)

---

## Performance Guarantees

**Response Time Targets** (from spec.md Success Criteria):

| Scenario | Target | Measurement |
|----------|--------|-------------|
| Cached data | <100ms | P99 |
| Fresh data (cache miss) | <2s | P95 |

**Concurrent Request Handling**:
- Service must handle 100 concurrent requests without errors or degradation
- Cache is thread-safe (concurrent reads from same cache entry)

---

## Versioning

**Current Version**: v1 (implicit in `/api/` prefix)

**Versioning Strategy**: No versioning for v1 (breaking changes will introduce `/api/v2/` endpoints if needed)

**Breaking vs Non-Breaking Changes**:
- **Non-Breaking** (can deploy without versioning):
  - Adding new optional fields to responses
  - Adding new endpoints
  - Improving error messages
- **Breaking** (requires new version):
  - Removing fields from responses
  - Changing field types
  - Changing endpoint URLs
  - Changing required request parameters

---

## Request/Response Examples

### Successful Category Fetch

**Request**:
```bash
curl -H "Origin: https://lemra-org.github.io" \
  https://api.essentiel.example.com/api/categories
```

**Response**:
```json
{
  "categories": [
    {"name": "Famille", "color": "#FF9800"},
    {"name": "Parent - Enfant", "color": "#9C27B0"},
    {"name": "Couple", "color": "#E91E63"},
    {"name": "Amitié", "color": "#4CAF50"},
    {"name": "Personnel", "color": "#2196F3"}
  ]
}
```

### Successful Question Fetch

**Request**:
```bash
curl -H "Origin: https://lemra-org.github.io" \
  https://api.essentiel.example.com/api/questions
```

**Response** (truncated for brevity):
```json
{
  "questions": [
    {
      "question": "Quelle est ta plus grande fierté cette année?",
      "category": "Famille",
      "forCouples": false,
      "forFamilies": true
    },
    {
      "question": "Qu'est-ce qui te fait te sentir aimé(e)?",
      "category": "Couple",
      "forCouples": true,
      "forFamilies": false
    }
  ]
}
```

### Error Response (Service Unavailable)

**Request**:
```bash
curl -H "Origin: https://lemra-org.github.io" \
  https://api.essentiel.example.com/api/categories
```

**Response**:
```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json

{
  "error": "Unable to fetch data from source"
}
```

### CORS Violation (Disallowed Origin)

**Request**:
```bash
curl -H "Origin: https://evil.com" \
  https://api.essentiel.example.com/api/categories
```

**Response** (200 OK but no CORS headers):
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "categories": [...]
}
```

**Note**: Browser will block the response due to missing `Access-Control-Allow-Origin` header for `https://evil.com`.

---

## Security Considerations

**No Credentials Exposed**:
- Service Account credentials stored server-side only
- Never included in API responses or logs accessible to clients
- Environment variables or secret management for credential injection

**CORS Enforcement**:
- Only `https://lemra-org.github.io` can make browser requests
- Preflight requests properly handled
- Non-browser clients (curl, Postman) can access without CORS restrictions

**Rate Limiting**:
- 100 requests per minute per IP
- Prevents abuse and quota exhaustion
- Enforced at Fly.io platform level (not application-level)

**HTTPS Only**:
- Force HTTPS in production (configured in `fly.toml`)
- HTTP connections redirected to HTTPS
- Protects data in transit

---

## Testing the API

### Local Development

```bash
# Start local server
go run cmd/server/main.go

# Test categories endpoint
curl http://localhost:8080/api/categories

# Test questions endpoint
curl http://localhost:8080/api/questions

# Test health check
curl http://localhost:8080/healthz
```

### Production

```bash
# Test categories endpoint with CORS
curl -H "Origin: https://lemra-org.github.io" \
  https://api.essentiel.example.com/api/categories

# Test preflight request
curl -X OPTIONS \
  -H "Origin: https://lemra-org.github.io" \
  -H "Access-Control-Request-Method: GET" \
  https://api.essentiel.example.com/api/categories
```

### Automated Testing

See [../quickstart.md](../quickstart.md) for integration test examples using Go's `httptest` package.

---

## Client Integration (Flutter Web App)

**Example API Service in Dart**:
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class EssentielApiService {
  final String baseUrl;
  
  EssentielApiService({required this.baseUrl});
  
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['categories'] as List)
        .map((c) => Category.fromJson(c))
        .toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }
  
  Future<List<Question>> fetchQuestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/questions'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['questions'] as List)
        .map((q) => Question.fromJson(q))
        .toList();
    } else {
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  }
}
```

---

## Summary

**Two Primary Endpoints**:
- `GET /api/categories` — Fetch all categories
- `GET /api/questions` — Fetch all questions

**Support Endpoints**:
- `GET /healthz` — Liveness probe
- `GET /readyz` — Readiness probe

**Key Features**:
- CORS support for web app domain
- 5-minute cache headers for browser caching
- Consistent JSON error format
- Sub-100ms cached responses
- <2s fresh data responses

**Client Expectations**:
- Always returns JSON (even errors)
- CORS headers present for allowed origins
- Cache-Control headers for efficient caching
- Standard HTTP status codes

