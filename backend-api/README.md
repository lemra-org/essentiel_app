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

**For Flutter Web Development**:
The Essentiel web app requires this backend API to fetch cards and categories. Before running the Flutter web app, you must start the backend using one of the methods below.

### Installation

```bash
# Install dependencies
go mod download

# Copy environment template (if starting from scratch)
cp .env.example .env

# Edit .env with your configuration
# - Set GOOGLE_SPREADSHEET_ID
# - Add Service Account JSON to service-account-dev.json
```

### Running Locally (for Flutter Web Development)

**Option 1: Standalone Go Server** (Recommended for active development)

```bash
# From repository root, navigate to backend-api/
cd backend-api

# Set Service Account credentials
export GOOGLE_SERVICE_ACCOUNT_JSON=$(cat service-account-dev.json)
export GOOGLE_SPREADSHEET_ID=your-spreadsheet-id

# Run the server
go run cmd/server/main.go
```

Server starts on http://localhost:8080

**Option 2: Docker Compose** (Recommended for testing full stack)

```bash
# From repository root
# Ensure .env file exists with required variables
cp .env.example .env

# Edit .env with:
# - GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
# - GOOGLE_SPREADSHEET_ID=your-spreadsheet-id

# Start backend + frontend together
docker compose -f compose.yaml -f compose-dev.yaml up --build

# Backend available at http://localhost:8080/api/*
# Frontend available at http://localhost:8080
```

**Integration with Flutter Web**:

When running `flutter run -d chrome`, the Flutter web dev server will attempt to connect to `http://localhost:8080/api/*` endpoints. Ensure the backend is running before starting the Flutter app.

The backend automatically enables CORS for localhost origins (any port) in development mode, so the Flutter dev server (which uses random ports) can connect without issues.

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
docker build -t essentiel-backend-api -f backend-api/Dockerfile backend-api/

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
