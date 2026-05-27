# Backend API Proxy Configuration

This document explains how the frontend communicates with the backend API using an nginx reverse proxy.

## Problem

Flutter web apps are compiled to static JavaScript. Any backend URLs are hardcoded into the compiled code, making it impossible to change them at deployment time without rebuilding.

## Solution

The frontend uses an **nginx reverse proxy** to route API requests:

1. Flutter app makes requests to `/api/*` (relative URL, same origin)
2. nginx intercepts these requests and proxies them to the backend service
3. Backend URL is configured via `BACKEND_URL` environment variable at container startup
4. Works across all environments (local, preview, production)

## Architecture

```
┌─────────────────────────────────────────┐
│  User Browser                           │
│  https://essentiel-frontend.onrender.com│
└────────────────┬────────────────────────┘
                 │
                 │ GET /api/categories
                 ▼
┌─────────────────────────────────────────┐
│  Frontend Container (nginx)             │
│  - Serves Flutter static files          │
│  - Proxies /api/* to backend            │
└────────────────┬────────────────────────┘
                 │
                 │ Proxies to: ${BACKEND_URL}/api/categories
                 ▼
┌─────────────────────────────────────────┐
│  Backend Container (Go API)             │
│  - Handles Google Sheets integration    │
│  - Returns JSON data                    │
└─────────────────────────────────────────┘
```

## Implementation Details

### 1. Flutter Code (web_prod.dart, web_dev.dart)

Uses **empty string** for backend URL (relative paths):

```dart
class WebProd extends Env {
  final String backendApiUrl = '';  // Empty = same origin
}
```

This means API calls go to:
- `/api/categories` (not `http://backend:8080/api/categories`)
- `/api/questions`

### 2. nginx Configuration (nginx.conf)

Proxies `/api/*` requests to backend:

```nginx
location /api/ {
    proxy_pass ${BACKEND_URL}/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

The `${BACKEND_URL}` variable is substituted at container startup.

### 3. Docker Entrypoint (docker-entrypoint.sh)

Substitutes environment variables into nginx config:

```bash
#!/bin/sh
BACKEND_URL=${BACKEND_URL:-http://backend-api:8080}
envsubst '${BACKEND_URL}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
exec nginx -g 'daemon off;'
```

### 4. Environment Configuration

**Local Development (docker-compose):**
```yaml
environment:
  - BACKEND_URL=http://backend-api:8080
```

**Production (Self-hosted):**
```yaml
environment:
  - BACKEND_URL=http://backend-api:8080
```

The backend service name (`backend-api`) is resolvable within the Docker network.

## Request Flow Example

### 1. Frontend Makes Request

```dart
// In Flutter code
final response = await http.get(
  Uri.parse('${Env.value!.backendApiUrl}/api/categories')
);

// Since backendApiUrl = '', this becomes:
// GET /api/categories
```

### 2. Browser Sends Request

```
GET https://app.yourdomain.com/api/categories
```

### 3. nginx Proxies Request

nginx receives request and proxies to backend:

```
GET http://backend-api:8080/api/categories
```

### 4. Backend Responds

```json
{
  "categories": [
    {"id": 1, "name": "Category 1"}
  ]
}
```

### 5. nginx Returns Response

Response flows back through nginx to browser.

## Benefits

✅ **No hardcoded URLs** - Backend URL configurable at deployment
✅ **Internal networking** - Render services communicate via fast internal network
✅ **Security** - Backend not exposed publicly (only frontend is)
✅ **Flexibility** - Easy to change backend URL without rebuilding frontend
✅ **CORS-free** - All requests appear to come from same origin
✅ **Works everywhere** - Same approach for dev, preview, production

## Environment-Specific URLs

| Environment | BACKEND_URL | How It's Set |
|-------------|-------------|--------------|
| **Docker Compose (Dev)** | `http://backend-api:8080` | `.env` file or default |
| **Production (Self-hosted)** | `http://backend-api:8080` | `.env` file or default |

## CORS Configuration

Since requests are proxied through the same origin, CORS is still needed but simplified:

**Backend ALLOWED_ORIGIN:**
- Local: `http://localhost:3000`
- Production: `https://app.yourdomain.com`

Set via `ALLOWED_ORIGIN` environment variable in `.env` or compose file.

## Testing

### Local (docker-compose)

```bash
# Start stack
docker compose -f compose-dev.yaml up --build

# Test frontend
curl http://localhost:3000

# Test API proxy
curl http://localhost:3000/api/categories

# Should proxy to backend and return JSON
```

### Production (Self-hosted)

```bash
# Test frontend
curl https://app.yourdomain.com

# Test API proxy
curl https://app.yourdomain.com/api/categories

# Should proxy to backend-api and return JSON
```

## Troubleshooting

### Issue: 502 Bad Gateway on /api/*

**Cause:** Backend URL is incorrect or backend is not reachable

**Solution:**
```bash
# Check BACKEND_URL is set correctly
docker compose exec frontend env | grep BACKEND_URL

# Check backend is healthy
docker compose ps backend-api

# Check nginx config was generated correctly
docker compose exec frontend cat /etc/nginx/conf.d/default.conf | grep proxy_pass
```

### Issue: CORS errors

**Cause:** Backend ALLOWED_ORIGIN doesn't match frontend URL

**Solution:**
```bash
# Check backend ALLOWED_ORIGIN
docker compose exec backend-api env | grep ALLOWED_ORIGIN

# Should match frontend public URL
# Local: http://localhost:3000
# Render: https://essentiel-frontend.onrender.com
```

### Issue: nginx fails to start

**Cause:** Environment variable substitution failed

**Solution:**
```bash
# Check entrypoint script executed
docker compose logs frontend | grep "Configuring nginx"

# Check template file exists
docker compose exec frontend ls -la /etc/nginx/conf.d/
```

## Alternative Approaches (Not Used)

### Why Not Hardcode URL?

**Problem:** Would need to rebuild frontend every time backend URL changes

```dart
// ❌ Bad: Hardcoded URL
final String backendApiUrl = 'https://essentiel-backend-api.onrender.com';

// If URL changes, must rebuild entire Flutter app
```

### Why Not Runtime Config File?

**Problem:** More complex, requires JavaScript interop

```javascript
// Would need to generate config.js at runtime
window.CONFIG = { backendUrl: 'https://...' };
```

Then load in Flutter - adds complexity without much benefit.

### Why Not Environment Variables in Build?

**Problem:** Must rebuild for each environment

```dockerfile
# ❌ Would need separate builds for dev/prod
ARG BACKEND_URL
RUN flutter build web -Dbackend.url=${BACKEND_URL}
```

With nginx proxy, one build works everywhere.

## See Also

- [nginx proxy_pass documentation](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)
- [Docker Compose Guide](DOCKER_COMPOSE.md)
- [Docker Networking](https://docs.docker.com/network/)
