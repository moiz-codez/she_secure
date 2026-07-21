# Task 6: Profile view-only + logout — Report

## What was implemented

Rewrote the profile screen as a view-only page that displays the current Firebase user's name, email, and phone, plus a logout button. Also rewrote widget tests to cover the profile screen.

## Files changed

| File | Change |
|------|--------|
| `lib/features/profile/presentation/profile_screen.dart` | Rewritten: CircleAvatar with initial, three `_ProfileTile` widgets (Name, Email, Phone), logout `OutlinedButton.icon` that signs out via `FirebaseAuth`, clears `SharedPreferences`, and navigates to `/login` |
| `test/widget_test.dart` | Added `Profile tests` group (4 tests). Added Firebase mock imports (`firebase_core`, `firebase_core_platform_interface/test.dart`) and `setUpAll` with `setupFirebaseCoreMocks()` + `Firebase.initializeApp()` for the profile group |
| `pubspec.yaml` | Added `firebase_core_platform_interface: ^6.0.3` to dev_dependencies (needed for `setupFirebaseCoreMocks` in tests) |
| `pubspec.lock` | Auto-updated |

## Key decisions

- **Text styles:** Used `AppTextStyles.caption` and `AppTextStyles.bodyLarge` (static class, matching existing codebase pattern from `LoginScreen`/`SignupScreen`). Did NOT use `theme.textStyles` which doesn't exist.
- **Firebase in tests:** ProfileScreen accesses `FirebaseAuth.instance.currentUser` in `build()`, which requires Firebase initialization. Added `firebase_core_platform_interface` as a dev dependency and used `setupFirebaseCoreMocks()` + `Firebase.initializeApp()` in `setUpAll` for the profile test group.
- **No `cloud_firestore` import in screen:** Removed the `cloud_firestore` import from the spec since it's not needed for this screen (only reads from `FirebaseAuth`).

## Test results

14/14 passing — 3 onboarding, 4 login, 3 signup, 4 profile.

## Commit

`3d8322d` — `feat(profile): add view-only profile with logout`

## Concerns

None.
