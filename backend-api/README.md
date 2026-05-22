# Essentiel Backend API

Backend REST API service that provides secure Google Sheets data access for the Essentiel web application.

## Overview

This service acts as a security boundary between the Essentiel web app and Google Sheets, keeping Service Account credentials server-side while exposing public REST endpoints for categories and questions data.

## Features

- **Secure Data Access**: Service Account credentials stay server-side only
- **CORS Support**: Configured for lemra-org.github.io domain
- **Caching**: 5-minute in-memory cache with TTL to reduce Google Sheets API calls
- **Fast Responses**: <100ms for cached data, <2s for fresh fetches
- **Cloud Deployment**: Ready for Fly.io, Cloud Run, or Railway

## API Endpoints

- `GET /api/categories` - Fetch all question categories
- `GET /api/questions` - Fetch all question cards
- `GET /healthz` - Liveness probe
- `GET /readyz` - Readiness probe (checks Google Sheets connectivity)

## Quick Start

### Prerequisites

- Go 1.22 or higher
- Google Cloud Service Account with Sheets API access
- Google Sheets spreadsheet with Categories and Questions sheets

### Installation

```bash
# Install dependencies
go mod download

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# - Set GOOGLE_SPREADSHEET_ID
# - Add Service Account JSON to service-account-dev.json
```

### Running Locally

```bash
# Set Service Account credentials
export GOOGLE_SERVICE_ACCOUNT_JSON=$(cat service-account-dev.json)

# Run the server
go run cmd/server/main.go
```

Server starts on http://localhost:8080

### Testing

```bash
# Test categories endpoint
curl http://localhost:8080/api/categories

# Test questions endpoint
curl http://localhost:8080/api/questions

# Test health check
curl http://localhost:8080/healthz
```

## Project Structure

```
backend-api/
├── cmd/
│   └── server/          # Application entry point
├── internal/
│   ├── api/             # HTTP handlers and routing
│   ├── cache/           # In-memory caching
│   ├── config/          # Configuration management
│   └── sheets/          # Google Sheets client
├── deployments/         # Docker and deployment configs
└── .github/workflows/   # CI/CD pipelines
```

## Deployment

### Fly.io Deployment

The service is configured for deployment to Fly.io with automatic CI/CD via GitHub Actions.

**Initial Setup:**

```bash
# Install Fly.io CLI
brew install flyctl  # macOS
# Or: curl -L https://fly.io/install.sh | sh

# Login
flyctl auth login

# Create app (choose unique name)
flyctl apps create essentiel-backend-api

# Set secrets
flyctl secrets set GOOGLE_SERVICE_ACCOUNT_JSON="$(cat service-account-prod.json)"
flyctl secrets set GOOGLE_SPREADSHEET_ID=your-production-spreadsheet-id
```

**Manual Deployment:**

```bash
# Deploy from local directory
flyctl deploy

# Check status
flyctl status

# View logs
flyctl logs
```

**Automated Deployment:**

Deployments to Fly.io are automatically triggered on push to `main` branch via GitHub Actions.

**Required GitHub Secrets:**

1. Go to repository Settings → Secrets and variables → Actions
2. Add secret:
   - `FLY_API_TOKEN`: Generate with `flyctl auth token`

The deploy workflow will automatically:
- Build the Docker image
- Deploy to Fly.io
- Run health checks

See [quickstart guide](../specs/004-backend-api-service/quickstart.md) for more detailed deployment instructions.

## Documentation

- [Feature Specification](../specs/004-backend-api-service/spec.md)
- [Implementation Plan](../specs/004-backend-api-service/plan.md)
- [REST API Contract](../specs/004-backend-api-service/contracts/rest-api.md)
- [Quickstart Guide](../specs/004-backend-api-service/quickstart.md)
- [Task Breakdown](../specs/004-backend-api-service/tasks.md)

## License

Part of the Essentiel project by lemra-org
