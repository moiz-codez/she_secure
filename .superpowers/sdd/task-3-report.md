# Task 3: Onboarding PageView + Tests

## What was implemented

- Rewrote `OnboardingScreen` from a placeholder `StatelessWidget` to a full `StatefulWidget` with a 3-page `PageView`
- Three onboarding pages: Welcome, Emergency SOS, Fake Call — each with title, body, and icon
- Animated dot indicators (width transitions between active/inactive)
- Next / Get Started button at the bottom
- Skip button in top-right corner
- On completion: sets `hasSeenOnboarding` to `true` in SharedPreferences, then navigates to `/login` via `context.go()`
- Used `AppTextStyles` static class directly (not a ThemeExtension) for text styling, matching codebase conventions

## Files changed

- `lib/features/onboarding/presentation/onboarding_screen.dart` — full rewrite
- `test/widget_test.dart` — full rewrite with 3 onboarding tests

## Test summary

All 3 tests pass:
1. **Onboarding shows first page** — verifies Welcome title, Next button, Skip button
2. **Onboarding navigates to next page** — taps Next, verifies Emergency SOS page
3. **Skip button completes onboarding** — taps Skip, verifies SharedPreferences flag set

## Notes

- `AppTextStyles` is a static utility class, not a `ThemeExtension`. Accessed directly as `AppTextStyles.displayMedium` etc.
- Tests use `GoRouter` wrapper since `_complete()` calls `context.go('/login')`
