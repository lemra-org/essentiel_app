# Self-Hosted Deployment Guide

This guide explains how to deploy the Essentiel app on your own server using Docker Compose.

## Prerequisites

- Linux server (VPS or dedicated)
- Docker and Docker Compose installed
- Domain name (optional, for HTTPS)
- Google Service Account credentials
- Google Spreadsheet ID

---

## Quick Deployment

### 1. Install Docker

```bash
# On Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### 2. Clone Repository

```bash
git clone https://github.com/lemra-org/essentiel_app.git
cd essentiel_app
```

### 3. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env
```

Required variables in `.env`:
```bash
# Google Sheets credentials
GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id-here

# CORS (your frontend domain)
ALLOWED_ORIGIN=https://app.yourdomain.com

# Backend URL for nginx proxy
BACKEND_URL=http://backend-api:8080
```

### 4. Deploy

```bash
# Pull pre-built images from GitHub Container Registry
docker compose pull

# Start services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Services will be running on:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- Redis: localhost:6379

---

## Add HTTPS with Reverse Proxy

### Option 1: nginx on Host

Install nginx as reverse proxy:

```bash
sudo apt install nginx certbot python3-certbot-nginx
```

Create nginx config `/etc/nginx/sites-available/essentiel`:

```nginx
server {
    listen 80;
    server_name app.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and get SSL:

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/essentiel /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get Let's Encrypt certificate
sudo certbot --nginx -d app.yourdomain.com
```

Update CORS in `.env`:
```bash
ALLOWED_ORIGIN=https://app.yourdomain.com
```

Restart services:
```bash
docker compose restart backend-api
```

### Option 2: Traefik (Docker-native)

Add Traefik to `compose.yaml`:

```yaml
services:
  traefik:
    image: traefik:v2.10
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=you@email.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt
    networks:
      - essentiel-network

  frontend:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`app.yourdomain.com`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
```

---

## Update Deployment

When new versions are released:

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Clean up old images
docker image prune -a
```

---

## Build from Source (Optional)

If you want to build images yourself:

```bash
# Build images locally
docker compose -f compose-dev.yaml build

# Tag for your registry
docker tag essentiel-frontend:dev your-registry/essentiel-frontend:latest
docker tag essentiel-backend-api:dev your-registry/essentiel-backend-api:latest

# Push to registry
docker push your-registry/essentiel-frontend:latest
docker push your-registry/essentiel-backend-api:latest

# Update compose.yaml to use your registry
# Then deploy as normal
```

---

## Monitoring

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f frontend
docker compose logs -f backend-api

# Last 100 lines
docker compose logs --tail=100 backend-api
```

### Check Health

```bash
# Service status
docker compose ps

# Health checks
curl http://localhost:3000/healthz  # Frontend
curl http://localhost:8080/healthz  # Backend
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df
```

---

## Backup

### Database (Google Sheets)

Data is stored in Google Sheets (no local database to backup).

### Environment Files

```bash
# Backup .env file (contains secrets)
cp .env .env.backup
```

Store `.env.backup` securely (not in git).

---

## Troubleshooting

### Frontend not loading

```bash
# Check frontend logs
docker compose logs frontend

# Check nginx config
docker compose exec frontend cat /etc/nginx/conf.d/default.conf

# Verify BACKEND_URL is set
docker compose exec frontend env | grep BACKEND_URL
```

### Backend API errors

```bash
# Check backend logs
docker compose logs backend-api

# Check Google credentials
docker compose exec backend-api env | grep GOOGLE_

# Test API directly
curl http://localhost:8080/api/categories
```

### Redis connection issues

```bash
# Check Redis is running
docker compose ps redis

# Test Redis
docker compose exec redis redis-cli ping

# Check backend Redis connection
docker compose logs backend-api | grep -i redis
```

### CORS errors in browser

Update `ALLOWED_ORIGIN` in `.env`:
```bash
ALLOWED_ORIGIN=https://app.yourdomain.com
```

Restart backend:
```bash
docker compose restart backend-api
```

---

## Security Hardening

### 1. Firewall

```bash
# Allow only necessary ports
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable

# Block direct access to app ports
# (use reverse proxy only)
```

### 2. Update ALLOWED_ORIGIN

Never use `*` in production:
```bash
# ❌ Bad
ALLOWED_ORIGIN=*

# ✅ Good
ALLOWED_ORIGIN=https://app.yourdomain.com
```

### 3. Keep Updated

```bash
# Update system
sudo apt update && sudo apt upgrade

# Update Docker images regularly
docker compose pull
docker compose up -d
```

### 4. Secrets Management

Never commit `.env` to git:
```bash
# Verify .env is in .gitignore
cat .gitignore | grep .env
```

---

## Performance Tuning

### Enable Redis (if not using)

Redis significantly improves performance:

```yaml
# In compose.yaml, Redis is included by default
# Just ensure REDIS_ADDR is set in .env
REDIS_ADDR=redis:6379
```

### Adjust Cache TTL

```bash
# In .env
CACHE_TTL_MINUTES=10  # Increase for less Google Sheets API calls
```

### Resource Limits

Add to `compose.yaml`:

```yaml
services:
  backend-api:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

---

## Scaling (Multiple Servers)

For high traffic:

1. **Load balancer** (nginx/HAProxy) in front
2. **Multiple frontend replicas**:
   ```bash
   docker compose up -d --scale frontend=3
   ```
3. **Shared Redis** (external Redis service)
4. **CDN** for static assets

---

## Cost Estimation

**Minimal VPS (1 vCPU, 1GB RAM):**
- DigitalOcean: $6/month
- Hetzner: €4.5/month
- Vultr: $6/month

**Recommended VPS (2 vCPU, 2GB RAM):**
- DigitalOcean: $12/month
- Hetzner: €7.5/month
- Vultr: $12/month

**Additional costs:**
- Domain name: ~$12/year
- Let's Encrypt SSL: Free

---

## Alternative: Docker Swarm / Kubernetes

For production at scale, consider:

- **Docker Swarm**: Built-in Docker clustering
- **Kubernetes**: Advanced orchestration
- **Nomad**: HashiCorp's orchestrator

(Out of scope for this guide)

---

## See Also

- [Docker Compose Guide](DOCKER_COMPOSE.md) - Local development
- [Backend Proxy Configuration](BACKEND_PROXY.md) - nginx proxy details
- [Backend API README](../backend-api/README.md) - Backend documentation
