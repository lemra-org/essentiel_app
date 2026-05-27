# Docker Compose Quick Reference

## Two Compose Configurations

### `compose.yaml` - Production (Pre-built Images)
Uses images from `ghcr.io/lemra-org/*`

```bash
# Pull and run latest production images
docker compose pull
docker compose up

# Access: http://localhost:3000
```

**Use when:**
- Testing production builds locally
- Running released versions
- You don't need to modify code

---

### `compose-dev.yaml` - Development (Build from Source)
Builds images from your local code

```bash
# Build from source and run
docker compose -f compose-dev.yaml up --build

# Access: http://localhost:3000
```

**Use when:**
- Actively developing
- Testing local changes
- Debugging issues

---

## Quick Commands

| Task | Command |
|------|---------|
| **Dev: Start** | `docker compose -f compose-dev.yaml up --build` |
| **Dev: Stop** | `docker compose -f compose-dev.yaml down` |
| **Dev: Logs** | `docker compose -f compose-dev.yaml logs -f` |
| **Dev: Rebuild** | `docker compose -f compose-dev.yaml up --build` |
| **Prod: Start** | `docker compose up` |
| **Prod: Stop** | `docker compose down` |
| **Prod: Update** | `docker compose pull && docker compose up` |
| **Check Status** | `docker compose ps` |

---

## Environment Setup

```bash
# 1. Copy template
cp .env.example .env

# 2. Edit credentials
nano .env

# Required variables:
# - GOOGLE_SERVICE_ACCOUNT_JSON
# - GOOGLE_SPREADSHEET_ID
```

---

## Services

| Service | Port | Description |
|---------|------|-------------|
| **frontend** | 3000 | Flutter web (nginx) |
| **backend-api** | 8080 | Go API server |
| **redis** | 6379 | Cache |

---

## Full Documentation

- **[DOCKER_COMPOSE.md](docs/DOCKER_COMPOSE.md)** - Complete Docker Compose guide
- **[BACKEND_PROXY.md](docs/BACKEND_PROXY.md)** - nginx proxy configuration details
