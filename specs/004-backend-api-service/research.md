# Research Findings: Backend API Service

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## CORS Middleware

**Decision**: Use `github.com/rs/cors` library

**Rationale**:
- Battle-tested and most widely adopted CORS middleware for Go
- Works with all Go versions (including 1.22)
- Simple configuration for single-origin scenarios
- Good performance for typical traffic patterns
- Extensive production usage and community support

**Alternatives Considered**:
- **jub0bs/cors**: Modern, better security/memory under adversarial conditions, but requires Go 1.25+
- **go-chi/cors**: Fork of rs/cors optimized for Chi router, but we're using standard library
- **Custom implementation**: Too error-prone for CORS complexity

**Implementation**:
```go
import "github.com/rs/cors"

c := cors.New(cors.Options{
    AllowedOrigins: []string{"https://lemra-org.github.io"},
    AllowedMethods: []string{"GET", "OPTIONS"},
    AllowedHeaders: []string{"Content-Type"},
    MaxAge: 300,
    Debug: false, // Production setting
})
handler := c.Handler(mux)
```

---

## Google Sheets API Integration

**Decision**: Use official `google.golang.org/api/sheets/v4` with custom parsing

**Rationale**:
- Official Google library with long-term support
- Well-documented authentication via Service Account
- Returns `[][]interface{}` which we'll map to structs manually (simple for 2 sheets)
- No extra dependencies needed for our straightforward use case

**Alternatives Considered**:
- **googlesheetsparser**: Convenient struct mapping but adds dependency for marginal benefit
- **Direct HTTP calls**: More control but requires reimplementing OAuth2 and error handling

**Service Account Authentication**:
```go
import (
    "google.golang.org/api/option"
    "google.golang.org/api/sheets/v4"
    "golang.org/x/oauth2/google"
)

ctx := context.Background()
credentials, _ := ioutil.ReadFile("service-account.json")
scopes := []string{"https://www.googleapis.com/auth/spreadsheets.readonly"}

config, _ := google.JWTConfigFromJSON(credentials, scopes...)
srv, _ := sheets.NewService(ctx, option.WithHTTPClient(config.Client(ctx)))
```

**Error Handling**:
- Google Sheets API rate limit: 300 req/min per project, 60 req/min per user
- Implement exponential backoff for 429 errors (1s, 4s, 9s, 16s, 25s delays)
- Retry up to 5 times before returning error to client
- Use batch reads (`srv.Spreadsheets.Values.BatchGet()`) to reduce quota usage

---

## In-Memory Caching

**Decision**: Use `github.com/patrickmn/go-cache` library

**Rationale**:
- Simple, production-ready cache with built-in TTL and cleanup
- Perfect for our use case (5-minute Google Sheets data cache)
- One-liner setup, minimal configuration
- Proven reliability across thousands of production deployments
- Thread-safe by default

**Alternatives Considered**:
- **map + sync.RWMutex**: More control but requires manual TTL management and cleanup goroutine
- **dgraph-io/ristretto**: High-performance but overkill for simple caching (designed for millions of entries)
- **jellydator/ttlcache**: Modern with generics but less battle-tested than go-cache

**Implementation**:
```go
import "github.com/patrickmn/go-cache"

// Create cache with 5-minute expiration, 10-minute cleanup interval
c := cache.New(5*time.Minute, 10*time.Minute)

// Store categories
c.Set("categories", categoriesData, cache.DefaultExpiration)

// Retrieve categories
if data, found := c.Get("categories"); found {
    return data.([]Category)
}
```

**Cache Strategy**:
- Single cache entry for categories, single entry for questions
- Add 10% jitter to TTL (4.5-5.5 minutes) to prevent thundering herd
- Cache miss triggers synchronous Google Sheets fetch (simple blocking call)
- No cache warmup needed (lazy loading on first request)

---

## Cloud Deployment Platform

**Decision**: Deploy to **Fly.io**

**Rationale**:
- Edge deployment across 35+ regions (better global latency than single-region)
- Zero-downtime rolling deployments with health check integration
- VM-based (no cold starts like Cloud Run)
- Cost-effective for always-on services ($10.70/month base)
- Simple CLI workflow and GitHub Actions integration

**Alternatives Considered**:
- **Cloud Run**: Excellent for MVP (2M free requests/month) but serverless cold starts and cost spikes at scale
- **Railway**: Simplest DX but recent reliability issues (2026 EU West outages) and no multi-region support

**Dockerfile Multi-Stage Build**:
```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server ./cmd/server

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
USER 65532:65532
EXPOSE 8080
CMD ["/server"]
```

**Expected Image Size**: 12-20MB (Go binary ~10MB + distroless base)

**Health Check Endpoints**:
- `/healthz` (liveness): Returns 200 if server is running
- `/readyz` (readiness): Returns 200 if server is ready to handle traffic (checks Google Sheets connectivity)

---

## Testing Strategy

**Decision**: Use Go's built-in `testing` package with `httptest` for handler testing

**Rationale**:
- No external testing framework needed (Go standard library is sufficient)
- `httptest.NewRecorder()` and `httptest.NewRequest()` enable isolated handler testing
- Table-driven tests for multiple scenarios
- Easy to mock Google Sheets API responses with `httptest.NewServer()`

**Test Organization**:
```
internal/
├── api/
│   ├── handlers.go
│   └── handlers_test.go      # Handler unit tests
├── sheets/
│   ├── client.go
│   └── client_test.go        # Google Sheets client tests with mocks
└── cache/
    ├── cache.go
    └── cache_test.go          # Cache behavior tests
```

**Handler Testing Pattern**:
```go
func TestGetCategories(t *testing.T) {
    tests := []struct {
        name     string
        method   string
        origin   string
        wantCode int
        wantCORS bool
    }{
        {"valid GET from allowed origin", "GET", "https://lemra-org.github.io", 200, true},
        {"OPTIONS preflight", "OPTIONS", "https://lemra-org.github.io", 200, true},
        {"GET from disallowed origin", "GET", "https://evil.com", 200, false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest(tt.method, "/api/categories", nil)
            req.Header.Set("Origin", tt.origin)
            w := httptest.NewRecorder()
            
            handler.ServeHTTP(w, req)
            
            assert.Equal(t, tt.wantCode, w.Code)
            if tt.wantCORS {
                assert.Equal(t, tt.origin, w.Header().Get("Access-Control-Allow-Origin"))
            }
        })
    }
}
```

**Mocking Google Sheets API**:
- Use `httptest.NewServer()` to create mock Google Sheets responses
- Return sample data for Categories and Questions sheets
- Test error scenarios (API down, rate limits, malformed data)

---

## CI/CD Pipeline

**Decision**: GitHub Actions workflow with automated Fly.io deployment

**Workflow**:
1. **On Push/PR**: Run tests, lint, build verification
2. **On Main Push**: Deploy to Fly.io production

**CI Workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: go mod download
      - run: go test -v ./...
      - run: go vet ./...
      - run: go build ./cmd/server
```

**Deploy Workflow** (`.github/workflows/deploy.yml`):
```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

**Fly.io Configuration** (`fly.toml`):
```toml
app = "essentiel-backend-api"
primary_region = "cdg" # Paris (closest to primary users)

[build]
  dockerfile = "deployments/Dockerfile"

[env]
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

  [[http_service.checks]]
  interval = "15s"
  grace_period = "5s"
  method = "GET"
  path = "/healthz"
  timeout = "5s"
```

---

## Environment Configuration

**Decision**: Use environment variables for all configuration

**Required Environment Variables**:
- `PORT`: HTTP server port (default: 8080)
- `GOOGLE_SERVICE_ACCOUNT_JSON`: Service Account credentials (JSON string)
- `GOOGLE_SPREADSHEET_ID`: Spreadsheet ID to fetch data from
- `ALLOWED_ORIGIN`: CORS allowed origin (default: https://lemra-org.github.io)
- `CACHE_TTL_MINUTES`: Cache TTL in minutes (default: 5)

**Configuration Loading**:
```go
type Config struct {
    Port                    string
    ServiceAccountJSON      string
    SpreadsheetID           string
    AllowedOrigin           string
    CacheTTL                time.Duration
}

func LoadConfig() *Config {
    return &Config{
        Port:               getEnv("PORT", "8080"),
        ServiceAccountJSON: getEnv("GOOGLE_SERVICE_ACCOUNT_JSON", ""),
        SpreadsheetID:      getEnv("GOOGLE_SPREADSHEET_ID", ""),
        AllowedOrigin:      getEnv("ALLOWED_ORIGIN", "https://lemra-org.github.io"),
        CacheTTL:           time.Duration(getEnvInt("CACHE_TTL_MINUTES", 5)) * time.Minute,
    }
}
```

**Secret Management**:
- **Local Development**: Use `.env` file (gitignored) with fake credentials
- **Fly.io Production**: Use `flyctl secrets set` command to inject credentials

---

## Summary

**Primary Technology Stack**:
- **Language**: Go 1.22+
- **HTTP Framework**: Standard library `net/http`
- **CORS**: github.com/rs/cors
- **Google Sheets**: google.golang.org/api/sheets/v4
- **Caching**: github.com/patrickmn/go-cache
- **Deployment**: Fly.io with Docker

**Key Technical Decisions**:
- Fly.io for global edge deployment and zero-downtime updates
- Standard library HTTP (no framework overhead)
- Simple in-memory caching (5-minute TTL)
- Table-driven tests with httptest
- Multi-stage Docker builds (<20MB images)

**No Complex Dependencies**: Intentionally lightweight stack focusing on standard library and proven libraries.
