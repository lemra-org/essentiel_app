# Feature Specification: Pull-to-Refresh Question Data

**Feature Branch**: `001-pull-to-refresh`

**Created**: 2026-05-21

**Status**: Draft

**Input**: User description: "Implement a pull-to-refresh in the app to force-refresh the questions from the Google spreadsheet"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual Question Refresh (Priority: P1)

Users need the ability to manually update questions and categories from the Google spreadsheet without restarting the app. This is particularly useful when parish staff update the spreadsheet during a group session and participants want to see the latest questions immediately.

**Why this priority**: This is the core value of the feature - enabling users to get fresh content on demand. Without this, users must close and restart the app to see updates, which is disruptive to group sessions.

**Independent Test**: Can be fully tested by pulling down on the question list screen while connected to the network and verifying that updated spreadsheet content appears after the refresh completes.

**Acceptance Scenarios**:

1. **Given** the app has loaded cached questions, **When** user pulls down on the question list, **Then** the app fetches the latest data from Google Sheets and displays updated questions and categories
2. **Given** the user initiates a pull-to-refresh, **When** the refresh is in progress, **Then** a visual loading indicator appears
3. **Given** the refresh completes successfully, **When** new data is loaded, **Then** the question list updates immediately and the loading indicator disappears
4. **Given** the user has cached data from a previous session, **When** user performs pull-to-refresh on first app launch, **Then** the app fetches fresh data and replaces cached content

---

### User Story 2 - Offline Refresh Handling (Priority: P2)

When users attempt to refresh questions without network connectivity, the app must provide clear feedback and maintain the existing cached data without errors.

**Why this priority**: Users often participate in groups in locations with intermittent connectivity. The app must handle refresh failures gracefully without losing existing content or confusing users.

**Independent Test**: Can be tested by enabling airplane mode, attempting pull-to-refresh, and verifying that cached data remains intact with appropriate user feedback.

**Acceptance Scenarios**:

1. **Given** the device has no network connectivity, **When** user pulls down to refresh, **Then** the app displays a user-friendly message in French explaining the network issue and retains existing cached questions
2. **Given** a refresh is in progress, **When** network connectivity is lost mid-fetch, **Then** the app cancels the refresh, shows an error message, and keeps the previous cached data intact
3. **Given** the refresh failed due to network issues, **When** user regains connectivity and pulls to refresh again, **Then** the app successfully fetches and updates the data

---

### User Story 3 - Refresh Feedback and Status (Priority: P3)

Users need clear visual feedback about the refresh status, including when data was last updated, to build confidence that they're seeing current content.

**Why this priority**: While less critical than the refresh functionality itself, status feedback helps users understand whether they need to refresh and confirms when refresh is complete.

**Independent Test**: Can be tested by observing the UI during and after refresh operations to verify feedback indicators appear correctly.

**Acceptance Scenarios**:

1. **Given** the refresh completes successfully, **When** the loading indicator disappears, **Then** users can immediately interact with the updated question list
2. **Given** multiple rapid pull-to-refresh gestures, **When** a refresh is already in progress, **Then** the app ignores subsequent refresh requests until the current one completes
3. **Given** the app starts with cached data, **When** the main screen loads, **Then** users can see they're viewing cached content (optional: show last update timestamp)

---

### Edge Cases

- What happens when the Google spreadsheet is temporarily unavailable (e.g., maintenance, permissions changed)?
- How does the system handle partial data fetches (e.g., categories load but questions fail)?
- What happens if the spreadsheet structure has changed (new columns, missing required fields)?
- How does the app behave when refresh is initiated while questions are being actively displayed in a quiz session?
- What happens when the spreadsheet is empty or has been cleared of all content?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to manually trigger a data refresh from the Google spreadsheet using a pull-down gesture on the question list screen
- **FR-002**: System MUST display a visual loading indicator while the refresh operation is in progress
- **FR-003**: System MUST fetch both "Categories" and "Questions" sheets when refresh is triggered
- **FR-004**: System MUST update the local cached data with fetched content upon successful refresh
- **FR-005**: System MUST preserve existing cached data if the refresh operation fails
- **FR-006**: System MUST provide user-friendly error messages in French when refresh fails due to network issues
- **FR-007**: System MUST prevent concurrent refresh operations (ignore subsequent refresh gestures while one is in progress)
- **FR-008**: System MUST complete the refresh operation and hide the loading indicator within a reasonable time or timeout with an error message
- **FR-009**: System MUST maintain app responsiveness during refresh (users can navigate away from the screen if needed)
- **FR-010**: System MUST handle spreadsheet access errors gracefully (permissions, spreadsheet deleted, malformed data)

### Key Entities

- **Question Data**: Content fetched from the "Questions" sheet - includes question text, category assignment, and any associated metadata
- **Category Data**: Content fetched from the "Categories" sheet - includes category names, colors, and display properties
- **Cached State**: Local storage of question and category data that persists between app sessions and serves as fallback during network issues
- **Refresh Operation**: The process of fetching fresh data from Google Sheets, validating it, and updating the cache

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can trigger a manual data refresh and see updated content from the spreadsheet within 5 seconds under normal network conditions
- **SC-002**: The app handles offline refresh attempts without crashes or data loss, maintaining 100% of cached data integrity
- **SC-003**: 95% of refresh operations complete successfully when network connectivity is available
- **SC-004**: Users receive clear, understandable feedback (in French) for both successful and failed refresh operations within 1 second of completion
- **SC-005**: The refresh operation does not block other app interactions - users can navigate away from the screen while refresh is in progress

## Assumptions

- Network connectivity is required for refresh to succeed, but the app gracefully degrades to cached data when offline (consistent with Principle II: Data Integrity & Offline-First)
- Google Service Account credentials remain valid and accessible through the environment configuration system
- The spreadsheet structure (sheet names "Categories" and "Questions") remains stable and matches the existing data model expectations
- The pull-to-refresh gesture is initiated from the main game screen where questions are displayed (lib/game/ directory)
- Existing data fetch logic can be reused or adapted for the manual refresh operation
- Users understand that refreshing requires a working internet connection (documented in user-facing help/about screen)
- The refresh operation uses the same Google Sheets integration (`gsheets` package) as the initial app startup data fetch
- Refresh failures do not log users out or invalidate their preferences (category selections, etc.)
- The feature targets Android devices primarily, following Principle I: Mobile-First Development
