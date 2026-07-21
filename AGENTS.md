# She-Secure

Personal safety app for women. Flutter, Android only, Firebase backend. Built as a local APK — not published to the Play Store.

Full product spec, screen-by-screen requirements, and acceptance criteria live in **docs/she-secure-spec.md**. Read it before starting any task — it's the source of truth, this file is just a pointer.

Build in the phases defined in Section 12 of that spec, one phase per session. Don't jump ahead to a later phase or invent scope that isn't in the spec. Anything marked 🔒 PHASE 2 in the spec is out of scope unless explicitly asked for.

## Current status

Phase 0 (Foundation) is complete and tagged `phase-0-complete`. Next is Phase 1 (Auth & onboarding).

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
├── firebase_options.dart  # placeholder — needs real values
└── main.dart
```

## Key architecture decisions

- **State management:** Riverpod. App entry point is `ProviderScope > SheSecureApp` (ConsumerWidget).
- **Routing:** go_router, wrapped in `appRouterProvider` (Provider<GoRouter>). All 14 routes from spec Section 5 are stubbed. Splash is the initial route.
- **Theme:** Dark-only `ThemeData` with `ThemeExtension<AppColorsThemeExtension>`. Access via `context.appColors`. Button and input themes centralized in `AppTheme.darkTheme`.
- **Fonts:** Sora (display), Inter (body), JetBrains Mono (data) via `google_fonts`.
- **Icons:** `phosphor_flutter`.
- **Package name:** `com.shesecure.app`.

## Firebase

`lib/firebase_options.dart` has placeholder values (`YOUR_API_KEY`, etc.). Before Phase 1, run:

```
flutterfire configure --platforms android
```

This overwrites `firebase_options.dart` with real credentials from your Firebase project. The app compiles with placeholders but won't authenticate.

## Git workflow

Conventional commits: `type(scope): description`, e.g. `feat(auth): add Firebase email/password signup`.

Push after each commit — `git push origin main`. Before starting a new phase, tag: `git tag phase-N-complete && git push origin phase-N-complete`.
