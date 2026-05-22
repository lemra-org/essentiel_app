---
description: "Implementation tasks for Backend API Service"
---

# Tasks: Backend API Service for Web App Data

**Input**: Design documents from `/specs/004-backend-api-service/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/rest-api.md, quickstart.md

**Tests**: Tests are OPTIONAL and NOT included in this task list (not explicitly requested in feature specification)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a new Go backend service (separate repository recommended):
- **Go code**: `cmd/` for entry points, `internal/` for application code
- **Deployment**: `deployments/` for Docker and cloud configs
- **CI/CD**: `.github/workflows/` for GitHub Actions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize Go project structure and install dependencies

- [ ] T001 Create Go module with `go mod init github.com/lemra-org/essentiel-backend-api`
- [ ] T002 Create project directory structure (cmd/server/, internal/api/, internal/cache/, internal/config/, internal/sheets/)
- [ ] T003 [P] Install core dependencies: google.golang.org/api/sheets/v4, golang.org/x/oauth2/google
- [ ] T004 [P] Install additional dependencies: github.com/rs/cors, github.com/patrickmn/go-cache
- [ ] T005 [P] Create .env.example file with required environment variables (PORT, GOOGLE_SPREADSHEET_ID, ALLOWED_ORIGIN, CACHE_TTL_MINUTES)
- [ ] T006 [P] Create .gitignore file (service-account*.json, .env, *.log)
- [ ] T007 [P] Create README.md with project description and quick start instructions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Create configuration loading in internal/config/config.go (environment variables: PORT, SERVICE_ACCOUNT_JSON, SPREADSHEET_ID, ALLOWED_ORIGIN, CACHE_TTL)
- [ ] T009 Create Category and Question structs in internal/sheets/models.go with JSON tags
- [ ] T010 [P] Create Google Sheets API client wrapper in internal/sheets/client.go with Service Account authentication
- [ ] T011 [P] Create in-memory cache wrapper in internal/cache/cache.go using patrickmn/go-cache with 5-minute TTL
- [ ] T012 Create HTTP router in internal/api/router.go with endpoint registration
- [ ] T013 [P] Create CORS middleware in internal/api/middleware.go using rs/cors for lemra-org.github.io domain
- [ ] T014 [P] Create logging middleware in internal/api/middleware.go for request/response logging
- [ ] T015 Create main.go entry point in cmd/server/ with server initialization and graceful shutdown

**Checkpoint**: Foundation ready - Google Sheets client configured, cache initialized, HTTP router with CORS/logging middleware, user story implementation can now begin

---

## Phase 3: User Story 1 - Secure Data Access via API (Priority: P1) 🎯 MVP

**Goal**: Essentiel web application can fetch card categories and questions from a public API without exposing any credentials to end users

**Independent Test**: Deploy the API service and make HTTP requests from curl or browser, verify JSON responses contain category and question data with no credentials visible

### Implementation for User Story 1

- [ ] T016 [US1] Implement FetchCategories function in internal/sheets/client.go (read Categories sheet, parse to []Category)
- [ ] T017 [US1] Implement FetchQuestions function in internal/sheets/client.go (read Questions sheet, parse to []Question)
- [ ] T018 [US1] Implement data validation in internal/sheets/client.go (validate category names, hex colors, question text)
- [ ] T019 [US1] Implement GetCategories handler in internal/api/handlers.go (cache check, fetch from Sheets, return JSON)
- [ ] T020 [US1] Implement GetQuestions handler in internal/api/handlers.go (cache check, fetch from Sheets, return JSON)
- [ ] T021 [P] [US1] Add error handling for Google Sheets API failures in handlers (503 Service Unavailable with generic error message)
- [ ] T022 [P] [US1] Add cache-control headers (Cache-Control: public, max-age=300) to category and question responses
- [ ] T023 [US1] Register /api/categories and /api/questions routes in internal/api/router.go
- [ ] T024 [US1] Test end-to-end flow: start server, curl /api/categories and /api/questions, verify JSON structure matches contract

**Checkpoint**: At this point, User Story 1 should be fully functional - API endpoints return categories and questions, Google Sheets credentials stay server-side, data validated before caching

---

## Phase 4: User Story 2 - Cross-Origin Web Access (Priority: P2)

**Goal**: Web application hosted on GitHub Pages can successfully call the API endpoints without CORS errors

**Independent Test**: Open deployed web app in browser, check browser console for CORS errors, verify API requests complete successfully with data displayed

### Implementation for User Story 2

- [ ] T025 [US2] Configure CORS middleware to allow https://lemra-org.github.io origin in internal/api/middleware.go
- [ ] T026 [US2] Add CORS allowed methods (GET, OPTIONS) to middleware configuration
- [ ] T027 [US2] Add CORS allowed headers (Content-Type) to middleware configuration
- [ ] T028 [US2] Set CORS preflight cache max-age to 300 seconds in middleware configuration
- [ ] T029 [P] [US2] Apply CORS middleware to HTTP router in internal/api/router.go
- [ ] T030 [US2] Test OPTIONS preflight request to /api/categories with Origin header, verify CORS headers in response
- [ ] T031 [US2] Test GET request from allowed origin, verify Access-Control-Allow-Origin header matches request origin
- [ ] T032 [P] [US2] Test GET request from disallowed origin, verify no CORS headers in response (browser will block)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - API serves data AND web app can call it from browser without CORS errors

---

## Phase 5: User Story 3 - Fast and Efficient Data Delivery (Priority: P3)

**Goal**: Users experience instant data loading with minimal wait times through caching optimization

**Independent Test**: Measure API response times using browser developer tools or curl with timing, verify cached responses <100ms and fresh data <2s

### Implementation for User Story 3

- [ ] T033 [US3] Add cache jitter (10% random variation: 4.5-5.5 minutes) to cache TTL in internal/cache/cache.go
- [ ] T034 [US3] Implement cache-first strategy in GetCategories handler (check cache before Sheets API call)
- [ ] T035 [US3] Implement cache-first strategy in GetQuestions handler (check cache before Sheets API call)
- [ ] T036 [P] [US3] Add response time logging to middleware (log duration from request start to response sent)
- [ ] T037 [P] [US3] Add retry logic with exponential backoff for Google Sheets API rate limits (429 errors: 1s, 4s, 9s, 16s, 25s delays)
- [ ] T038 [US3] Test concurrent requests (simulate 100 simultaneous requests), verify all succeed without errors
- [ ] T039 [US3] Test cache hit performance (make request, repeat within 5 min), verify second request <100ms
- [ ] T040 [US3] Test cache miss performance (clear cache, make request), verify response <2s for typical spreadsheet size

**Checkpoint**: All user stories should now be independently functional - API delivers secure data, supports CORS for web app, and provides fast cached responses

---

## Phase 6: Deployment & Infrastructure

**Purpose**: Containerization and cloud deployment setup

- [ ] T041 Create multi-stage Dockerfile in deployments/Dockerfile (golang:1.22-alpine builder, gcr.io/distroless/static-debian12 runtime)
- [ ] T042 [P] Add build optimization flags in Dockerfile (CGO_ENABLED=0, -ldflags="-s -w" for binary stripping)
- [ ] T043 [P] Configure Dockerfile to run as non-root user (USER 65532:65532) and expose port 8080
- [ ] T044 Test local Docker build and run, verify server starts and endpoints respond
- [ ] T045 Create Fly.io configuration in deployments/fly.toml (app name, region, build dockerfile path)
- [ ] T046 [P] Configure HTTP service in fly.toml (internal_port 8080, force_https true, auto_stop_machines false)
- [ ] T047 [P] Add health check configuration in fly.toml (interval 15s, path /healthz, timeout 5s)
- [ ] T048 Create health check endpoint GET /healthz in internal/api/handlers.go (returns 200 OK with {"status":"healthy"})
- [ ] T049 Create readiness check endpoint GET /readyz in internal/api/handlers.go (checks Google Sheets connectivity, returns 200/503)
- [ ] T050 Register /healthz and /readyz routes in internal/api/router.go

**Checkpoint**: Deployment infrastructure configured - Docker image builds successfully, Fly.io config ready for deployment, health checks functional

---

## Phase 7: CI/CD & Automation

**Purpose**: Automated testing and deployment pipelines

- [ ] T051 Create GitHub Actions CI workflow in .github/workflows/ci.yml (trigger on push/PR)
- [ ] T052 [P] Add Go setup step in CI workflow (actions/setup-go@v5 with go-version 1.22)
- [ ] T053 [P] Add dependency installation step in CI workflow (go mod download)
- [ ] T054 [P] Add test execution step in CI workflow (go test -v -cover ./...)
- [ ] T055 [P] Add code vetting step in CI workflow (go vet ./...)
- [ ] T056 [P] Add build verification step in CI workflow (go build ./cmd/server)
- [ ] T057 Create GitHub Actions deploy workflow in .github/workflows/deploy.yml (trigger on push to main)
- [ ] T058 [P] Add Fly.io deployment step in deploy workflow (superfly/flyctl-actions/setup-flyctl@master, flyctl deploy --remote-only)
- [ ] T059 [P] Configure GitHub secrets documentation in README.md (FLY_API_TOKEN required)

**Checkpoint**: CI/CD pipelines configured - tests run on push/PR, automatic deployment to Fly.io on main branch push

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, optimization, and final quality checks

- [ ] T060 [P] Add comprehensive API documentation to README.md (endpoints, request/response examples, deployment instructions)
- [ ] T061 [P] Add local development setup guide to README.md (prerequisites, environment variables, running locally)
- [ ] T062 [P] Add troubleshooting section to README.md (common issues: CORS errors, authentication failures, cache problems)
- [ ] T063 Add example Service Account setup instructions to README.md (Google Cloud Console steps, spreadsheet sharing)
- [ ] T064 [P] Add performance benchmarks documentation (response time targets, concurrent request handling)
- [ ] T065 [P] Verify all error responses return consistent JSON format with "error" field
- [ ] T066 [P] Verify no sensitive data (credentials, detailed errors) exposed in API responses or logs
- [ ] T067 Add rate limiting documentation to README.md (100 req/min per IP, enforced at Fly.io level)
- [ ] T068 [P] Verify Docker image size <50MB (run docker images command and check)
- [ ] T069 Perform end-to-end deployment test (deploy to Fly.io, verify endpoints accessible from web browser)
- [ ] T070 [P] Run quickstart.md validation (follow all steps in quickstart guide, verify they work as documented)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Phase 2 - No dependencies on other stories
  - User Story 2 (P2): Can start after Phase 2 - Enhances US1 with CORS support
  - User Story 3 (P3): Can start after Phase 2 - Enhances US1/US2 with performance optimization
- **Deployment (Phase 6)**: Can start after US1 (MVP) or wait for all stories
- **CI/CD (Phase 7)**: Can start after Deployment infrastructure is ready
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
  - Delivers: Core API functionality (Google Sheets data access, JSON endpoints)
  - MVP: Can deploy to production after this story alone
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Enhances US1 with CORS
  - Delivers: Web app can call API from browser without CORS errors
  - Independent: Can be tested separately by making browser requests
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Enhances US1/US2 with performance
  - Delivers: Fast cached responses, retry logic, concurrent request handling
  - Independent: Can be tested separately with performance benchmarks

### Within Each User Story

- Google Sheets client functions before handlers (T016-T018 → T019-T020)
- Handlers before route registration (T019-T020 → T023)
- Core functionality before optimization (basic endpoints → cache strategies → retry logic)

### Parallel Opportunities

- **Setup (Phase 1)**: T003-T004, T005-T006-T007 can run in parallel
- **Foundational (Phase 2)**: T009, T010-T011, T013-T014 can run in parallel after T008
- **User Story 1**: T021-T022 can run in parallel with other US1 tasks
- **User Story 2**: T032 can run in parallel with T030-T031
- **User Story 3**: T036-T037, T039-T040 can run in parallel
- **Deployment (Phase 6)**: T042-T043, T046-T047 can run in parallel
- **CI/CD (Phase 7)**: T052-T056, T059 can run in parallel
- **Polish (Phase 8)**: T060-T062, T064-T066, T068, T070 can run in parallel
- **Different user stories can be worked on in parallel by different team members after Phase 2**

---

## Parallel Example: User Story 1

```bash
# Launch Google Sheets integration tasks (sequential - dependencies):
Task T016: "Implement FetchCategories in internal/sheets/client.go"
Task T017: "Implement FetchQuestions in internal/sheets/client.go"
Task T018: "Implement data validation in internal/sheets/client.go"

# Then launch handler and route tasks:
Task T019: "Implement GetCategories handler"
Task T020: "Implement GetQuestions handler"

# Then launch parallel optimization tasks:
Task T021: "Add error handling for Google Sheets API failures" (different concern)
Task T022: "Add cache-control headers" (different concern)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (Go project initialization)
2. Complete Phase 2: Foundational (Google Sheets client, cache, router, middleware)
3. Complete Phase 3: User Story 1 (API endpoints with secure data access)
4. Optional: Complete Phase 6: Deployment (deploy MVP to Fly.io)
5. **STOP and VALIDATE**: Test User Story 1 independently with curl/Postman
6. Deploy/demo if ready - web app can fetch data via API

**MVP Scope**: Phases 1, 2, 3, 6 = Minimum viable API backend

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy (MVP - secure data access) ✅
3. Add User Story 2 → Test independently → Deploy (CORS support for web app) ✅
4. Add User Story 3 → Test independently → Deploy (performance optimization) ✅
5. Add CI/CD automation → Auto-deploy on commit
6. Add Polish → Documentation, benchmarks, validation
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core API endpoints)
   - Developer B: User Story 2 (CORS support) - can start in parallel
   - Developer C: User Story 3 (performance optimization) - can start in parallel
   - Developer D: Deployment infrastructure - can start after US1
3. Stories complete and integrate independently
4. Team collaborates on Phase 7-8: CI/CD and Polish

---

## Notes

- [P] tasks = different files/concerns, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability (US1, US2, US3)
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- This is a separate repository from the Flutter app - maintain independent versioning
- Zero credentials in client code - all authentication server-side only
- Avoid: exposing credentials in logs/responses, tight coupling between stories, hardcoded configuration

---

## Total Task Count

- **Setup**: 7 tasks
- **Foundational**: 8 tasks (BLOCKING)
- **User Story 1 (P1)**: 9 tasks 🎯 MVP
- **User Story 2 (P2)**: 8 tasks
- **User Story 3 (P3)**: 8 tasks
- **Deployment & Infrastructure**: 10 tasks
- **CI/CD & Automation**: 9 tasks
- **Polish**: 11 tasks
- **TOTAL**: 70 tasks

**Parallel Opportunities**: 28 tasks marked [P] can run in parallel within their phases

**MVP Scope**: 24 tasks (Setup + Foundational + US1 + core Deployment)

**Full Feature**: 70 tasks (all user stories + deployment + CI/CD + polish)
