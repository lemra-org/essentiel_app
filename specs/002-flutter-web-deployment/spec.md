# Feature Specification: Flutter Web Deployment

**Feature Branch**: `002-flutter-web-deployment`

**Created**: 2026-05-22

**Status**: Draft

**Input**: User description: "To make the app more universally reachable, I want to generate a webapp from the same code, which Flutter should allow doing, right? It will be hosted on GH pages. The webapp should work on mobile phones using browsers, but also on bigger screen sizes"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Web Access Without Installation (Priority: P1)

Users can access and use the Essentiel card game directly through a web browser without installing a mobile app, making it instantly accessible to anyone with a browser and internet connection.

**Why this priority**: This is the core value proposition - removing the installation barrier. A user can share a URL and anyone can start playing immediately. This is the MVP that delivers immediate value.

**Independent Test**: Can be fully tested by navigating to the hosted URL in any modern browser and verifying all core game features work (viewing cards, shuffling, filtering categories). Delivers standalone value as users can play the game without any app installation.

**Acceptance Scenarios**:

1. **Given** a user receives a link to the web app, **When** they open it in Chrome/Firefox/Safari on desktop, **Then** the game loads and displays the card interface correctly
2. **Given** the web app is loaded, **When** the user shakes their device (mobile) or clicks shuffle, **Then** a random card is displayed
3. **Given** the web app is loaded, **When** the user navigates through cards using the horizontal scroll, **Then** cards display correctly with all visual elements (icons, categories, colors)
4. **Given** the web app is loaded, **When** the user applies category filters, **Then** only cards from selected categories are shown

---

### User Story 2 - Mobile Browser Experience (Priority: P2)

Users accessing the web app on mobile phone browsers have a seamless experience optimized for touch interaction and small screens, matching the quality of the native mobile app experience.

**Why this priority**: Mobile phones are likely the primary access method for this app. Without proper mobile optimization, the web version would be frustrating to use, negating the accessibility benefit.

**Independent Test**: Can be tested by accessing the web app on various mobile browsers (iOS Safari, Chrome Mobile, Firefox Mobile) and verifying touch gestures work smoothly, content is readable without zooming, and all interactive elements are easily tappable.

**Acceptance Scenarios**:

1. **Given** a mobile user opens the web app, **When** they view any screen, **Then** content fits the viewport without requiring horizontal scrolling or pinch-to-zoom
2. **Given** a mobile user is viewing cards, **When** they swipe horizontally, **Then** cards scroll smoothly with touch-responsive gesture recognition
3. **Given** a mobile user taps the menu button, **When** the speed dial opens, **Then** all menu items are easily tappable with appropriate spacing for fingers
4. **Given** a mobile user pulls down to refresh, **When** the refresh gesture is detected, **Then** cards reload from the Google Sheets data source

---

### User Story 3 - Desktop & Large Screen Optimization (Priority: P3)

Users on desktop computers or tablets see an optimized layout that takes advantage of larger screen real estate, providing a comfortable viewing and interaction experience without wasted space or awkward scaling.

**Why this priority**: While mobile is primary, many users may access from desktop (e.g., during video calls, presentations, or office use). A poor desktop experience would create a negative impression and limit adoption in those contexts.

**Independent Test**: Can be tested by opening the web app on desktop browsers at various window sizes and verifying the layout adapts appropriately, text remains readable, interactive elements are properly sized for mouse interaction, and the interface doesn't appear stretched or awkwardly scaled.

**Acceptance Scenarios**:

1. **Given** a desktop user opens the web app, **When** viewing cards at 1920x1080 resolution, **Then** the layout utilizes available space effectively without excessive whitespace or tiny UI elements
2. **Given** a desktop user resizes their browser window, **When** transitioning between mobile-width and desktop-width, **Then** the layout adapts smoothly without breaking or requiring page reload
3. **Given** a desktop user hovers over menu items, **When** using mouse interaction, **Then** appropriate hover states provide visual feedback
4. **Given** a tablet user in landscape mode opens the web app, **When** viewing the card list, **Then** more cards are visible simultaneously compared to portrait mobile view

---

### Edge Cases

- What happens when a user has JavaScript disabled in their browser?
- How does the app behave when the GitHub Pages hosting is temporarily unavailable?
- What happens when a user tries to use pull-to-refresh on a desktop browser without touch capability?
- How does the app handle very old browsers (e.g., IE11, older Safari versions)?
- What happens when a user loses internet connection while using the web app?
- How does the app behave on unusual screen sizes (ultra-wide monitors, very small screens)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The web application MUST provide all core game functionality available in the mobile app (card viewing, shuffling, filtering, refresh)
- **FR-002**: The web application MUST be publicly accessible via a stable URL hosted on GitHub Pages
- **FR-003**: The web application MUST load and function correctly in modern browsers (Chrome, Firefox, Safari, Edge - last 2 major versions)
- **FR-004**: The web application MUST adapt its layout responsively for viewport widths from 320px (mobile) to 3840px (4K desktop)
- **FR-005**: The web application MUST preserve all existing data integrations (Google Sheets API for cards, SharedPreferences equivalent for user settings)
- **FR-006**: The web application MUST maintain visual consistency with the mobile app (same colors, fonts, icons, branding)
- **FR-007**: The web application MUST support touch gestures on touch-enabled devices (swipe, pull-to-refresh, tap)
- **FR-008**: The web application MUST support mouse/keyboard interaction on non-touch devices
- **FR-009**: The web application MUST handle network failures gracefully with appropriate user messaging
- **FR-010**: The deployment process MUST be automated via CI/CD to GitHub Pages on every commit to the main branch

### Key Entities

No new entities are introduced by this feature. The web app uses the same data model as the existing mobile app:

- **Card**: Question text, category, special flags (isForFamilies, isForCouples, isForParentChild, isForInternalMood)
- **Category**: Name, color code
- **User Preferences**: Category filters, cached card data

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can access the web app and view their first card within 5 seconds of loading the page (on standard broadband connection)
- **SC-002**: The web app functions correctly on at least 95% of modern browser/device combinations (Chrome, Firefox, Safari, Edge on Windows, macOS, Linux, iOS, Android)
- **SC-003**: Mobile users can complete all primary game tasks (view random card, apply filters, refresh cards) using only touch gestures without needing to zoom or pan
- **SC-004**: Desktop users viewing at 1920x1080 resolution can read all text and interact with all UI elements comfortably without eye strain or precision cursor work
- **SC-005**: The web app's core functionality works identically to the mobile app, with users successfully playing the game without encountering missing features

## Assumptions

- Users have modern browsers with JavaScript enabled (no support for IE11 or browsers >3 years old)
- GitHub Pages will remain available and reliable for hosting static web content
- The existing Flutter codebase can be compiled to web without requiring major code refactoring
- Users have at least a basic broadband internet connection (3G or better for mobile, broadband for desktop)
- Browser local storage is available and enabled for caching user preferences
- The Google Sheets API integration works in browser contexts with appropriate CORS configuration
- The existing mobile UI/UX patterns (shake to shuffle, pull to refresh, speed dial menu) will translate reasonably well to web with appropriate adaptations for non-mobile contexts
