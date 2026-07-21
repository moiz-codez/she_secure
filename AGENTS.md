# She-Secure

Personal safety app for women. Flutter, Android only, Firebase backend. Built as a local APK — not published to the Play Store.

Full product spec, screen-by-screen requirements, and acceptance criteria live in **docs/she-secure-spec.md**. Read it before starting any task — it's the source of truth, this file is just a pointer.

Build in the phases defined in Section 12 of that spec, one phase per session. Don't jump ahead to a later phase or invent scope that isn't in the spec. Anything marked 🔒 PHASE 2 in the spec is out of scope unless explicitly asked for.

## Current status

Phase 0 (Foundation) is complete and tagged `phase-0-complete`. Phase 1 (Auth & onboarding) is complete and tagged `phase-1-complete`. Next is Phase 2.

## Build / test / lint

```
flutter pub get          # install deps
flutter analyze          # lint (dart analyze)
flutter test             # all tests
flutter test test/widget_test.dart   # single test
flutter build apk --debug            # debug APK
```

## Project structure

Feature-first. Each feature lives under `lib/features/<name>/presentation/`. Shared infra in `lib/core/` and `lib/shared/`.

```
lib/
├── core/router/          # go_router config (app_router.dart, routes.dart)
├── shared/theme/         # AppColors, AppTextStyles, AppTheme
├── shared/widgets/       # (empty — reusable widgets go here)
├── features/
│   ├── splash/presentation/splash_screen.dart
│   ├── onboarding/presentation/
│   ├── auth/presentation/        # login_screen.dart, signup_screen.dart
│   ├── home/presentation/
│   ├── sos/presentation/
│   ├── contacts/presentation/
│   ├── location/presentation/
│   ├── recordings/presentation/
│   ├── fake_call/presentation/
│   ├── tutorial/presentation/
│   ├── settings/presentation/
│   └── profile/presentation/
├── firebase_options.dart  # real Firebase creds (project: she-2b713)
└── main.dart
```

## Key architecture decisions

- **State management:** Riverpod. App entry point is `ProviderScope > SheSecureApp` (ConsumerWidget).
- **Routing:** go_router, wrapped in `appRouterProvider` (Provider<GoRouter>). All 14 routes from spec Section 5 are stubbed. Splash is the initial route.
- **Auth redirect:** `AuthStateNotifier` wraps `FirebaseAuth.authStateChanges()` as a `ChangeNotifier`, wired as `refreshListenable` on GoRouter. The `redirect` callback in `app_router.dart` handles onboarding-seen check + auth state routing reactively. This is the critical pattern — don't add manual auth checks in individual screens.
- **Theme:** Dark-only `ThemeData` with `ThemeExtension<AppColorsThemeExtension>`. Access via `context.appColors`. Button and input themes centralized in `AppTheme.darkTheme`.
- **Fonts:** Sora (display), Inter (body), JetBrains Mono (data) via `google_fonts`.
- **Icons:** `phosphor_flutter`.
- **Package name:** `com.shesecure.app`.

## Firebase

`lib/firebase_options.dart` has real credentials for project `she-2b713`. If you need to reconfigure:

```
flutterfire configure --platforms android
```

## Git workflow

Conventional commits: `type(scope): description`, e.g. `feat(auth): add Firebase email/password signup`.

Push after each commit — `git push origin main`. Before starting a new phase, tag: `git tag phase-N-complete && git push origin phase-N-complete`.
