---
description: "Implementation tasks for Flutter Web Deployment feature"
---

# Tasks: Flutter Web Deployment

**Input**: Design documents from `/specs/002-flutter-web-deployment/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/web-api.md, quickstart.md

**Tests**: Tests are OPTIONAL and NOT included in this task list (not requested in feature specification)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a Flutter mobile app adding web platform support:
- **Flutter project**: `lib/` for shared code (existing)
- **Web-specific**: `web/` for web platform files (to be created)
- **CI/CD**: `.github/workflows/` for deployment automation
- **Documentation**: `specs/002-flutter-web-deployment/`

---

## Phase 1: Setup (Web Platform Initialization)

**Purpose**: Enable Flutter web support and create basic web platform structure

- [ ] T001 Enable Flutter web platform support by running `flutter create . --platforms=web`
- [ ] T002 [P] Create web app icons (192x192, 512x512) in web/icons/ from assets/images/essentiel_logo.svg.png
- [ ] T003 [P] Create favicon.png in web/ directory
- [ ] T004 [P] Update web/index.html with French language (lang="fr"), app title, and meta description

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create backend API data service abstraction in lib/services/api_service.dart
- [ ] T006 [P] Add environment detection utility in lib/utils.dart for `kIsWeb` checks
- [ ] T007 Create web environment configuration in lib/environments/web_dev.dart with backend API URL
- [ ] T008 Create production web environment in lib/environments/web_prod.dart with production backend API URL
- [ ] T009 Update lib/env.dart to support web environment detection and backend API configuration
- [ ] T010 [P] Configure web/manifest.json with app name, description, icons, theme colors, and start_url
- [ ] T011 [P] Update pubspec.yaml to ensure all dependencies support web platform (verify shared_preferences, google_fonts, etc.)

**Checkpoint**: Foundation ready - web platform configured, backend API service abstraction in place, user story implementation can now begin

---

## Phase 3: User Story 1 - Web Access Without Installation (Priority: P1) 🎯 MVP

**Goal**: Users can access and use the Essentiel card game directly through a web browser without installing a mobile app

**Independent Test**: Navigate to hosted URL in Chrome/Firefox/Safari on desktop, verify cards load, shuffle works, category filters work, and all game features function correctly

### Implementation for User Story 1

- [ ] T012 [US1] Implement backend API service for fetching categories in lib/services/api_service.dart (GET /api/categories)
- [ ] T013 [US1] Implement backend API service for fetching questions in lib/services/api_service.dart (GET /api/questions)
- [ ] T014 [US1] Update lib/game/game.dart to use backend API service when `kIsWeb` is true
- [ ] T015 [US1] Add error handling for backend API failures in lib/game/game.dart with French error messages
- [ ] T016 [US1] Implement data caching in browser localStorage via shared_preferences for offline support
- [ ] T017 [US1] Update lib/game/cards.dart to parse backend API response format (forCouples, forFamilies, forParentChild)
- [ ] T018 [P] [US1] Add basic responsive layout constraints in lib/game/game.dart using MediaQuery for 320px+ viewports
- [ ] T019 [US1] Verify shuffle functionality works on web (button click, no shake gesture needed)
- [ ] T020 [US1] Verify category filter functionality works on web with localStorage persistence
- [ ] T021 [US1] Test horizontal card scrolling works with mouse wheel and trackpad gestures
- [ ] T022 [P] [US1] Add loading indicators for backend API calls in lib/game/game.dart
- [ ] T023 [US1] Implement refresh functionality via menu item (replaces pull-to-refresh for desktop)

**Checkpoint**: At this point, User Story 1 should be fully functional - web app loads, fetches data from backend API, displays cards, supports shuffle/filter/refresh, works in modern desktop browsers

---

## Phase 4: User Story 2 - Mobile Browser Experience (Priority: P2)

**Goal**: Users accessing the web app on mobile phone browsers have a seamless experience optimized for touch interaction and small screens

**Independent Test**: Access web app on iOS Safari, Chrome Mobile, Firefox Mobile - verify touch gestures work smoothly, content fits viewport without zooming, all interactive elements are easily tappable

### Implementation for User Story 2

- [ ] T024 [P] [US2] Add viewport meta tag optimization in web/index.html for mobile browsers
- [ ] T025 [US2] Implement touch-optimized tap targets (48x48 minimum) in lib/game/game.dart speed dial menu
- [ ] T026 [US2] Add pull-to-refresh gesture support for mobile web in lib/game/game.dart using existing RefreshIndicator
- [ ] T027 [US2] Optimize horizontal card swipe gestures for touch devices in lib/game/game.dart
- [ ] T028 [P] [US2] Test and adjust touch target sizes for category filter buttons
- [ ] T029 [US2] Implement mobile viewport breakpoint (<600px) with appropriate layout adjustments using LayoutBuilder
- [ ] T030 [US2] Verify no horizontal scrolling required on mobile viewports (320px width minimum)
- [ ] T031 [P] [US2] Test on iOS Safari, Chrome Mobile, Firefox Mobile for compatibility
- [ ] T032 [US2] Add touch gesture feedback (ripple effects) to interactive elements

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - web app works on desktop AND provides excellent mobile browser experience with touch optimization

---

## Phase 5: User Story 3 - Desktop & Large Screen Optimization (Priority: P3)

**Goal**: Users on desktop computers or tablets see an optimized layout that takes advantage of larger screen real estate

**Independent Test**: Open web app on desktop browsers at 1920x1080, verify layout adapts appropriately, resize window to test breakpoints (320px → 3840px), verify hover states work with mouse

### Implementation for User Story 3

- [ ] T033 [P] [US3] Implement desktop breakpoint (>1200px) with layout optimizations using LayoutBuilder in lib/game/game.dart
- [ ] T034 [P] [US3] Add tablet breakpoint (600px-1200px) with intermediate layout in lib/game/game.dart
- [ ] T035 [US3] Implement mouse hover states for menu items and interactive elements using MouseRegion
- [ ] T036 [P] [US3] Add keyboard navigation support (Tab, Enter, Escape, Space) for accessibility
- [ ] T037 [US3] Optimize card display for large screens with max-width constraints to prevent excessive whitespace
- [ ] T038 [P] [US3] Add hover tooltips for icon-only buttons using Tooltip widget
- [ ] T039 [US3] Implement responsive font scaling for 4K displays (3840px width) using MediaQuery.textScaleFactor
- [ ] T040 [US3] Test window resize behavior - verify smooth transitions between breakpoints (320px → 3840px)
- [ ] T041 [P] [US3] Add cursor styling (pointer on hover for clickable elements) using MouseRegion
- [ ] T042 [US3] Optimize image loading with cacheWidth/cacheHeight for different screen densities

**Checkpoint**: All user stories should now be independently functional - web app provides optimal experience from mobile (320px) to 4K desktop (3840px)

---

## Phase 6: Deployment & Progressive Web App

**Purpose**: Automated deployment to GitHub Pages and offline support via PWA

- [ ] T043 Create GitHub Actions workflow in .github/workflows/deploy-web.yml for automated deployment
- [ ] T044 [P] Configure bluefireteam/flutter-gh-pages@v9 action with baseHref "/essentiel_app/" and compileToWasm: true
- [ ] T045 [P] Add workflow trigger for push to main branch in .github/workflows/deploy-web.yml
- [ ] T046 Configure GitHub Pages in repository settings (gh-pages branch, / root folder)
- [ ] T047 Build web app with PWA support using --pwa-strategy offline-first flag
- [ ] T048 [P] Configure service worker caching strategy for offline-first experience
- [ ] T049 [P] Add cache fallback for backend API failures - serve cached cards when offline
- [ ] T050 Test offline functionality - load app, disconnect network, verify cached cards display
- [ ] T051 [P] Add PWA install prompt handling and install banner
- [ ] T052 Test PWA installation on Chrome, Edge, Safari - verify standalone mode works

**Checkpoint**: Deployment pipeline configured - commits to main auto-deploy to GitHub Pages, PWA installable, offline mode functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final quality checks

- [ ] T053 [P] Update CLAUDE.md to reference specs/002-flutter-web-deployment/plan.md
- [ ] T054 [P] Add web platform documentation in README.md with deployment URL and browser compatibility
- [ ] T055 Run Lighthouse audit - verify Performance ≥90, Accessibility ≥90, PWA installable
- [ ] T056 [P] Optimize bundle size using --tree-shake-icons build flag
- [ ] T057 [P] Add Content Security Policy meta tag in web/index.html
- [ ] T058 Test browser compatibility on Chrome 120+, Firefox 121+, Safari 17.2+, Edge 120+
- [ ] T059 [P] Add error message localization - verify all errors display in French
- [ ] T060 Test deep linking - verify /#/ and /#/about routes work correctly
- [ ] T061 Performance testing - verify initial load <5s, interaction latency <100ms, 60 FPS animations
- [ ] T062 [P] Run quickstart.md validation - verify all setup steps work as documented
- [ ] T063 Security audit - verify no credentials embedded in web builds, backend URL only
- [ ] T064 [P] Add analytics or monitoring integration (if desired)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Phase 2 - No dependencies on other stories
  - User Story 2 (P2): Can start after Phase 2 - Builds on US1 but independently testable
  - User Story 3 (P3): Can start after Phase 2 - Builds on US1/US2 but independently testable
- **Deployment (Phase 6)**: Can start after US1 (MVP) or wait for all stories
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
  - Delivers: Core web app functionality (cards, shuffle, filters, refresh)
  - MVP: Can deploy to production after this story alone
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Enhances US1 with mobile optimizations
  - Delivers: Mobile browser touch optimization and responsive mobile layout
  - Independent: Can be tested separately on mobile browsers
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Enhances US1/US2 with desktop optimizations
  - Delivers: Desktop and large screen layout optimization
  - Independent: Can be tested separately on desktop browsers

### Within Each User Story

- Backend API integration before data display (T012-T013 → T014-T017)
- Core functionality before optimization (basic layout → responsive breakpoints)
- Desktop functionality (US1) before mobile optimization (US2) before desktop enhancement (US3)

### Parallel Opportunities

- **Setup (Phase 1)**: T002, T003, T004 can run in parallel
- **Foundational (Phase 2)**: T006, T007, T008, T010, T011 can run in parallel after T005
- **User Story 1**: T018, T022 can run in parallel with other US1 tasks
- **User Story 2**: T024, T028, T031 can run in parallel
- **User Story 3**: T033-T034, T036, T038, T039, T041 can run in parallel
- **Deployment (Phase 6)**: T044-T045, T048-T049, T051 can run in parallel
- **Polish (Phase 7)**: T053-T054, T056-T057, T059, T062-T064 can run in parallel
- **Different user stories can be worked on in parallel by different team members after Phase 2**

---

## Parallel Example: User Story 1

```bash
# Launch backend API service implementation (sequential):
Task T012: "Implement backend API service for fetching categories"
Task T013: "Implement backend API service for fetching questions"

# Then launch parallel web integration tasks:
Task T018: "Add basic responsive layout constraints" (different concern)
Task T022: "Add loading indicators for backend API calls" (different concern)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (enable web platform, create web/ structure)
2. Complete Phase 2: Foundational (backend API service, environment config)
3. Complete Phase 3: User Story 1 (core web functionality)
4. Optional: Complete Phase 6: Deployment (deploy MVP to GitHub Pages)
5. **STOP and VALIDATE**: Test User Story 1 independently on desktop browsers
6. Deploy/demo if ready - users can access game via web without installation

**MVP Scope**: Phases 1, 2, 3, 6 = Minimum viable web app accessible via GitHub Pages

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy (MVP - desktop browsers) ✅
3. Add User Story 2 → Test independently → Deploy (mobile browser support) ✅
4. Add User Story 3 → Test independently → Deploy (desktop optimization) ✅
5. Add Deployment automation → Auto-deploy on commit
6. Add Polish → Performance, security, documentation
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core web functionality)
   - Developer B: User Story 2 (mobile optimization) - can start in parallel
   - Developer C: User Story 3 (desktop optimization) - can start in parallel
   - Developer D: Deployment pipeline - can start after US1
3. Stories complete and integrate independently
4. Team collaborates on Phase 7: Polish

---

## Backend API Requirements

**Critical**: This implementation assumes the backend API is provided by the team. Before starting Phase 2, ensure:

- Backend API is deployed and accessible
- Endpoints return data in expected format (see contracts/web-api.md):
  - `GET /api/categories` → `{ "categories": [{ "name": "...", "color": "..." }] }`
  - `GET /api/questions` → `{ "questions": [{ "question": "...", "category": "...", "forCouples": bool, ... }] }`
- CORS headers configured for lemra-org.github.io domain
- Development backend URL available for testing (e.g., https://api-dev.essentiel.example.com)

If backend is not ready, User Story 1 can be partially implemented with mock data, but backend integration (T012-T015) will be blocked.

---

## Notes

- [P] tasks = different files/concerns, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability (US1, US2, US3)
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Web platform reuses existing Flutter code - most changes are configuration and responsive design
- No new data models needed - all entities exist in mobile app
- Shake gesture automatically works on mobile web browsers with motion sensors, button fallback exists for desktop
- Avoid: breaking mobile app functionality, embedding credentials in web builds, CORS issues

---

## Total Task Count

- **Setup**: 4 tasks
- **Foundational**: 7 tasks (BLOCKING)
- **User Story 1 (P1)**: 12 tasks 🎯 MVP
- **User Story 2 (P2)**: 9 tasks
- **User Story 3 (P3)**: 10 tasks
- **Deployment & PWA**: 10 tasks
- **Polish**: 12 tasks
- **TOTAL**: 64 tasks

**Parallel Opportunities**: 27 tasks marked [P] can run in parallel within their phases

**MVP Scope**: 23 tasks (Setup + Foundational + US1 + core Deployment)

**Full Feature**: 64 tasks (all user stories + deployment + polish)
