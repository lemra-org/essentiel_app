# Implementation Plan: Backend API Service for Web App Data

**Branch**: `004-backend-api-service` | **Date**: 2026-05-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-backend-api-service/spec.md`

## Summary

Backend REST API service that provides secure Google Sheets data access for the Essentiel web application. The service acts as a security boundary, keeping Service Account credentials server-side while exposing two public endpoints (/api/categories and /api/questions) with CORS support for the web app domain. Implements caching (5-minute TTL) to reduce Google Sheets API calls and targets <100ms response times for cached data.

## Technical Context

**Language/Version**: Go 1.22+ (latest stable)

**Primary Dependencies**: 
- Go standard library (`net/http`, `encoding/json`)
- Google Sheets API Go client (`google.golang.org/api/sheets/v4`)
- Google OAuth2 library (`golang.org/x/oauth2/google`)
- CORS middleware (`rs/cors`)
- Redis Go client (`github.com/redis/go-redis/v9`) - optional

**Storage**: 
- **Caching**: Redis (optional, recommended for production) or in-memory cache with 5-minute TTL
- **Data Source**: Google Sheets (single source of truth)
- No persistent database needed

**Testing**: Go built-in testing framework (`go test`), integration tests with mock Google Sheets responses

**Target Platform**: Cloud platform deployment (Cloud Run, Fly.io, or Railway) with Docker containerization

**Project Type**: Web service / REST API

**Performance Goals**: 
- <100ms response time for cached data (P99)
- <2s response time for fresh Google Sheets fetch (P95)
- Handle 100 concurrent requests without degradation

**Constraints**: 
- Zero credential exposure (Service Account keys server-side only)
- CORS restricted to lemra-org.github.io domain
- Google Sheets API rate limits (100 requests per 100 seconds per user)
- Stateless architecture for horizontal scaling

**Scale/Scope**: 
- 2 REST endpoints (/api/categories, /api/questions)
- Expected load: hundreds of concurrent users from web app
- Small codebase: <1000 lines of Go code
- Lightweight deployment: <50MB Docker image

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: This backend service is a separate project from the main Essentiel Flutter app. Constitution principles are evaluated for applicability to this backend service context.

### Principle I: Mobile-First Development ⊘

**Status**: NOT APPLICABLE

**Justification**: This is a backend REST API service, not a mobile application. Mobile-first development principles do not apply to server-side services.

**Action**: N/A

### Principle II: Data Integrity & Offline-First ✅

**Status**: COMPLIANT (adapted for backend context)

**Justification**: Google Sheets remains the single source of truth. The service implements in-memory caching (5-minute TTL) to handle transient network issues and reduce API calls, similar to offline-first principles but in a server context. Data validation is required before returning responses to clients.

**Action**: Implement robust error handling for Google Sheets API failures. Cache data to maintain service availability during transient Sheet API issues. Validate data integrity after fetch operations.

### Principle III: Environment Separation ✅

**Status**: COMPLIANT

**Justification**: The service requires strict separation between development and production environments. Service Account credentials must NEVER be committed to git and must be injected via environment variables or secret management. This is even more critical than the Flutter app because this service holds the actual credentials.

**Action**: 
- Use environment variables for Service Account credentials
- Support both local development (fake/test credentials) and production deployments
- Document credential management in quickstart.md
- Ensure zero credential exposure in logs or API responses

### Principle IV: CI/CD & Release Discipline ✅

**Status**: COMPLIANT

**Justification**: The service must follow automated CI/CD deployment pipelines. Manual deployments should only be used for local testing, never for production. Docker containerization enables consistent builds across environments.

**Action**: 
- Create GitHub Actions workflow for automated deployment
- Support multiple cloud platforms (Cloud Run, Fly.io, Railway) via Docker
- Version the service using git tags
- Automated health checks post-deployment

### Principle V: User-Centric Quality ✅

**Status**: COMPLIANT (adapted for API context)

**Justification**: While this service has no direct UI, its reliability and performance directly affect the Essentiel web app user experience. API failures, slow responses, or incorrect data impact users attempting to access the card game. Error responses must be clear and actionable.

**Action**:
- Maintain <100ms response times for cached data (user expectation: instant loading)
- Provide clear HTTP status codes and error messages
- Log errors for debugging without exposing sensitive details to clients
- Test API reliability under various failure scenarios (Sheets API down, rate limits, malformed data)

### Summary

✅ **GATE PASSED**: 3/5 principles fully compliant, 2 not applicable (mobile-specific).

**Required before Phase 0**: No blockers. Backend service aligns with applicable constitution principles (data integrity, environment separation, CI/CD, quality).

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (new repository or subdirectory)

**Decision**: This backend service should be a **separate repository** from the Flutter app to maintain independent deployment and versioning.

```text
# Go backend service structure
backend-api/
├── cmd/
│   └── server/
│       └── main.go          # Application entry point
├── internal/
│   ├── api/
│   │   ├── handlers.go      # HTTP request handlers (/api/categories, /api/questions)
│   │   ├── middleware.go    # CORS, logging middleware
│   │   └── router.go        # Route configuration
│   ├── cache/
│   │   └── cache.go         # In-memory caching with TTL
│   ├── config/
│   │   └── config.go        # Environment configuration, credentials loading
│   └── sheets/
│       ├── client.go        # Google Sheets API client wrapper
│       └── models.go        # Category, Question data structures
├── pkg/
│   └── [reusable packages if needed]
├── deployments/
│   ├── Dockerfile           # Multi-stage Docker build
│   ├── fly.toml             # Fly.io deployment config
│   └── cloudrun.yaml        # Cloud Run deployment config
├── .github/
│   └── workflows/
│       ├── ci.yml           # Run tests, lint on push/PR
│       └── deploy.yml       # Deploy to cloud platform on main push
├── go.mod                   # Go module dependencies
├── go.sum                   # Dependency checksums
├── README.md                # Service documentation
└── .env.example             # Environment variable template
```

**Repository Location**: TBD - suggest `lemra-org/essentiel-backend-api` or subdirectory in monorepo
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No constitutional violations. Backend service aligns with applicable principles (Environment Separation, CI/CD, Quality). Mobile-specific principles (I, II) not applicable to server-side service.*
