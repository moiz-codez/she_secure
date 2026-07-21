# Task 2: Splash redirect logic + tests

## What was implemented

Rewrote `SplashScreen` from a stateless placeholder to a `StatefulWidget` that:
1. Delays 2 seconds on launch
2. Checks `SharedPreferences` for `hasSeenOnboarding`
3. Redirects to `/onboarding` if false/null, otherwise to `/login`
4. Includes a `TODO` comment for Firebase Auth check (Task 4)

The branding text was updated from `'Splash'` to `'SheSecure'` / `'Safety at your fingertips'`.

## Files changed

- `lib/features/splash/presentation/splash_screen.dart` — rewritten as StatefulWidget with redirect logic
- `test/widget_test.dart` — rewritten with GoRouter-based test that verifies branding text

## Test approach

The test uses `GoRouter` (not plain `MaterialApp`) because the splash screen calls `context.go(...)`, which requires a GoRouter ancestor. SharedPreferences is mocked with `hasSeenOnboarding: true` so the redirect goes to `/login`. After `pump(Duration(seconds: 2))` the timer resolves cleanly.

## Commit

`3020a86` — `feat(splash): add redirect logic with onboarding check`
