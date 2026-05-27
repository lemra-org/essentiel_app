# Render Deployment Guide

This guide explains how to deploy the full-stack Essentiel app (Flutter web frontend + Go backend) to Render using docker-compose.

## Overview

The project uses a monorepo structure with both frontend and backend deployed together:

- **Frontend**: Flutter web app served via nginx
- **Backend**: Go API with Redis cache
- **Platform**: Render (supports docker-compose, PR previews, free tier)

## Features

✅ **Full stack deployment** - Both frontend and backend from one repo
✅ **Docker-based** - Uses existing docker-compose.yml
✅ **PR previews** - Automatic preview environments for every PR
✅ **Managed Redis** - Built-in Redis cache service
✅ **Auto HTTPS** - Automatic SSL certificates
✅ **Free tier** - 750 hours/month free (starter plan)

---

## Quick Start (First Time Setup)

### 1. Sign up for Render

1. Go to [render.com](https://render.com/)
2. Sign in with GitHub
3. Authorize Render to access `lemra-org/essentiel_app`

### 2. Create Blueprint

1. Click **"New"** → **"Blueprint"**
2. Connect to repository: `lemra-org/essentiel_app`
3. Render auto-detects `render.yaml`
4. Review services:
   - `essentiel-redis` (Private service - Redis cache)
   - `essentiel-backend-api` (Web service - Go API)
   - `essentiel-frontend` (Web service - Flutter web)

### 3. Configure Secrets

Before deploying, add these environment variables in the Render dashboard:

**For `essentiel-backend-api`**:

1. Go to service settings → Environment
2. Add secret variables:
   - `GOOGLE_SERVICE_ACCOUNT_JSON`: Paste the full JSON credentials
   - `GOOGLE_SPREADSHEET_ID`: Your Google Sheets ID

**Note**: Other env vars are configured in `render.yaml` automatically.

### 4. Deploy

1. Click **"Apply"** to create all services
2. Render will:
   - Build Docker images for frontend and backend
   - Deploy Redis cache
   - Start all services with health checks
   - Assign URLs (e.g., `essentiel-frontend.onrender.com`)

**Build time**: ~5-10 minutes for first deployment

### 5. Update CORS Configuration

After frontend is deployed, update the backend's `ALLOWED_ORIGIN`:

1. Go to `essentiel-backend-api` service settings
2. Update `ALLOWED_ORIGIN` env var to your frontend URL
3. Example: `https://essentiel-frontend.onrender.com`

---

## PR Preview Environments

### How It Works

Every PR automatically gets:
- Unique preview URLs for frontend and backend
- Isolated Redis instance
- Auto-cleanup after 7 days or when PR closes

### Preview URLs

Format:
- Frontend: `essentiel-frontend-pr-224.onrender.com`
- Backend: `essentiel-backend-api-pr-224.onrender.com`

### Preview Configuration

Preview environments use:
- **Frontend**: `web_dev.dart` environment (dev backend URL)
- **Backend**: CORS allows all origins (`ALLOWED_ORIGIN=*`)

### Testing a PR Preview

1. Open the PR on GitHub
2. Render automatically builds and deploys
3. Check the Render dashboard for preview URLs
4. Click the frontend URL to test
5. Preview persists for 7 days or until PR closes/merges

---

## Local Development

### Prerequisites

- Docker & Docker Compose
- Git

### Run Full Stack Locally

1. **Clone repository**:
   ```bash
   git clone https://github.com/lemra-org/essentiel_app.git
   cd essentiel_app
   ```

2. **Set environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your Google credentials
   ```

3. **Start all services** (development mode - builds from source):
   ```bash
   docker compose -f compose-dev.yaml up --build
   ```

4. **Access**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - Redis: localhost:6379

5. **Stop services**:
   ```bash
   docker compose -f compose-dev.yaml down
   ```

### Development Workflow

```bash
# Rebuild after code changes
docker compose -f compose-dev.yaml up --build

# View logs
docker compose -f compose-dev.yaml logs -f frontend
docker compose -f compose-dev.yaml logs -f backend-api

# Run only specific service
docker compose -f compose-dev.yaml up frontend
```

### Test with Production Images

```bash
# Pull and run production images from ghcr.io
docker compose pull
docker compose up
```

---

## Project Structure

```
essentiel_app/
├── backend-api/              # Go backend API
│   ├── Dockerfile           # Backend Docker build
│   ├── cmd/server/          # API entry point
│   └── internal/            # Business logic
├── lib/                     # Flutter source code
│   ├── environments/        # Environment configs
│   │   ├── web_dev.dart    # Dev environment
│   │   └── web_prod.dart   # Production environment
│   └── services/
│       └── backend_api_service.dart
├── web/                     # Flutter web assets
├── Dockerfile               # Frontend Docker build
├── nginx.conf              # Frontend nginx config
├── compose.yaml            # Production (pre-built images)
├── compose-dev.yaml        # Development (local build)
└── render.yaml             # Render deployment blueprint
```

---

## Architecture

### Services

1. **essentiel-redis** (Private Service)
   - Redis 7 Alpine
   - Caching layer for backend
   - Not exposed publicly

2. **essentiel-backend-api** (Web Service)
   - Go API server
   - Fetches data from Google Sheets
   - Caches responses in Redis
   - Exposes REST API at `/api/categories`, `/api/questions`

3. **essentiel-frontend** (Web Service)
   - Flutter web app
   - Served via nginx
   - Connects to backend API
   - PWA with offline support

### Request Flow

```
User Browser
    ↓
Frontend (nginx on Render)
    ↓ HTTP requests to /api/*
Backend API (Go on Render)
    ↓ Cache check
Redis (on Render)
    ↓ Cache miss
Google Sheets API
```

---

## Configuration Details

### Environment Variables

#### Frontend (`essentiel-frontend`)

| Variable | Value | Description |
|----------|-------|-------------|
| `BUILD_ENV` | `prod` / `dev` | Flutter environment file |
| `BACKEND_API_URL` | Auto-set | Backend service URL |

#### Backend (`essentiel-backend-api`)

| Variable | Value | Description |
|----------|-------|-------------|
| `PORT` | `8080` | API server port |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Secret | Google credentials JSON |
| `GOOGLE_SPREADSHEET_ID` | Secret | Google Sheets ID |
| `ALLOWED_ORIGIN` | Frontend URL | CORS whitelist |
| `CACHE_TTL_MINUTES` | `5` | Redis cache TTL |
| `REDIS_ADDR` | Auto-set | Redis service address |

### Health Checks

- **Frontend**: `GET /healthz` (nginx endpoint)
- **Backend**: `GET /healthz` (API endpoint)
- **Redis**: `redis-cli ping`

---

## Deployment Workflow

### Production Deployment

1. Merge PR to `main` branch
2. Render auto-deploys from `main`
3. Both frontend and backend redeploy
4. Zero-downtime deployment with health checks

### Manual Deploy

1. Go to Render dashboard
2. Select service (frontend or backend)
3. Click **"Manual Deploy"** → **"Deploy latest commit"**

### Rollback

1. Go to Render dashboard
2. Select service
3. Click **"Rollback"** and choose a previous deployment

---

## Monitoring

### Logs

View logs in Render dashboard:
- Navigate to service
- Click **"Logs"** tab
- Real-time streaming logs

### Metrics

Free tier includes:
- CPU usage
- Memory usage
- Request count
- Response times
- Health check status

---

## Troubleshooting

### Build Failures

**Frontend build fails**:
```bash
# Check Flutter version in Dockerfile matches .tool-versions
# Current: Flutter 3.22.3
```

**Backend build fails**:
```bash
# Check Go version in backend-api/Dockerfile
# Current: Go 1.26
```

### CORS Errors

**Symptom**: Frontend can't reach backend API

**Solution**:
1. Check backend `ALLOWED_ORIGIN` env var
2. Update to match frontend URL exactly
3. For previews, use `ALLOWED_ORIGIN=*`

### Redis Connection Issues

**Symptom**: Backend logs show Redis connection errors

**Solution**:
1. Check `REDIS_ADDR` is set correctly (auto-set by Render)
2. Verify Redis service is running in dashboard
3. Check health check status

### Preview Environment Not Working

**Symptom**: PR preview URL returns 404

**Solution**:
1. Check Render dashboard for build logs
2. Verify `previewsEnabled: true` in render.yaml
3. Ensure branch is not blocked (only PRs trigger previews)

---

## Costs

### Free Tier Limits

Render free tier includes:
- **750 hours/month** across all services
- **100 GB bandwidth/month**
- **Automatic sleep** after 15min inactivity
- **Cold start** ~30s when sleeping

### Cost Optimization

1. **Use starter plan for production** ($7/month per service)
   - No sleep
   - Faster scaling
   - Better performance

2. **Limit preview environments**
   - Set `previewsExpireAfterDays: 7`
   - Auto-cleanup on PR close

3. **Share Redis instance**
   - One Redis serves both frontend and backend

---

## Custom Domain

### Setup

1. Go to `essentiel-frontend` service settings
2. Click **"Custom Domains"**
3. Add your domain (e.g., `app.essentiel.app`)
4. Update DNS records as instructed
5. Render provisions SSL automatically

### DNS Configuration

Add CNAME record:
```
app.essentiel.app  →  essentiel-frontend.onrender.com
```

### Update Backend CORS

After custom domain setup:
```bash
# Update backend ALLOWED_ORIGIN
ALLOWED_ORIGIN=https://app.essentiel.app
```

---

## CI/CD Integration

Render auto-deploys from GitHub, but you can enhance with GitHub Actions:

### Optional: Pre-deploy Checks

Create `.github/workflows/render-deploy.yml`:

```yaml
name: Pre-deploy Checks

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate docker-compose
        run: docker-compose config
      
      - name: Validate render.yaml
        run: |
          # Add render.yaml validation if needed
          cat render.yaml
```

---

## Next Steps

1. ✅ Set up Render account and connect GitHub
2. ✅ Configure secrets (Google credentials)
3. ✅ Deploy blueprint
4. ✅ Test production deployment
5. ✅ Create a test PR to verify preview environments
6. ⚠️ Consider custom domain for production
7. ⚠️ Upgrade to paid plan for better performance

---

## Support

- **Render Docs**: https://render.com/docs
- **Render Status**: https://status.render.com
- **Project Issues**: https://github.com/lemra-org/essentiel_app/issues
