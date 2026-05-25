# Feature Specification: Backend API Service for Web App Data

**Feature Branch**: `004-backend-api-service`

**Created**: 2026-05-22

**Status**: Draft

**Input**: User description: "Backend API service in Go that provides a secure proxy to Google Sheets data for the Essentiel web app. The service should: Expose two REST endpoints: GET /api/categories and GET /api/questions; Fetch data from Google Sheets using Service Account credentials (server-side only, never exposed to clients); Return categories with name and color fields; Return questions with question text, category, and boolean flags (forCouples, forFamilies); Support CORS for lemra-org.github.io domain; Include caching headers (Cache-Control: public, max-age=300) to reduce Google Sheets API calls; Handle errors gracefully with appropriate HTTP status codes; Support deployment to a cloud platform (e.g., Cloud Run, Fly.io, Railway); Be lightweight and fast (target <100ms response time). The service acts as a security boundary - it's the only component that has Google Sheets credentials, ensuring zero credential exposure in the Flutter web app builds."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Data Access via API (Priority: P1)

The Essentiel web application can fetch card categories and questions from a public API without exposing any credentials to end users. The service acts as a secure intermediary between the web app and Google Sheets, ensuring that sensitive authentication information remains server-side only.

**Why this priority**: This is the foundational capability - without it, the web app cannot access its data. This is the core security requirement that prevents credential exposure in client-side code.

**Independent Test**: Can be fully tested by deploying the API service and making HTTP requests to the endpoints from a web browser or curl. Success means receiving properly formatted JSON responses with category and question data, with zero credentials visible in the API response or client code.

**Acceptance Scenarios**:

1. **Given** the API service is deployed, **When** a web app makes a GET request to /api/categories, **Then** the service returns a JSON array of categories with name and color fields
2. **Given** the API service is deployed, **When** a web app makes a GET request to /api/questions, **Then** the service returns a JSON array of questions with text, category, and boolean flags (forCouples, forFamilies)
3. **Given** the API service is running, **When** inspecting the API response or source code, **Then** no Google Sheets credentials or Service Account keys are visible to the client
4. **Given** data exists in the Google Sheets spreadsheet, **When** the API fetches categories and questions, **Then** the returned data accurately reflects the current spreadsheet contents

---

### User Story 2 - Cross-Origin Web Access (Priority: P2)

The web application hosted on GitHub Pages (lemra-org.github.io) can successfully call the API endpoints without being blocked by browser security policies. Users accessing the web app from their browsers experience seamless data loading without CORS errors.

**Why this priority**: Without CORS support, the web app cannot make API requests from the browser, making the service unusable. This is essential for web deployment but secondary to the core data access functionality.

**Independent Test**: Can be tested by opening the deployed web app in a browser, checking the browser console for CORS errors, and verifying that API requests complete successfully with data displayed in the app.

**Acceptance Scenarios**:

1. **Given** the web app is hosted on lemra-org.github.io, **When** the app makes a request to the API endpoints, **Then** the browser allows the request without CORS errors
2. **Given** a request comes from an unauthorized origin, **When** the API receives the request, **Then** the service rejects it with appropriate CORS policy
3. **Given** the web app makes API requests, **When** viewing browser developer tools, **Then** proper CORS headers are visible in the response (Access-Control-Allow-Origin)

---

### User Story 3 - Fast and Efficient Data Delivery (Priority: P3)

Users of the web application experience instant data loading with minimal wait times. The service optimizes performance through caching strategies that reduce redundant data fetches while maintaining data freshness.

**Why this priority**: Performance directly impacts user experience, but the service must first work correctly (P1) and be accessible (P2) before optimization matters. Fast response times make the app feel professional and responsive.

**Independent Test**: Can be tested by measuring API response times using browser developer tools or performance testing tools. Success means responses arrive in under 100ms for cached data and the service handles multiple concurrent requests without degradation.

**Acceptance Scenarios**:

1. **Given** the API has previously fetched data, **When** a subsequent request is made within 5 minutes, **Then** the service responds in under 100 milliseconds using cached data
2. **Given** multiple users are accessing the web app simultaneously, **When** concurrent API requests are made, **Then** all users receive responses without significant delay or failures
3. **Given** cached data exists, **When** the cache expires (after 5 minutes), **Then** the service automatically refreshes data from Google Sheets for the next request
4. **Given** an API request is made, **When** the response is returned, **Then** the browser receives appropriate caching headers (Cache-Control: public, max-age=300)

---

### Edge Cases

- What happens when the Google Sheets spreadsheet is temporarily unavailable or returns an error?
- How does the system handle malformed data in the spreadsheet (missing fields, invalid formats)?
- What happens when API requests exceed expected rate limits from Google Sheets?
- How does the service behave when Service Account credentials are invalid or expired?
- What happens when the API receives requests from unauthorized domains (CORS violation attempts)?
- How does the system handle extremely large spreadsheets that may cause timeout issues?
- What happens when the deployed service restarts or scales (cache invalidation)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose a GET /api/categories endpoint that returns all question categories with their names and color codes
- **FR-002**: System MUST expose a GET /api/questions endpoint that returns all questions with text, category, and boolean flags (forCouples, forFamilies)
- **FR-003**: System MUST authenticate to Google Sheets API using Service Account credentials stored securely server-side
- **FR-004**: Service Account credentials MUST NEVER be exposed in API responses, logs accessible to clients, or any client-facing communication
- **FR-005**: System MUST include CORS headers allowing requests from lemra-org.github.io domain
- **FR-006**: System MUST reject requests from unauthorized origins with appropriate CORS policy
- **FR-007**: System MUST include cache-control headers (Cache-Control: public, max-age=300) to enable browser and CDN caching
- **FR-008**: System MUST handle Google Sheets API errors gracefully with appropriate HTTP status codes (404, 500, 503)
- **FR-009**: System MUST validate data retrieved from Google Sheets before returning it to clients
- **FR-010**: System MUST be deployable to a cloud platform with minimal configuration

### Key Entities

- **Category**: Represents a question category with a name (e.g., "Famille") and a hex color code (e.g., "#FF9800")
- **Question**: Represents a card question with question text, associated category, and boolean flags indicating suitability for different contexts (couples, families, parent-child)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: API endpoints return valid JSON responses within 100 milliseconds for cached data
- **SC-002**: API endpoints return valid JSON responses within 2 seconds for fresh data fetched from Google Sheets
- **SC-003**: Web application can fetch and display categories and questions without any credential exposure visible in browser developer tools or network traffic
- **SC-004**: Service successfully handles 100 concurrent requests without errors or significant performance degradation
- **SC-005**: Web application hosted on lemra-org.github.io successfully loads data from the API without CORS errors in all major browsers (Chrome, Firefox, Safari, Edge)
- **SC-006**: Service deployment completes in under 10 minutes with standard cloud platform workflows
- **SC-007**: API responses match the data format expected by the Flutter web app (categories with name/color, questions with text/category/flags)

## Assumptions

- The existing Google Sheets spreadsheet structure (Categories sheet and Questions sheet) will remain stable
- Service Account credentials will be provided and configured securely in the deployment environment (environment variables or secret management)
- The Google Sheets spreadsheet is publicly readable or accessible by the Service Account
- Network connectivity between the deployed service and Google Sheets API is reliable
- The service will be deployed to a cloud platform that supports environment variable configuration and HTTPS
- Cache invalidation of 5 minutes (300 seconds) is acceptable for data freshness requirements
- Web app will handle API failures gracefully (show cached data or appropriate error messages)
- The spreadsheet will not exceed Google Sheets API rate limits under normal usage patterns
- Standard HTTP status codes (200, 404, 500, 503) are sufficient for error communication
- CORS restrictions only need to support lemra-org.github.io domain (no additional domains required initially)
