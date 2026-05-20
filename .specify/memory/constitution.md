<!--
SYNC IMPACT REPORT - Constitution Update
Version: 1.0.0 (Initial)
Date: 2026-05-21

Changes:
- Created initial constitution for Essentiel Flutter app
- Established 5 core principles:
  1. Mobile-First Development
  2. Data Integrity & Offline-First
  3. Environment Separation
  4. CI/CD & Release Discipline
  5. User-Centric Quality

Added Sections:
- Core Principles (5 principles)
- Development Standards
- Release & Deployment
- Governance

Templates Requiring Updates:
✅ plan-template.md - Constitution Check section aligns with principles
✅ spec-template.md - Requirements structure supports data integrity and user testing
✅ tasks-template.md - Task organization supports phased mobile development

Follow-up TODOs: None
-->

# Essentiel Constitution

## Core Principles

### I. Mobile-First Development

Every feature must be designed and tested for mobile devices first. The app targets Android (primary) with iOS consideration for future expansion.

**Why**: Essentiel is a mobile application used by church groups on their personal devices. Mobile constraints (screen size, touch interaction, offline access, battery life) must be primary design considerations, not afterthoughts.

**How to apply**: 
- Design UI/UX for small screens and touch input first
- Test on real devices or emulators, not just desktop
- Consider mobile-specific constraints: battery, network, storage
- Use Flutter's mobile-optimized widgets and patterns
- Validate responsive behavior across different screen sizes

### II. Data Integrity & Offline-First

Google Sheets is the single source of truth for questions and categories. The app must handle offline scenarios gracefully and sync data reliably.

**Why**: Users participate in Essentiel groups in various locations with varying network quality. Data must persist locally and sync reliably when connectivity is available. Google Sheets enables non-technical parish staff to manage content without code deployments.

**How to apply**:
- Cache Google Sheets data locally using `shared_preferences`
- Handle network failures gracefully with meaningful user feedback
- Validate data integrity after fetch operations
- Never assume network availability during core gameplay
- Test offline scenarios explicitly
- Document data flow: Google Sheets → App fetch → Local cache → UI

### III. Environment Separation

Development (dev) and production (prod) environments must remain strictly separated with distinct Google Service Account credentials and configuration.

**Why**: Past incident where test data appeared in production taught us that environment mixing creates confusion for users and risks exposing development credentials. Clear separation protects production data and enables safe testing.

**How to apply**:
- NEVER commit Google Service Account credentials to git
- Use entry-point-based environments (`lib/environments/dev.dart`, `lib/environments/prod.dart`)
- Target specific environments during builds: `-t lib/environments/prod.dart`
- CI/CD must inject production credentials at build time via secrets
- Local development defaults to dev environment with fake/empty credentials
- Clearly label environment in app UI during development builds

### IV. CI/CD & Release Discipline

All releases follow automated CI/CD pipelines. Manual builds are permitted for local testing only, never for distribution.

**Why**: Manual release processes led to version inconsistencies and missing release artifacts in the past. Automated pipelines ensure consistent builds, proper signing, version tagging, and simultaneous deployment to GitHub Releases and Google Play.

**How to apply**:
- Use GitHub Actions for all release builds (`.github/workflows/release.yml`)
- Tag releases in git to trigger automated builds
- Version codes/names derive from git tags (managed in `android/app/build.gradle`)
- Sign releases using keystore from `~/.droid/essentiel.keystore.properties` (local) or CI secrets
- Build both APK and AAB formats for distribution
- Upload release artifacts to GitHub Releases and Google Play Store automatically
- NEVER bypass CI to manually upload builds to Play Store

### V. User-Centric Quality

Features must be tested from the user's perspective, considering the context of Essentiel sharing groups: families, varied technical literacy, low-pressure social settings.

**Why**: Essentiel serves church parish groups including families and members with varying technical comfort. The app must be intuitive, forgiving of mistakes, and enhance (not distract from) meaningful group conversations.

**How to apply**:
- Write user scenarios in spec.md that reflect real group usage
- Test with non-technical users before release
- Prioritize simplicity and clarity over feature richness
- Provide clear error messages in French (primary user language)
- Validate UI changes against accessibility guidelines
- Consider group dynamics: multiple people viewing one device, easy navigation between questions

## Development Standards

**Flutter Version Management**: Use `asdf` with `.tool-versions` to ensure consistent Flutter SDK versions across development environments and CI.

**Code Quality Gates**:
- `flutter analyze --suggestions` must pass with zero issues
- `flutter pub run dependency_validator` must pass
- `flutter test` must pass all tests before merge

**Dependency Management**:
- Keep dependencies minimal and justified
- Document why each major dependency is required
- Review dependency updates for breaking changes before upgrading
- Validate with `dependency_validator` before committing

**Testing Requirements**:
- Widget tests for UI components
- Integration tests for data flow (Google Sheets → Cache → UI)
- Test offline scenarios explicitly
- Run tests in CI on every push/PR

**Architecture Consistency**:
- Follow existing directory structure:
  - `lib/game/` - Game UI and logic
  - `lib/environments/` - Environment configurations
  - `lib/resources/` - Data models and constants
  - `lib/widgets/` - Reusable UI components
- Data models remain in `lib/resources/`
- Environment configs remain simple entry points, not service layers

## Release & Deployment

**Versioning**: Semantic versioning derived from git tags, managed automatically in `android/app/build.gradle`.

**Release Process**:
1. Create GitHub Release with version tag
2. CI builds signed APK + AAB automatically
3. CI uploads to GitHub Release and Google Play Store
4. Verify deployment in Play Console

**Signing**: Android release signing uses keystore configured in `~/.droid/essentiel.keystore.properties` (local) or injected via CI secrets (production).

**Deployment Targets**:
- Google Play Store package: `lemrapp.essentiel`
- iOS builds currently disabled (`if: false` in workflows) - reserved for future expansion

**Rollback Policy**: If critical bug discovered post-release, create hotfix tag and let CI rebuild/redeploy. Do not manually upload builds.

## Governance

This constitution supersedes all other development practices and preferences. When in doubt, these principles take precedence.

**Amendment Process**:
1. Propose changes with clear rationale and impact analysis
2. Document why current principles are insufficient
3. Update constitution version using semantic versioning:
   - MAJOR: Backward-incompatible governance changes, principle removals
   - MINOR: New principles added or material expansions
   - PATCH: Clarifications, wording fixes, non-semantic refinements
4. Propagate changes to dependent templates (plan, spec, tasks)
5. Commit with message: `docs: amend constitution to vX.Y.Z (description)`

**Compliance**:
- All PRs must align with these principles
- Constitution checks in `plan.md` must gate feature development
- Violations require explicit justification in Complexity Tracking section
- Feature specs must reference relevant principles

**Runtime Guidance**: See `CLAUDE.md` for operational guidance when working with this codebase.

**Version**: 1.0.0 | **Ratified**: 2026-05-21 | **Last Amended**: 2026-05-21
