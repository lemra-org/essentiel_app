# Essentiel Backend API

Backend REST API service that provides secure Google Sheets data access for the Essentiel web application.

## Overview

This service acts as a security boundary between the Essentiel web app and Google Sheets, keeping Service Account credentials server-side while exposing public REST endpoints for categories and questions data.

## Features

- **Secure Data Access**: Service Account credentials stay server-side only
- **CORS Support**: Configured for lemra-org.github.io domain
- **Caching**: 5-minute in-memory cache with TTL to reduce Google Sheets API calls
- **Fast Responses**: <100ms for cached data, <2s for fresh fetches
- **Docker Deployment**: Containerized with Docker Compose support

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

### Docker Deployment

The service is containerized and can be deployed using Docker Compose.

**Using Docker Compose (from repository root):**

Docker Compose pulls the pre-built image from GitHub Container Registry (no local build required):

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your credentials
# Start all services (pulls image from ghcr.io)
docker-compose up -d

# View logs
docker-compose logs -f backend-api

# Stop services
docker-compose down
```

**Environment Configuration:**

Create a `.env` file at the repository root:

```env
# Image to use (optional, defaults to latest)
BACKEND_API_IMAGE=ghcr.io/lemra-org/essentiel-backend-api:latest

# Required configuration
GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id

# Optional configuration
ALLOWED_ORIGIN=https://lemra-org.github.io
CACHE_TTL_MINUTES=5
```

**Manual Docker Build:**

```bash
# Build image
docker build -t essentiel-backend-api -f backend-api/deployments/Dockerfile backend-api/

# Run container
docker run -p 8080:8080 \
  -e GOOGLE_SERVICE_ACCOUNT_JSON="$(cat service-account-dev.json)" \
  -e GOOGLE_SPREADSHEET_ID=your-spreadsheet-id \
  essentiel-backend-api
```

**Container Registry:**

The CI/CD pipeline automatically builds and pushes images to GitHub Container Registry (ghcr.io):

```bash
# Pull latest image
docker pull ghcr.io/lemra-org/essentiel-backend-api:latest

# Run pulled image
docker run -p 8080:8080 \
  -e GOOGLE_SERVICE_ACCOUNT_JSON="..." \
  -e GOOGLE_SPREADSHEET_ID=your-id \
  ghcr.io/lemra-org/essentiel-backend-api:latest
```

See [quickstart guide](../specs/004-backend-api-service/quickstart.md) for more detailed deployment instructions.

## Documentation

- [Feature Specification](../specs/004-backend-api-service/spec.md)
- [Implementation Plan](../specs/004-backend-api-service/plan.md)
- [REST API Contract](../specs/004-backend-api-service/contracts/rest-api.md)
- [Quickstart Guide](../specs/004-backend-api-service/quickstart.md)
- [Task Breakdown](../specs/004-backend-api-service/tasks.md)

## License

Part of the Essentiel project by lemra-org
