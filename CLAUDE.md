# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Analyze code
flutter analyze --suggestions

# Validate dependencies
flutter pub run dependency_validator

# Run tests
flutter test

# Run a single test file
flutter test test/<path_to_test>.dart

# Run the app (dev environment, default)
flutter run

# Run with a specific environment
flutter run -t lib/environments/prod.dart

# Build Android APK
flutter build apk --release -t lib/environments/prod.dart

# Build Android App Bundle
flutter build appbundle --release -t lib/environments/prod.dart
```

Flutter version is managed via asdf (see `.tool-versions`).

## Architecture

This is a Flutter quiz/card game app for Essentiel sharing groups. Cards are loaded from a **Google Sheets spreadsheet** via the `gsheets` package and displayed as a horizontally scrollable list.

### Environment System

The app uses entry-point-based environments under `lib/environments/`:
- `dev.dart` — fake/empty Google credentials, for local development
- `prod.dart` — real credentials injected at build time via CI secrets

The active environment is passed to `main()` and stored in `lib/env.dart` as a global singleton. Always target a specific environment when building for release: `-t lib/environments/prod.dart`.

### Data Flow

1. App starts with an environment config (Google Service Account credentials + spreadsheet ID)
2. `Game` widget (in `lib/game/`) fetches data from Google Sheets in `initState`
3. Two sheets are loaded: "Categories" and "Questions"
4. Cards are rendered, filtered by category, and stored preferences are persisted via `shared_preferences`

### Key Directories

- `lib/game/` — Core game UI: card display, category selector, main game screen
- `lib/environments/` — Environment entry points (dev/prod)
- `lib/resources/` — Data models: `Category`, color definitions
- `lib/widgets/` — Animated background (`Background`, `Wave`)
- `lib/about.dart` — About screen
- `lib/utils.dart` — Shared utilities

### Android Release Signing

The keystore config is loaded from `~/.droid/essentiel.keystore.properties` (local) or CI secrets. Version codes and names are derived from git tags in `android/app/build.gradle`.

### CI/CD

- **`.github/workflows/build.yml`** — Runs on push/PR: dependency check, tests, Android debug build + analyze
- **`.github/workflows/release.yml`** — Runs on GitHub Release: builds signed APK + AAB, uploads to GitHub Release and Google Play Store (`lemrapp.essentiel`)
- iOS builds are disabled (`if: false`) in both workflows

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan at
specs/001-pull-to-refresh/plan.md
<!-- SPECKIT END -->
