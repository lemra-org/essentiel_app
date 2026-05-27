# Docker Compose Local Development

This guide explains how to run the full Essentiel stack locally using Docker Compose.

## Compose Files

The project uses Docker Compose's **overlay pattern**:

- **`compose.yaml`** - Base configuration with all service definitions
  - Uses pre-built images from `ghcr.io/lemra-org/*`
  - For production deployment or testing released versions

- **`compose-dev.yaml`** - Development overlay
  - Overrides `image` with local `build` instructions
  - Extends `compose.yaml` (doesn't duplicate config)
  - For active development with local source code

## Quick Start (Development)

Build from local source:

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env with your Google credentials
nano .env  # or your favorite editor

# 3. Start all services (builds from source)
docker compose -f compose.yaml -f compose-dev.yaml up --build

# 4. Access the app
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8080
# - Redis: localhost:6379
```

## Quick Start (Production Images)

Use pre-built images:

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env with your Google credentials
nano .env

# 3. Pull and start pre-built images
docker compose pull
docker compose up -d

# 4. Access the app
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8080
# - Redis: localhost:6379
```

## Services

The docker-compose setup includes three services:

### 1. Frontend (Flutter Web)
- **Port**: 3000
- **Image**: Built from `./Dockerfile`
- **Environment**: Configurable via `BUILD_ENV` (dev/prod)
- **Depends on**: backend-api

### 2. Backend API (Go)
- **Port**: 8080
- **Image**: Built from `./backend-api/Dockerfile`
- **Environment**: Configurable via `.env`
- **Depends on**: redis

### 3. Redis Cache
- **Port**: 6379
- **Image**: redis:7-alpine
- **Purpose**: Caches Google Sheets data

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Build environment for frontend
BUILD_ENV=dev  # or prod

# Google Sheets credentials (required)
GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id

# CORS (frontend origin)
ALLOWED_ORIGIN=http://localhost:3000

# Cache TTL
CACHE_TTL_MINUTES=5

# Backend URL for frontend
BACKEND_API_URL=http://localhost:8080
```

## Common Commands

### Development (Local Source)

```bash
# Start services (build from source)
docker compose -f compose.yaml -f compose-dev.yaml up --build

# Start in background
docker compose -f compose.yaml -f compose-dev.yaml up -d

# Rebuild after code changes
docker compose -f compose.yaml -f compose-dev.yaml up --build

# Rebuild specific service only
docker compose -f compose.yaml -f compose-dev.yaml up --build frontend
```

### Production (Pre-built Images)

```bash
# Pull and start latest images
docker compose pull
docker compose up -d

# Update to newer images
docker compose pull
docker compose up -d
```

### Common Commands (Both Modes)

```bash
# View logs (all services)
docker compose logs -f

# View logs for specific service
docker compose logs -f frontend
docker compose logs -f backend-api

# Check service health
docker compose ps

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v

# Restart a service
docker compose restart frontend

# Execute command in container
docker compose exec backend-api sh
docker compose exec frontend sh
```

## Development Workflow

### Making Frontend Changes

1. Edit files in `lib/`, `web/`, or `pubspec.yaml`
2. Rebuild frontend:
   ```bash
   docker compose -f compose.yaml -f compose-dev.yaml up --build frontend
   ```
3. Refresh browser at http://localhost:3000

### Making Backend Changes

1. Edit files in `backend-api/`
2. Rebuild backend:
   ```bash
   docker compose -f compose.yaml -f compose-dev.yaml up --build backend-api
   ```
3. Backend restarts automatically

### Switching Environments

```bash
# Use development environment (default)
BUILD_ENV=dev docker compose -f compose.yaml -f compose-dev.yaml up --build frontend

# Use production environment
BUILD_ENV=prod docker compose -f compose.yaml -f compose-dev.yaml up --build frontend
```

### Testing Production Images Locally

```bash
# Pull latest production images
docker compose pull

# Run with production images
docker compose up -d

# Useful for verifying images before deployment
```

## Health Checks

All services include health checks:

```bash
# Check service health
docker-compose ps

# Example output:
# NAME                STATUS              PORTS
# frontend            Up (healthy)        0.0.0.0:3000->80/tcp
# backend-api         Up (healthy)        0.0.0.0:8080->8080/tcp
# redis               Up (healthy)        0.0.0.0:6379->6379/tcp
```

## Troubleshooting

### Frontend not loading

```bash
# Check frontend logs
docker-compose logs frontend

# Common issues:
# - Backend not healthy (frontend depends on it)
# - Build failed (check Flutter version in Dockerfile)
```

### Backend API errors

```bash
# Check backend logs
docker-compose logs backend-api

# Common issues:
# - Invalid Google credentials in .env
# - Redis not connected (check REDIS_ADDR)
# - CORS errors (check ALLOWED_ORIGIN)
```

### Redis connection issues

```bash
# Check Redis is running
docker-compose ps redis

# Test Redis connection
docker-compose exec redis redis-cli ping
# Should return: PONG

# Check backend can reach Redis
docker-compose exec backend-api wget -O- http://localhost:8080/healthz
```

### Port conflicts

If ports 3000, 8080, or 6379 are already in use:

```bash
# Edit docker-compose.yml to use different ports:
services:
  frontend:
    ports:
      - "3001:80"  # Changed from 3000
  backend-api:
    ports:
      - "8081:8080"  # Changed from 8080
  redis:
    ports:
      - "6380:6379"  # Changed from 6379
```

### Clean rebuild

**Development:**
```bash
# Remove all containers, volumes, and images
docker compose down -v --rmi all

# Rebuild from scratch
docker compose -f compose.yaml -f compose-dev.yaml up --build
```

**Production:**
```bash
# Remove containers and volumes
docker compose down -v

# Pull fresh images
docker compose pull
docker compose up -d
```

## Architecture

```
┌─────────────────────────────────────────┐
│  User Browser                           │
└────────────────┬────────────────────────┘
                 │
                 │ HTTP
                 ▼
┌─────────────────────────────────────────┐
│  Frontend (nginx:alpine)                │
│  Port: 3000                             │
│  - Flutter web build                    │
│  - Serves static files                  │
│  - Proxies API calls to backend         │
└────────────────┬────────────────────────┘
                 │
                 │ /api/* requests
                 ▼
┌─────────────────────────────────────────┐
│  Backend API (Go)                       │
│  Port: 8080                             │
│  - REST API endpoints                   │
│  - Google Sheets integration            │
│  - Redis caching                        │
└────────────────┬────────────────────────┘
                 │
                 │ Cache check/set
                 ▼
┌─────────────────────────────────────────┐
│  Redis (redis:7-alpine)                 │
│  Port: 6379                             │
│  - In-memory cache                      │
│  - 5-minute TTL                         │
└─────────────────────────────────────────┘
```

## Network

All services run on the `essentiel-network` bridge network:

```bash
# Inspect network
docker network inspect essentiel_essentiel-network

# Services can communicate using service names:
# - frontend → backend-api:8080
# - backend-api → redis:6379
```

## Volumes

By default, no persistent volumes are created. Data is lost when containers stop.

To persist Redis data:

```yaml
# Add to docker-compose.yml
services:
  redis:
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

## Production Use

For production deployment on your own server:

### 1. Build and Push Images

```bash
# Build production images using dev overlay
docker compose -f compose.yaml -f compose-dev.yaml build

# Tag for registry
docker tag essentiel-frontend:dev ghcr.io/lemra-org/essentiel-frontend:latest
docker tag essentiel-backend-api:dev ghcr.io/lemra-org/essentiel-backend-api:latest

# Push to GitHub Container Registry
docker push ghcr.io/lemra-org/essentiel-frontend:latest
docker push ghcr.io/lemra-org/essentiel-backend-api:latest
```

### 2. Deploy on Server

```bash
# On your production server
git clone https://github.com/lemra-org/essentiel_app.git
cd essentiel_app

# Set up environment
cp .env.example .env
nano .env  # Add your credentials

# Pull and run production images
docker compose pull
docker compose up -d
```

### 3. Set Up Reverse Proxy (Optional)

Use nginx or Traefik on your server to:
- Add HTTPS (Let's Encrypt)
- Route domain to frontend container
- Example: `app.yourdomain.com` → `localhost:3000`

## See Also

- [Backend Proxy Configuration](BACKEND_PROXY.md) - nginx proxy details
- [Backend API README](../backend-api/README.md) - Backend documentation
- [CLAUDE.md](../CLAUDE.md) - Development commands
