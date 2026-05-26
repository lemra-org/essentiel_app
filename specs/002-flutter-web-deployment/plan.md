# Implementation Plan: Flutter Web Deployment

**Branch**: `002-flutter-web-deployment` | **Date**: 2026-05-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-flutter-web-deployment/spec.md`

## Summary

Deploy the existing Flutter mobile app as a web application accessible via GitHub Pages, enabling users to play the Essentiel card game directly in their browsers without installation. The web app must maintain feature parity with the mobile version while providing responsive layouts for mobile browsers (320px+) through desktop screens (up to 4K). Automated CI/CD will deploy the web build to GitHub Pages on every commit to the main branch.

## Technical Context

**Language/Version**: Dart 3.4.4 (Flutter 3.22.3-stable)

**Primary Dependencies**: 
- Flutter Web SDK (included with Flutter 3.22.3)
- Existing Flutter dependencies (google_fonts, flip_card, gsheets, etc.)
- GitHub Pages for hosting

**Storage**: Browser local storage (via shared_preferences web implementation) for user settings and cached card data from backend API

**Testing**: Flutter web testing framework (`flutter test --platform=chrome`), manual browser testing across Chrome/Firefox/Safari/Edge

**Target Platform**: Web browsers (Chrome, Firefox, Safari, Edge - last 2 major versions) on desktop, tablet, and mobile devices

**Project Type**: Mobile app with web deployment target

**Performance Goals**: 
- Initial load: <5 seconds on broadband
- Interaction latency: <100ms for touch/click responses
- Smooth 60 FPS animations

**Constraints**: 
- Must work offline after initial load (Progressive Web App capabilities)
- GitHub Pages hosting limits (100GB bandwidth/month, 1GB storage)
- Backend API dependency (implemented in `backend-api/`, deployed to https://api.essentiel.app or https://api.essentiel.soro.io)
- No native mobile features (device shake may require web API alternative or fallback)

**Scale/Scope**: Single-page web application, ~10 screens/views, targeting hundreds of concurrent users

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Mobile-First Development ✅

**Status**: COMPLIANT

**Justification**: The web app explicitly targets mobile browsers as P2 priority and uses responsive design (320px-3840px). Flutter Web uses the same codebase as the mobile app, ensuring mobile-first patterns are preserved. Touch gestures are required (FR-007).

**Action**: Test on mobile browsers first during development. Verify touch interactions work before optimizing for desktop.

### Principle II: Data Integrity & Offline-First ✅

**Status**: COMPLIANT

**Justification**: The web version uses a secure backend API (instead of direct Google Sheets access) and local caching via `shared_preferences` (which has web support through browser localStorage). Offline scenarios are explicitly tested (edge case: "What happens when user loses internet connection"). FR-005 requires preserving all existing data integrations (fulfilled via backend proxy).

**Action**: Verify `shared_preferences` web plugin caches data in browser localStorage. Test offline mode after initial load.

### Principle III: Environment Separation ✅

**Status**: COMPLIANT

**Justification**: Web builds use environment separation (`lib/environments/dev.dart` vs `prod.dart`) with platform-specific data access. Research confirmed that Service Account credentials must NOT be used in web builds (Google security best practice violation). Instead, web builds use a secure backend API (implemented in `backend-api/` directory, zero credentials in client), while mobile builds continue using Service Account credentials for direct Google Sheets access. This maintains security posture while enabling web deployment.

**Action**: Implement `kIsWeb` detection to load backend API URL for web (http://localhost:8080 for dev, https://api.essentiel.app or https://api.essentiel.soro.io for prod), Service Account for mobile. Security model documented in [quickstart.md](./quickstart.md) and [research.md](./research.md).

### Principle IV: CI/CD & Release Discipline ✅

**Status**: COMPLIANT

**Justification**: FR-010 requires automated CI/CD deployment to GitHub Pages on every main branch commit. This extends existing CI/CD practices to a new deployment target.

**Action**: Create `.github/workflows/deploy-web.yml` that builds Flutter web and deploys to GitHub Pages automatically.

### Principle V: User-Centric Quality ✅

**Status**: COMPLIANT  

**Justification**: The feature spec includes explicit user scenarios for web access (P1), mobile browser experience (P2), and desktop optimization (P3). French error messages and accessibility are preserved from mobile app. Edge cases cover JavaScript disabled, old browsers, and network failures.

**Action**: Test with non-technical users on various browsers before release. Verify error messages remain in French.

### Summary

✅ **GATE PASSED**: 5/5 principles fully compliant.

**Post-Design Verification** (completed after Phase 1): Environment separation verified - API keys for web, Service Account for mobile. Security model documented and approved.

## Project Structure

### Documentation (this feature)

```text
specs/002-flutter-web-deployment/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── web-api.md       # Web app surface area (routes, storage APIs)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Flutter project structure (existing)
lib/
├── game/                # Game UI and logic
├── environments/        # Environment configurations (dev.dart, prod.dart)
│   ├── dev.dart        # Development environment (existing)
│   └── prod.dart       # Production environment (existing)
├── resources/           # Data models (Category, Card)
├── widgets/             # Reusable UI components (Background, Wave)
├── about.dart
├── env.dart
├── main.dart           # Entry point for mobile builds
└── utils.dart

web/                     # Web-specific files (to be created)
├── index.html          # HTML template for web builds
├── manifest.json       # PWA manifest
├── icons/              # Web app icons (different sizes)
└── favicon.png

.github/workflows/
├── build.yml           # Existing mobile CI
├── release.yml         # Existing mobile release workflow
└── deploy-web.yml      # New: web deployment workflow (to be created)

build/                  # Build output (gitignored)
└── web/                # Flutter web build output (to be deployed to GitHub Pages)
```

**Structure Decision**: This is a single Flutter project with multiple build targets (Android, Web). The existing `lib/` structure supports both platforms without modification due to Flutter's cross-platform nature. Web-specific configuration lives in the `web/` directory. CI/CD workflows target different platforms.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No constitutional violations requiring justification. Environment separation verification noted but does not block development.*
