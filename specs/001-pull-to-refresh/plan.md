# Implementation Plan: Pull-to-Refresh Question Data

**Branch**: `001-pull-to-refresh` | **Date**: 2026-05-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-pull-to-refresh/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add pull-to-refresh functionality to the main game screen, allowing users to manually update questions and categories from the Google Sheets spreadsheet without restarting the app. This addresses the need for real-time content updates during group sessions when parish staff modify the spreadsheet.

**Technical Approach**: Wrap the existing question list UI with Flutter's `RefreshIndicator` widget, reuse existing Google Sheets fetch logic from app initialization, handle offline scenarios gracefully with French error messages, and update the local `shared_preferences` cache upon successful refresh.

## Technical Context

**Language/Version**: Dart with Flutter 3.22.3-stable

**Primary Dependencies**: 
- `gsheets` (forked version for Google Sheets API access)
- `shared_preferences` 2.1.0 (local data caching)
- `googleapis_auth` 1.3.1 (Google Service Account authentication)
- `fluttertoast` 8.2.1 (user feedback for errors)

**Storage**: 
- Google Sheets as source of truth (Categories and Questions sheets)
- `shared_preferences` for local cache persistence
- No database required

**Testing**: 
- `flutter test` for widget tests
- Manual testing on Android emulator and real devices
- Test offline scenarios explicitly per constitution

**Target Platform**: Android (primary), iOS (future consideration)

**Project Type**: Mobile app (Flutter)

**Performance Goals**: 
- Refresh completes within 5 seconds under normal network conditions
- UI remains responsive during refresh (non-blocking)
- 60 fps maintained during pull gesture and animation

**Constraints**: 
- Must work offline (graceful degradation to cached data)
- Network-dependent for fresh data
- Mobile battery and data usage considerations
- French language for all user-facing messages

**Scale/Scope**: 
- Single-user mobile app
- Small dataset: ~50-200 questions, ~10-20 categories
- Low concurrent load (one user per device)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Mobile-First Development

✅ **PASS** - Pull-to-refresh is a mobile-native interaction pattern optimized for touch devices. Design prioritizes mobile constraints (touch gesture, network availability, battery).

**Validation**:
- Pull gesture is standard mobile UX pattern
- Uses Flutter's mobile-optimized `RefreshIndicator` widget
- Handles mobile network constraints (offline, slow connections)
- Tested on real Android devices/emulators required

### Principle II: Data Integrity & Offline-First

✅ **PASS** - Maintains Google Sheets as single source of truth while ensuring offline functionality and data integrity.

**Validation**:
- Google Sheets remains source of truth (no change)
- Cached data preserved on refresh failure (FR-005)
- Network errors handled gracefully with user feedback (FR-006)
- Explicit offline testing required (per spec edge cases)
- Data flow documented: Google Sheets → Fetch → Validate → Cache → UI

### Principle III: Environment Separation

✅ **PASS** - Uses existing environment configuration system; no changes to credential management.

**Validation**:
- Reuses existing Google Service Account credentials from environment configs
- No new credential handling required
- Dev/prod separation maintained through existing `lib/environments/` system

### Principle IV: CI/CD & Release Discipline

✅ **PASS** - No CI/CD changes required; feature follows standard development and release workflow.

**Validation**:
- Standard feature branch workflow (`001-pull-to-refresh`)
- Will be released through existing GitHub Actions pipelines
- No manual deployment steps introduced

### Principle V: User-Centric Quality

✅ **PASS** - Designed for church group context with clear French feedback and simple interaction.

**Validation**:
- Simple pull-down gesture familiar to mobile users
- French error messages for network issues (FR-006)
- Clear visual feedback (loading indicator, success/error states)
- User scenarios tested: group session with live spreadsheet updates
- Maintains existing cached content on failure (no data loss)

**Constitution Check Result**: ✅ **ALL PRINCIPLES SATISFIED** - No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-pull-to-refresh/
├── plan.md              # This file (/speckit-plan command output)
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── game/                # MODIFY: Add RefreshIndicator to main game screen
│   ├── game.dart        # Main game widget - wrap with RefreshIndicator
│   └── [other game files]
├── resources/           # REUSE: Existing data models (Category, Question)
│   └── [category.dart, etc.]
├── widgets/             # REUSE: Background and other widgets unchanged
│   └── [background.dart, wave.dart]
├── environments/        # REUSE: Existing environment configs
│   ├── dev.dart
│   └── prod.dart
├── env.dart             # REUSE: Environment singleton
├── main.dart            # UNCHANGED
└── utils.dart           # POTENTIALLY EXTEND: Add refresh helper function

test/
├── widget_test.dart     # EXTEND: Add widget tests for pull-to-refresh
└── [integration tests]  # NEW: Test offline refresh scenarios

android/                 # UNCHANGED
ios/                     # UNCHANGED (currently disabled)
```

**Structure Decision**: This is a single Flutter mobile app project. The feature modifies the existing `lib/game/` directory by adding pull-to-refresh functionality to the main game screen. No new directories or major structural changes required. All changes are additive - wrapping existing UI with `RefreshIndicator` and reusing existing Google Sheets fetch logic.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations identified. This section intentionally left empty.
