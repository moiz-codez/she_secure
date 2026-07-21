# Task 5 Report: Create route constants and go_router config

## What Was Implemented

Created two files for app-wide routing:

1. **`lib/core/router/routes.dart`** - `AppRoutes` abstract final class with 14 static path constants (splash, onboarding, login, signup, home, sos, contacts, location, recordings, recordingDetail, fakeCall, tutorial, settings, profile).

2. **`lib/core/router/app_router.dart`** - `GoRouter` instance (`goRouter`) configured with all 14 routes, including a nested route for recording detail (`/recordings/:id`). Initial location set to splash.

## Files Changed

| File | Action |
|------|--------|
| `lib/core/router/routes.dart` | Created |
| `lib/core/router/app_router.dart` | Created |

## Verification

- `dart analyze lib/core/router/` passed with no issues
- All 14 stub screens from `lib/features/*/presentation/` confirmed to exist and import correctly
- go_router v14.8.1 already in pubspec.yaml

## Issues / Concerns

- Removed unused `flutter/material.dart` import from `app_router.dart` (was flagged by analyzer).
- The `goRouter` instance is a top-level `final` — appropriate for Phase 1. Will be refactored to use Riverpod `Provider` when auth logic is added in Phase 2.
