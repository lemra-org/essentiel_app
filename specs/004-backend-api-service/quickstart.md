# Quickstart Guide: Backend API Service

**Feature**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Date**: 2026-05-22

## Prerequisites

Before starting development:

1. **Go 1.22+**: Install from [go.dev/dl](https://go.dev/dl/) or use asdf
2. **Git**: For version control
3. **Google Cloud**: Service Account with Google Sheets API access (see [Credentials Setup](#credentials-setup))
4. **Docker**: For local containerization and deployment testing (optional)
5. **Fly.io CLI**: For deployment (`brew install flyctl` or see [fly.io/docs](https://fly.io/docs/hands-on/install-flyctl/))

---

## Quick Start (5 minutes)

### 1. Create Project Structure

```bash
# Create project directory
mkdir essentiel-backend-api
cd essentiel-backend-api

# Initialize Go module
go mod init github.com/lemra-org/essentiel-backend-api

# Create directory structure
mkdir -p cmd/server internal/{api,cache,config,sheets} deployments
```

### 2. Install Dependencies

```bash
# Core dependencies
go get google.golang.org/api/sheets/v4
go get golang.org/x/oauth2/google
go get github.com/rs/cors
go get github.com/patrickmn/go-cache
```

### 3. Create Configuration

Create `.env.example`:
```bash
PORT=8080
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id-here
ALLOWED_ORIGIN=https://lemra-org.github.io
CACHE_TTL_MINUTES=5
```

Copy to `.env` for local development:
```bash
cp .env.example .env
```

### 4. Service Account Setup (Development)

For local development, you have two options:

**Option A**: Use test/fake credentials (recommended for MVP)
```bash
# Create a dummy service account JSON for development
cat > service-account-dev.json <<EOF
{
  "type": "service_account",
  "project_id": "essentiel-dev",
  "private_key_id": "fake-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nFAKE\n-----END PRIVATE KEY-----\n",
  "client_email": "dev@essentiel-dev.iam.gserviceaccount.com"
}
EOF

# Add to .gitignore
echo "service-account*.json" >> .gitignore
echo ".env" >> .gitignore
```

**Option B**: Use real credentials (if you have a test spreadsheet)
1. Create a Service Account in Google Cloud Console
2. Enable Google Sheets API
3. Download JSON key file → save as `service-account-dev.json`
4. Share your test spreadsheet with the service account email

### 5. Run Development Server

```bash
# Set environment variable pointing to service account JSON
export GOOGLE_SERVICE_ACCOUNT_JSON=$(cat service-account-dev.json)

# Run the server
go run cmd/server/main.go
```

**Expected output**:
```
Server starting on :8080
Caching enabled with 5-minute TTL
CORS configured for: https://lemra-org.github.io
```

### 6. Test Endpoints

```bash
# Test categories endpoint
curl http://localhost:8080/api/categories

# Test questions endpoint
curl http://localhost:8080/api/questions

# Test health check
curl http://localhost:8080/healthz
```

---

## Development Workflow

### Project Structure

```
essentiel-backend-api/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── api/
│   │   ├── handlers.go          # HTTP request handlers
│   │   ├── handlers_test.go     # Handler tests
│   │   ├── middleware.go        # CORS, logging middleware
│   │   └── router.go            # Route configuration
│   ├── cache/
│   │   ├── cache.go             # In-memory caching
│   │   └── cache_test.go        # Cache tests
│   ├── config/
│   │   └── config.go            # Environment configuration
│   └── sheets/
│       ├── client.go            # Google Sheets API client
│       ├── client_test.go       # Client tests with mocks
│       └── models.go            # Category, Question structs
├── deployments/
│   ├── Dockerfile               # Multi-stage Docker build
│   └── fly.toml                 # Fly.io deployment config
├── .github/
│   └── workflows/
│       ├── ci.yml               # Run tests, lint on push/PR
│       └── deploy.yml           # Deploy to Fly.io on main push
├── go.mod                       # Go module dependencies
├── go.sum                       # Dependency checksums
├── .env.example                 # Environment variable template
├── .gitignore                   # Git ignore patterns
└── README.md                    # Service documentation
```

### Implementing Handlers

**Example**: `internal/api/handlers.go`
```go
package api

import (
    "encoding/json"
    "net/http"
    "github.com/lemra-org/essentiel-backend-api/internal/sheets"
)

func GetCategories(w http.ResponseWriter, r *http.Request) {
    categories, err := sheets.FetchCategories()
    if err != nil {
        http.Error(w, `{"error":"Unable to fetch data from source"}`, http.StatusServiceUnavailable)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.Header().Set("Cache-Control", "public, max-age=300")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "categories": categories,
    })
}
```

### Running Tests

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with verbose output
go test -v ./...

# Run specific package tests
go test ./internal/api

# Run tests in watch mode (requires entr)
find . -name '*.go' | entr go test ./...
```

### Code Quality

```bash
# Format code
go fmt ./...

# Lint code (requires golangci-lint)
golangci-lint run

# Vet code
go vet ./...

# Check for security issues (requires gosec)
gosec ./...
```

---

## Google Sheets Setup

### Spreadsheet Structure

Your Google Sheets spreadsheet must have this structure:

**Sheet 1: Categories**
```
| Catégorie       | Couleur  |
|-----------------|----------|
| Famille         | #FF9800  |
| Parent - Enfant | #9C27B0  |
| Couple          | #E91E63  |
```

**Sheet 2: Questions**
```
| Question                        | Catégorie       | Pour Couples | Pour Familles |
|---------------------------------|-----------------|--------------|---------------|
| Quelle est ta plus grande...   | Famille         | Non          | Oui           |
| Qu'est-ce qui te fait...        | Couple          | Oui          | Non           |
```

### Service Account Permissions

1. Create a Service Account in Google Cloud Console
2. Enable Google Sheets API for your project
3. Download JSON key file
4. Share the spreadsheet with the service account email address:
   - Open spreadsheet → Share
   - Add service account email (e.g., `essentiel-api@project.iam.gserviceaccount.com`)
   - Grant "Viewer" permission (read-only)

### Get Spreadsheet ID

The spreadsheet ID is in the URL:
```
https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit
```

Add it to your `.env` file:
```bash
GOOGLE_SPREADSHEET_ID=1a2b3c4d5e6f7g8h9i0j
```

---

## Local Development

### Environment Variables

Create a `.env` file with these variables:

```bash
# Server Configuration
PORT=8080

# Google Sheets Configuration
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id
# GOOGLE_SERVICE_ACCOUNT_JSON is loaded from file, not .env

# CORS Configuration
ALLOWED_ORIGIN=https://lemra-org.github.io

# Cache Configuration
CACHE_TTL_MINUTES=5
```

### Loading Service Account Credentials

**Development**: Load from file
```bash
export GOOGLE_SERVICE_ACCOUNT_JSON=$(cat service-account-dev.json)
go run cmd/server/main.go
```

**Production**: Injected via secret management (Fly.io secrets)

### Hot Reload (Optional)

Install `air` for automatic reloading:
```bash
go install github.com/cosmtrek/air@latest

# Create .air.toml configuration
air init

# Run with hot reload
air
```

### Debugging

```bash
# Run with delve debugger
dlv debug cmd/server/main.go

# Set breakpoint and run
(dlv) break main.main
(dlv) continue
```

---

## Testing

### Unit Tests

**Example**: `internal/api/handlers_test.go`
```go
package api

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestGetCategories(t *testing.T) {
    tests := []struct {
        name     string
        origin   string
        wantCode int
        wantCORS bool
    }{
        {
            name:     "allowed origin",
            origin:   "https://lemra-org.github.io",
            wantCode: 200,
            wantCORS: true,
        },
        {
            name:     "disallowed origin",
            origin:   "https://evil.com",
            wantCode: 200,
            wantCORS: false,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest("GET", "/api/categories", nil)
            req.Header.Set("Origin", tt.origin)
            w := httptest.NewRecorder()
            
            GetCategories(w, req)
            
            if w.Code != tt.wantCode {
                t.Errorf("got %d, want %d", w.Code, tt.wantCode)
            }
            
            if tt.wantCORS {
                cors := w.Header().Get("Access-Control-Allow-Origin")
                if cors != tt.origin {
                    t.Errorf("missing CORS header")
                }
            }
        })
    }
}
```

### Integration Tests

**Mock Google Sheets API**:
```go
func TestSheetsClientIntegration(t *testing.T) {
    // Create mock Google Sheets server
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{
            "values": [
                ["Catégorie", "Couleur"],
                ["Famille", "#FF9800"]
            ]
        }`))
    }))
    defer server.Close()
    
    // Test client against mock server
    // ... test implementation
}
```

### Contract Tests

Verify API responses match the contract defined in `contracts/rest-api.md`:
```go
func TestCategoriesContract(t *testing.T) {
    // Test response structure
    // Test required fields
    // Test data types
}
```

---

## Building & Deployment

### Local Docker Build

Create `deployments/Dockerfile`:
```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

# Runtime stage
FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/server /server

USER 65532:65532
EXPOSE 8080

CMD ["/server"]
```

Build and run:
```bash
# Build Docker image
docker build -t essentiel-backend-api -f deployments/Dockerfile .

# Run container
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e GOOGLE_SERVICE_ACCOUNT_JSON="$(cat service-account-dev.json)" \
  -e GOOGLE_SPREADSHEET_ID=your-id \
  essentiel-backend-api
```

### Fly.io Deployment

#### Initial Setup

```bash
# Install Fly.io CLI
brew install flyctl  # macOS
# Or: curl -L https://fly.io/install.sh | sh

# Login to Fly.io
flyctl auth login

# Create app (choose a unique name)
flyctl apps create essentiel-backend-api
```

#### Configure Secrets

```bash
# Set Service Account credentials
flyctl secrets set GOOGLE_SERVICE_ACCOUNT_JSON="$(cat service-account-prod.json)"

# Set Spreadsheet ID
flyctl secrets set GOOGLE_SPREADSHEET_ID=your-production-spreadsheet-id
```

#### Deploy

```bash
# Deploy from local directory
flyctl deploy

# Check deployment status
flyctl status

# View logs
flyctl logs

# Open in browser
flyctl open
```

#### Configuration (`deployments/fly.toml`)

```toml
app = "essentiel-backend-api"
primary_region = "cdg"  # Paris

[build]
  dockerfile = "deployments/Dockerfile"

[env]
  PORT = "8080"
  ALLOWED_ORIGIN = "https://lemra-org.github.io"
  CACHE_TTL_MINUTES = "5"

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

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

---

## CI/CD Pipeline

### GitHub Actions Workflows

**CI Workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Install dependencies
        run: go mod download
      
      - name: Run tests
        run: go test -v -cover ./...
      
      - name: Run vet
        run: go vet ./...
      
      - name: Build
        run: go build ./cmd/server
```

**Deploy Workflow** (`.github/workflows/deploy.yml`):
```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: superfly/flyctl-actions/setup-flyctl@master
      
      - name: Deploy to Fly.io
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Setup GitHub Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add `FLY_API_TOKEN`:
   ```bash
   # Generate Fly.io token
   flyctl auth token
   
   # Add to GitHub secrets
   ```

---

## Monitoring & Debugging

### View Logs

```bash
# Fly.io logs
flyctl logs

# Tail logs in real-time
flyctl logs -a essentiel-backend-api

# Filter by instance
flyctl logs -i <instance-id>
```

### Performance Monitoring

```bash
# Check service metrics
flyctl metrics

# View current instances
flyctl status

# Scale instances
flyctl scale count 2  # Run 2 instances
```

### Health Checks

```bash
# Check liveness
curl https://essentiel-backend-api.fly.dev/healthz

# Check readiness (verifies Google Sheets connectivity)
curl https://essentiel-backend-api.fly.dev/readyz
```

---

## Troubleshooting

### Issue: CORS Errors in Browser

**Symptoms**: Browser console shows CORS policy errors

**Solution**:
1. Verify `ALLOWED_ORIGIN` environment variable matches web app domain exactly
2. Check CORS middleware configuration in code
3. Test with curl to verify CORS headers are present:
   ```bash
   curl -H "Origin: https://lemra-org.github.io" \
     -I https://essentiel-backend-api.fly.dev/api/categories
   ```

### Issue: Google Sheets API Authentication Failed

**Symptoms**: 500 errors, logs show authentication failures

**Solutions**:
1. Verify Service Account JSON is valid
2. Check spreadsheet is shared with service account email
3. Ensure Google Sheets API is enabled in Google Cloud project
4. Verify `GOOGLE_SPREADSHEET_ID` is correct

### Issue: Cache Not Working

**Symptoms**: Every request triggers Google Sheets fetch

**Debug**:
```go
// Add logging to cache operations
func (c *Cache) Get(key string) (interface{}, bool) {
    log.Printf("Cache GET: %s", key)
    data, found := c.cache.Get(key)
    log.Printf("Cache hit: %v", found)
    return data, found
}
```

### Issue: Slow Response Times

**Symptoms**: Responses take >2s consistently

**Debug**:
1. Check Google Sheets API latency (add timing logs)
2. Verify cache is enabled and working
3. Check Fly.io region vs user location
4. Profile with Go's `pprof`:
   ```go
   import _ "net/http/pprof"
   // Access http://localhost:8080/debug/pprof/
   ```

---

## Summary Checklist

Before deployment:

- [ ] Go 1.22+ installed
- [ ] Dependencies installed (`go mod download`)
- [ ] Service Account created and spreadsheet shared
- [ ] Environment variables configured (`.env` for local)
- [ ] Tests passing (`go test ./...`)
- [ ] Docker build successful
- [ ] Fly.io app created
- [ ] Secrets configured on Fly.io
- [ ] CI/CD workflows configured
- [ ] Health checks responding
- [ ] CORS working for web app domain

**Estimated setup time**: 30-60 minutes (including Google Cloud configuration)
