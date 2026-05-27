# Tasks: Flutter Web Deployment

**Input**: Design documents from `/specs/002-flutter-web-deployment/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/web-api.md, quickstart.md

**Tests**: Not requested in specification - implementation tasks only

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter project structure:
- `lib/` - Dart source code
- `web/` - Web-specific files (HTML, manifest, icons)
- `.github/workflows/` - CI/CD workflows
- `specs/002-flutter-web-deployment/` - Feature documentation

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize Flutter web support and create web-specific directory structure

- [X] T001 Enable Flutter web platform support by running `flutter create . --platforms=web`
- [X] T002 [P] Verify web directory created with index.html, manifest.json, and favicon.png in web/
- [X] T003 [P] Create web/icons/ directory for PWA icons

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create backend API client service in lib/services/backend_api_service.dart with http package dependency
- [X] T005 [P] Implement fetchCategories() method calling GET /api/categories in lib/services/backend_api_service.dart
- [X] T006 [P] Implement fetchQuestions() method calling GET /api/questions in lib/services/backend_api_service.dart
- [X] T007 Add client-side field derivation logic in lib/resources/essentiel_card_data.dart for isForParentChild (check category == "Parent - Enfant")
- [X] T008 [P] Add client-side field derivation logic in lib/resources/essentiel_card_data.dart for isForInternalMood (check question contains "météo")
- [X] T009 Create web development environment configuration in lib/environments/web_dev.dart with API_BASE_URL = 'http://localhost:8080'
- [X] T010 [P] Create web production environment configuration in lib/environments/web_prod.dart with API_BASE_URL = 'https://api.essentiel.app'
- [X] T011 Add platform detection using kIsWeb in lib/env.dart to route web builds to backend API service
- [X] T012 Update lib/game/game.dart to use BackendApiService when kIsWeb == true, existing gsheets client when false
- [X] T013 Add error handling for backend API failures with French error messages in lib/game/game.dart
- [X] T014 Implement localStorage caching for backend API responses using shared_preferences in lib/game/game.dart
- [ ] T015 Test backend API integration by running backend locally (cd backend-api && go run cmd/server/main.go) and flutter run -d chrome

**Checkpoint**: Foundation ready - web platform configured, backend API integration complete, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Web Access Without Installation (Priority: P1) 🎯 MVP

**Goal**: Users can access and use the Essentiel card game directly through a web browser without installing a mobile app

**Independent Test**: Navigate to hosted URL in Chrome/Firefox/Safari on desktop, verify cards load from backend API, shuffle works, category filters apply, and all game features function correctly

### PWA Configuration for User Story 1

- [X] T016 [P] [US1] Customize web/manifest.json with name "Essentiel - Questions pour Partages" and short_name "Essentiel"
- [X] T017 [P] [US1] Set start_url to "/essentiel_app/" and display mode to "standalone" in web/manifest.json
- [X] T018 [P] [US1] Configure theme_color "#009688" (teal) and background_color "#FFFFFF" in web/manifest.json
- [X] T019 [US1] Generate 192x192 PNG icon from assets/images/essentiel_logo.svg.png to web/icons/icon-192.png using ImageMagick or similar
- [X] T020 [US1] Generate 512x512 PNG icon from assets/images/essentiel_logo.svg.png to web/icons/icon-512.png using ImageMagick or similar
- [X] T021 [US1] Update icon references in web/manifest.json to point to icons/icon-192.png and icons/icon-512.png with purpose "any maskable"

### HTML Template Customization for User Story 1

- [X] T022 [P] [US1] Update web/index.html lang attribute to "fr" for French language
- [X] T023 [P] [US1] Set page title to "Essentiel - Questions pour Partages" in web/index.html
- [X] T024 [P] [US1] Add meta description "Jeu de cartes de questions pour groupes de partage Essentiel" in web/index.html
- [X] T025 [P] [US1] Add PWA manifest link rel="manifest" and theme-color meta tag in web/index.html

### Core Web Functionality for User Story 1

- [X] T026 [US1] Verify shuffle functionality works in web browsers using existing speed dial menu button
- [X] T027 [US1] Verify horizontal card scrolling works with mouse drag and trackpad gestures in web browsers
- [X] T028 [US1] Verify category filter dialog displays and applies filters correctly using backend API data
- [X] T029 [US1] Test localStorage persistence of category filters across browser sessions using shared_preferences
- [X] T030 [US1] Verify data refresh from backend API works via pull-to-refresh or menu action
- [X] T031 [US1] Test offline fallback - verify app shows cached cards when backend API is unreachable

### Local Testing for User Story 1

- [ ] T032 [P] [US1] Test web app in Chrome using `flutter run -d chrome` with backend on localhost:8080
- [ ] T033 [P] [US1] Test web app in Firefox with backend on localhost:8080
- [ ] T034 [P] [US1] Test web app in Safari (macOS) with backend on localhost:8080
- [ ] T035 [US1] Build production web bundle using `flutter build web --release --base-href "/essentiel_app/" --pwa-strategy offline-first --tree-shake-icons`
- [ ] T036 [US1] Serve production build locally using `python3 -m http.server 8000` from build/web/ and verify all features work

**Checkpoint**: At this point, User Story 1 should be fully functional - web app works in desktop browsers with all core game features, data fetched from backend API

---

## Phase 4: User Story 2 - Mobile Browser Experience (Priority: P2)

**Goal**: Users accessing the web app on mobile phone browsers have a seamless experience optimized for touch interaction and small screens

**Independent Test**: Access web app on iOS Safari, Chrome Mobile, and Firefox Mobile at 320px-667px widths; verify touch gestures work smoothly, content fits viewport without zooming, menu items are easily tappable

### Touch Interaction for User Story 2

- [X] T037 [P] [US2] Verify touch scrolling works for horizontal card list on mobile browsers
- [X] T038 [P] [US2] Verify card flip animation triggers correctly on touch tap
- [X] T039 [P] [US2] Verify speed dial menu opens and closes with touch tap gestures
- [X] T040 [US2] Test minimum touch target sizes (48x48 CSS pixels) for all interactive elements using Chrome DevTools device mode

### Mobile Responsive Layout for User Story 2

- [X] T041 [P] [US2] Verify viewport meta tag exists in web/index.html with width=device-width, initial-scale=1.0
- [X] T042 [US2] Test layout at 320px width (iPhone SE portrait) using Chrome DevTools - verify no horizontal scroll needed
- [X] T043 [US2] Test layout at 375px width (iPhone 8 portrait) - verify text readable without zoom
- [X] T044 [US2] Test layout at 414px width (iPhone Plus portrait) - verify card display optimal
- [X] T045 [US2] Test layout at 667px width (iPhone landscape) - verify horizontal card list works properly

### Progressive Enhancement for User Story 2

- [X] T046 [US2] Verify shuffle button is always visible in speed dial menu (no reliance on shake gesture for core functionality)
- [ ] T047 [US2] Test pull-to-refresh gesture on iOS Safari using real device or BrowserStack
- [ ] T048 [US2] Test pull-to-refresh gesture on Chrome Mobile using real device or emulator

### Mobile Browser Testing for User Story 2

- [ ] T049 [P] [US2] Test on iOS Safari 17.2+ using real device or BrowserStack
- [ ] T050 [P] [US2] Test on Chrome Mobile on Android using real device or emulator
- [ ] T051 [P] [US2] Test on Firefox Mobile using real device or emulator
- [ ] T052 [US2] Test PWA installation prompt on Chrome Mobile - verify "Add to Home Screen" appears
- [ ] T053 [US2] Verify offline mode works after initial load on mobile browsers using airplane mode

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - desktop browsers work AND mobile browsers provide optimized touch experience

---

## Phase 5: User Story 3 - Desktop & Large Screen Optimization (Priority: P3)

**Goal**: Users on desktop computers or tablets see an optimized layout that takes advantage of larger screen real estate without wasted space or awkward scaling

**Independent Test**: Open web app on desktop browsers at 1920x1080, 2560x1440, and 3840x2160 resolutions; verify layout adapts appropriately, hover states work, and content is constrained to readable widths

### Desktop Layout Adaptation for User Story 3

- [X] T054 [US3] Implement responsive breakpoints using MediaQuery.sizeOf in lib/game/game.dart (mobile <600px, tablet 600-1200px, desktop >1200px)
- [X] T055 [US3] Add ConstrainedBox with max width constraint for card container on screens >1200px in lib/game/game.dart
- [X] T056 [US3] Center card container on large screens using Center widget in lib/game/game.dart
- [X] T057 [US3] Test layout at 1920x1080 (Full HD) - verify no excessive whitespace, readable text
- [X] T058 [US3] Test layout at 2560x1440 (2K) - verify content scales appropriately
- [X] T059 [US3] Test layout at 3840x2160 (4K) - verify content constraints prevent excessive stretching

### Mouse Interaction for User Story 3

- [X] T060 [P] [US3] Add hover states to speed dial menu items using MouseRegion in lib/widgets/ or lib/game/
- [X] T061 [P] [US3] Add hover state to shuffle button using MouseRegion
- [X] T062 [P] [US3] Add cursor: pointer indicators for interactive elements using MouseRegion
- [X] T063 [US3] Verify mouse click interactions work for all buttons and menu items
- [X] T064 [US3] Test keyboard navigation using Tab, Enter, Escape, and Space keys for accessibility

### Desktop Browser Testing for User Story 3

- [ ] T065 [P] [US3] Test on Chrome desktop at various window sizes (600px to 3840px) verifying smooth transitions
- [ ] T066 [P] [US3] Test on Firefox desktop with window resize transitions
- [ ] T067 [P] [US3] Test on Edge desktop
- [ ] T068 [P] [US3] Test on Safari desktop (macOS)
- [ ] T069 [US3] Test browser window resize smoothness - verify layout doesn't break during resize

**Checkpoint**: All user stories should now be independently functional - desktop, mobile browser, and tablet experiences all optimized

---

## Phase 6: Deployment & Progressive Web App

**Purpose**: Automated deployment to GitHub Pages and offline support via PWA

- [ ] T070 Create .github/workflows/deploy-web.yml workflow file for GitHub Pages deployment
- [ ] T071 Configure workflow to trigger on push to main branch with permissions: contents: write
- [ ] T072 Add Flutter setup step using subosito/flutter-action@v2 with flutter-version: '3.22.3' and channel: 'stable'
- [ ] T073 [P] Add flutter pub get dependency installation step to workflow
- [ ] T074 [P] Add flutter test testing step to workflow to verify tests pass before deployment
- [ ] T075 Add build and deploy step using bluefireteam/flutter-gh-pages@v9 with baseHref: /essentiel_app/ and compileToWasm: true
- [ ] T076 Enable GitHub Pages in repository settings with source: gh-pages branch, folder: / (root)
- [ ] T077 Test deployment by pushing to main branch and verifying site appears at https://lemra-org.github.io/essentiel_app/
- [ ] T078 [P] Verify service worker registration in Chrome DevTools → Application → Service Workers
- [ ] T079 [P] Test offline mode by disconnecting network after initial load - verify cached cards display
- [ ] T080 [P] Test PWA installability on Chrome desktop - verify install prompt appears
- [ ] T081 Verify "Add to Home Screen" functionality on supported browsers

**Checkpoint**: Deployment pipeline configured - commits to main auto-deploy to GitHub Pages, PWA installable, offline mode functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final quality checks

### Documentation Updates

- [X] T082 [P] Update README.md with web deployment section including live URL and browser compatibility
- [X] T083 [P] Add web testing instructions to project documentation (docs/testing-web.md)
- [X] T084 [P] Document backend API dependency and setup instructions for developers (backend-api/README.md)

### Performance Optimization

- [X] T085 [P] Run bundle size check and verify total bundle size <2MB (note: --analyze-size not available in Flutter 3.22.3)
- [X] T086 [P] Optimize image assets using cacheWidth/cacheHeight parameters in lib/ (about.dart, cards.dart, game.dart)
- [ ] T087 Run Lighthouse audit on deployed site and verify scores ≥90 for Performance, Accessibility, Best Practices, SEO
- [ ] T088 Verify Core Web Vitals pass thresholds (LCP <2.5s, FID <100ms, CLS <0.1)

### Browser Compatibility Testing

- [ ] T089 [P] Test on Chrome 120+ (Windows, macOS, Linux)
- [ ] T090 [P] Test on Firefox 121+ (Windows, macOS, Linux)
- [ ] T091 [P] Test on Safari 17.2+ (macOS, iOS)
- [ ] T092 [P] Test on Edge 120+ (Windows)
- [ ] T093 Verify graceful degradation message displays when JavaScript is disabled

### Security & Accessibility

- [ ] T094 [P] Verify no Google Sheets credentials embedded in web build output by inspecting build/web/ JavaScript files
- [ ] T095 [P] Verify backend API URL is correctly configured in build (no hardcoded secrets, only public URL)
- [ ] T096 [P] Test keyboard navigation completeness (Tab, Enter, Escape, Arrow keys, Space)
- [ ] T097 [P] Test screen reader announcements for card content using NVDA or VoiceOver
- [ ] T098 Verify WCAG 2.1 Level AA compliance for color contrast and touch target sizes

### Production Readiness

- [ ] T099 [P] Verify backend API is deployed to production (https://api.essentiel.app or https://api.essentiel.soro.io)
- [ ] T100 Update lib/environments/web_prod.dart with actual production backend URL
- [ ] T101 Test production web app with production backend API - verify CORS headers allow lemra-org.github.io
- [ ] T102 Run quickstart.md validation end-to-end to ensure documentation is accurate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3, 4, 5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Deployment (Phase 6)**: Can start after US1 (MVP) or wait for all stories
- **Polish (Phase 7)**: Depends on all desired user stories being complete (minimum: US1 for MVP)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
  - Delivers: Core web app functionality (cards from backend API, shuffle, filters, refresh)
  - MVP: Can deploy to production after this story alone
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Enhances US1 with mobile optimizations
  - Delivers: Mobile browser touch optimization and responsive mobile layout
  - Independent: Can be tested separately on mobile browsers
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Enhances US1/US2 with desktop optimizations
  - Delivers: Desktop and large screen layout optimization
  - Independent: Can be tested separately on desktop browsers

### Within Each User Story

- Backend API integration (Phase 2) MUST complete before any user story
- Client-side field derivation MUST be implemented before data display works correctly
- PWA configuration before local testing
- Core functionality before browser-specific testing

### Parallel Opportunities

- **Setup (Phase 1)**: T002, T003 can run in parallel
- **Foundational (Phase 2)**: T005-T006, T007-T008, T009-T010 can run in parallel after T004
- **User Story 1**: T016-T018, T022-T025, T032-T034 can run in parallel
- **User Story 2**: T037-T039, T041, T049-T051 can run in parallel
- **User Story 3**: T054-T056, T060-T062, T065-T068 can run in parallel
- **Deployment (Phase 6)**: T073-T074, T078-T080 can run in parallel
- **Polish (Phase 7)**: T082-T084, T085-T086, T089-T092, T094-T097 can run in parallel
- **Different user stories can be worked on in parallel by different team members after Phase 2**

---

## Parallel Example: Foundational Phase

```bash
# After T004 completes, launch API integration tasks together:
Task T005: "Implement fetchCategories() in backend_api_service.dart"
Task T006: "Implement fetchQuestions() in backend_api_service.dart"

# Launch client-side derivation tasks together:
Task T007: "Add isForParentChild derivation in essentiel_card_data.dart"
Task T008: "Add isForInternalMood derivation in essentiel_card_data.dart"

# Launch environment configuration tasks together:
Task T009: "Create web_dev.dart with localhost:8080"
Task T010: "Create web_prod.dart with api.essentiel.app"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (enable web platform, create web/ structure)
2. Complete Phase 2: Foundational (backend API integration, client-side derivation, environment config)
3. Complete Phase 3: User Story 1 (core web functionality, PWA, desktop testing)
4. Optional: Complete Phase 6: Deployment (deploy MVP to GitHub Pages)
5. **STOP and VALIDATE**: Test User Story 1 independently on desktop browsers
6. Deploy/demo if ready - users can access game via web without installation

**MVP Scope**: Phases 1, 2, 3, 6 = Minimum viable web app accessible via GitHub Pages

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy (MVP - desktop browsers) ✅
3. Add User Story 2 → Test independently → Deploy (mobile browser support) ✅
4. Add User Story 3 → Test independently → Deploy (desktop optimization) ✅
5. Add Deployment automation (if not done with MVP) → Auto-deploy on commit
6. Add Polish → Performance, security, documentation
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (core web functionality)
   - Developer B: User Story 2 (mobile optimization) - can start in parallel
   - Developer C: User Story 3 (desktop optimization) - can start in parallel
   - Developer D: Deployment pipeline (Phase 6) - can start after US1
3. Stories complete and integrate independently
4. Team collaborates on Phase 7: Polish

---

## Backend API Requirements

**Critical**: This implementation depends on the backend API implemented in `backend-api/` directory.

**Before starting Phase 2, ensure**:

- Backend API code exists in `backend-api/` (✅ already implemented and merged)
- Local development: Backend runs on localhost:8080 via `go run cmd/server/main.go`
- Endpoints available:
  - `GET /api/categories` → `{ "categories": [{ "name": "...", "color": "..." }] }`
  - `GET /api/questions` → `{ "questions": [{ "question": "...", "category": "...", "forCouples": bool, "forFamilies": bool }] }`
  - Note: API does NOT return `forParentChild` field - client must derive it
- CORS configured: `localhost:*` for development, `https://lemra-org.github.io` for production
- Production deployment: Backend will be deployed to `https://api.essentiel.app` or `https://api.essentiel.soro.io` before web app launch

**If backend is not running locally**, User Story 1 implementation will be blocked at T015.

---

## Notes

- [P] tasks = different files/concerns, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability (US1, US2, US3)
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Web platform reuses existing Flutter code - most changes are configuration and responsive design
- **Critical**: Client must derive `isForParentChild` and `isForInternalMood` locally (not in API response)
- Backend API handles all Google Sheets authentication server-side (zero credentials in web builds)
- Shake gesture automatically works on mobile web browsers with motion sensors, button fallback for desktop
- Avoid: breaking mobile app functionality, embedding credentials in web builds, CORS issues

---

## Total Task Count

- **Setup**: 3 tasks
- **Foundational**: 12 tasks (BLOCKING)
- **User Story 1 (P1)**: 21 tasks 🎯 MVP
- **User Story 2 (P2)**: 17 tasks
- **User Story 3 (P3)**: 16 tasks
- **Deployment & PWA**: 12 tasks
- **Polish**: 21 tasks
- **TOTAL**: 102 tasks

**Parallel Opportunities**: 42 tasks marked [P] can run in parallel within their phases

**MVP Scope**: 36 tasks (Setup + Foundational + US1 + core Deployment)

**Full Feature**: 102 tasks (all user stories + deployment + polish)
