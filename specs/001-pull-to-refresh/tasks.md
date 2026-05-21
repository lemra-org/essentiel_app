# Tasks: Pull-to-Refresh Question Data

**Input**: Design documents from `/specs/001-pull-to-refresh/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Tests are OPTIONAL for this feature. Manual testing scenarios are documented in quickstart.md. Widget tests can be added in Phase 6 (Polish) if time permits.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter project structure: `lib/`, `test/` at repository root
- Main modification: `lib/game/game.dart` (Game widget)
- Existing models: `lib/resources/` (Category, Question - reused, not modified)
- Utilities: `lib/utils.dart` (optional helper functions)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Environment verification and dependency check

- [X] T001 Verify Flutter dependencies are installed via `flutter pub get`
- [X] T002 Verify Flutter version matches .tool-versions (3.22.3-stable) via `asdf current flutter`
- [X] T003 Run `flutter analyze --suggestions` to ensure codebase has zero issues before modifications

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Refactor existing code to enable refresh functionality

**⚠️ CRITICAL**: This phase must be complete before ANY user story can be implemented

- [X] T004 Read existing fetch logic in lib/game/game.dart to understand current Google Sheets data loading implementation
- [X] T005 Extract Google Sheets fetch logic from initState into reusable method `_fetchQuestionsFromSheets()` in lib/game/game.dart
- [X] T006 Verify extracted method works by testing initial app load (no regression in existing functionality)

**Checkpoint**: Foundation ready - fetch logic is reusable for both initial load and manual refresh

---

## Phase 3: User Story 1 - Manual Question Refresh (Priority: P1) 🎯 MVP

**Goal**: Enable users to manually refresh questions and categories by pulling down on the question list

**Independent Test**: Pull down on question list while connected to network, verify updated spreadsheet content appears after refresh completes

### Implementation for User Story 1

- [X] T007 [US1] Locate the scrollable widget (ListView/GridView) in lib/game/game.dart that displays questions
- [X] T008 [US1] Wrap the scrollable widget with RefreshIndicator in lib/game/game.dart
- [X] T009 [US1] Implement `_handleRefresh()` callback method in lib/game/game.dart that returns Future<void>
- [X] T010 [US1] Call `_fetchQuestionsFromSheets()` from `_handleRefresh()` to fetch fresh data in lib/game/game.dart
- [X] T011 [US1] Update widget state after successful refresh to display new questions in lib/game/game.dart
- [X] T012 [US1] Test basic pull-to-refresh: pull down gesture triggers refresh, loading spinner appears, data updates

**Checkpoint**: At this point, User Story 1 should be fully functional - users can pull to refresh and see updated content

---

## Phase 4: User Story 2 - Offline Refresh Handling (Priority: P2)

**Goal**: Handle network errors gracefully, preserve cached data, display French error messages

**Independent Test**: Enable airplane mode, attempt pull-to-refresh, verify cached data remains intact with French error message

### Implementation for User Story 2

- [X] T013 [US2] Add try-catch block around fetch logic in `_handleRefresh()` in lib/game/game.dart
- [X] T014 [US2] Define French error message constants at top of lib/game/game.dart or in lib/utils.dart
- [X] T015 [US2] Import fluttertoast package in lib/game/game.dart (already in dependencies)
- [X] T016 [US2] Implement error handler for SocketException (no network) in lib/game/game.dart - display "Pas de connexion réseau. Veuillez vérifier votre connexion."
- [X] T017 [US2] Implement error handler for timeout errors in lib/game/game.dart - display "Le chargement des questions a expiré. Réessayez plus tard."
- [X] T018 [US2] Implement error handler for permission/access errors in lib/game/game.dart - display "Impossible d'accéder à la feuille de calcul."
- [X] T019 [US2] Implement generic error handler (catch-all) in lib/game/game.dart - display "Erreur lors du chargement des questions."
- [X] T020 [US2] Verify cache is NOT modified on refresh failure (only update cache on successful fetch)
- [X] T021 [US2] Test offline scenario: airplane mode → pull-to-refresh → verify French error message and cached data preserved

**Checkpoint**: At this point, User Stories 1 AND 2 both work - manual refresh with robust error handling

---

## Phase 5: User Story 3 - Refresh Feedback and Status (Priority: P3)

**Goal**: Prevent concurrent refresh operations, enhance visual feedback

**Independent Test**: Rapidly pull down multiple times while refresh in progress, verify only one operation executes

### Implementation for User Story 3

- [X] T022 [US3] Add boolean field `_isRefreshing = false` to Game widget state in lib/game/game.dart
- [X] T023 [US3] Check `_isRefreshing` flag at start of `_handleRefresh()` - return early if true in lib/game/game.dart
- [X] T024 [US3] Set `_isRefreshing = true` at start of fetch operation in lib/game/game.dart
- [X] T025 [US3] Set `_isRefreshing = false` in finally block after fetch (success or error) in lib/game/game.dart
- [X] T026 [US3] Test concurrent refresh prevention: rapid pull gestures while refresh in progress → verify only one operation executes

**Checkpoint**: All user stories complete - full pull-to-refresh functionality with error handling and concurrency control

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, testing, and quality assurance

- [X] T027 [P] Run `flutter analyze --suggestions` to ensure zero issues
- [X] T028 [P] Run `flutter pub run dependency_validator` to validate dependencies
- [ ] T029 Test all scenarios from quickstart.md: online refresh, offline refresh, concurrent refresh, slow network, permission errors
- [ ] T030 [P] Manual testing on Android emulator (verify pull gesture, loading indicator, error messages)
- [ ] T031 [P] Manual testing on real Android device (verify performance, network handling)
- [ ] T032 (OPTIONAL) Add widget test for RefreshIndicator in test/widget_test.dart
- [ ] T033 (OPTIONAL) Add integration test for offline refresh scenario in test/integration/
- [ ] T034 Verify FR-001 through FR-010 from spec.md are all satisfied
- [ ] T035 Verify SC-001 through SC-005 (success criteria) from spec.md are met
- [ ] T036 Update about screen or help documentation to mention pull-to-refresh feature in lib/about.dart (optional)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P2): Depends on User Story 1 completion (builds on _handleRefresh method)
  - User Story 3 (P3): Depends on User Story 1 completion (enhances _handleRefresh method)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 completion - adds error handling to existing _handleRefresh
- **User Story 3 (P3)**: Depends on User Story 1 completion - adds concurrency control to existing _handleRefresh

**Note**: US2 and US3 both modify the same method (_handleRefresh), so they must be done sequentially after US1.

### Within Each User Story

- **User Story 1**: Sequential tasks (T007 → T008 → T009 → T010 → T011 → T012)
  - Locate widget → Wrap with RefreshIndicator → Implement callback → Call fetch → Update state → Test
- **User Story 2**: Sequential tasks with some parallel opportunities
  - T013 must be first (add try-catch structure)
  - T014, T015 can run in parallel (define constants, import package)
  - T016-T019 sequential (add error handlers one by one)
  - T020, T021 are validation/testing
- **User Story 3**: Sequential tasks (T022 → T023 → T024 → T025 → T026)
  - Add flag → Check flag → Set flag true → Set flag false in finally → Test

### Parallel Opportunities

- **Setup Phase**: T001, T002, T003 can run sequentially (quick verification tasks)
- **Foundational Phase**: Sequential (T004 → T005 → T006) - refactoring existing code
- **User Story 2**: T014 and T015 can run in parallel (define constants + import package)
- **Polish Phase**: T027, T028, T030, T031, T032, T033 can run in parallel (different validation activities)

**Important**: Most tasks in this feature are sequential because they modify the same file (lib/game/game.dart) and build on each other incrementally.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (extract fetch logic)
3. Complete Phase 3: User Story 1 (basic pull-to-refresh)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Pull down on question list
   - Verify loading spinner appears
   - Verify data refreshes
   - Verify works on emulator and real device
5. Deploy/demo if ready (MVP complete!)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **First deployable increment (MVP!)**
3. Add User Story 2 → Test independently → **Second increment (error handling)**
4. Add User Story 3 → Test independently → **Third increment (polished experience)**
5. Each story adds value without breaking previous stories

### Full Feature Delivery

For complete feature with all user stories:

1. Complete Phases 1-2 (Setup + Foundational)
2. Implement User Story 1 (T007-T012) → Test checkpoint
3. Implement User Story 2 (T013-T021) → Test checkpoint
4. Implement User Story 3 (T022-T026) → Test checkpoint
5. Polish and validate (Phase 6: T027-T036)
6. Final testing using all scenarios from quickstart.md
7. Submit PR for review

**Estimated Effort**:
- Phase 1 (Setup): 15 minutes
- Phase 2 (Foundational): 30-45 minutes (extract and test existing logic)
- Phase 3 (US1): 45-60 minutes (core implementation)
- Phase 4 (US2): 30-45 minutes (error handling)
- Phase 5 (US3): 20-30 minutes (concurrency control)
- Phase 6 (Polish): 45-60 minutes (testing and validation)
- **Total**: 3-4 hours for complete feature

---

## Notes

- All tasks modify lib/game/game.dart - sequential execution recommended
- No new dependencies required (all packages already in pubspec.yaml)
- No database changes (uses existing shared_preferences cache)
- No environment config changes (reuses existing Google Service Account setup)
- Commit after each completed user story checkpoint
- Follow constitution principles:
  - Test on real Android devices (Principle I: Mobile-First)
  - Verify offline scenarios (Principle II: Data Integrity & Offline-First)
  - French error messages required (Principle V: User-Centric Quality)
- Avoid: Adding new dependencies, creating new files unnecessarily, modifying data models
- Focus: Minimal code changes to achieve maximum user value

## Testing Reference

All manual testing scenarios are documented in `specs/001-pull-to-refresh/quickstart.md`:
- Scenario 1: Successful refresh (online)
- Scenario 2: Offline refresh (no network)
- Scenario 3: Network loss during refresh
- Scenario 4: Concurrent refresh prevention
- Scenario 5: Slow network performance
- Scenario 6: Spreadsheet permission error
- Scenario 7: Malformed spreadsheet data
- Scenario 8: Rapid app switching

Use quickstart.md as the testing guide for Phase 6 validation.
