# Phase 0 — Foundation Design

**Package name:** `com.shesecure.app`

## Folder structure

```
lib/
├── core/
│   ├── router/
│   │   ├── app_router.dart        # go_router config, route definitions, redirect logic
│   │   └── routes.dart            # Route path constants
│   └── constants/
├── features/
│   ├── splash/presentation/       # Stub
│   ├── onboarding/presentation/   # Stub
│   ├── auth/presentation/         # Stub (login + signup screens)
│   ├── home/presentation/         # Stub
│   ├── sos/presentation/          # Stub
│   ├── contacts/presentation/     # Stub
│   ├── location/presentation/     # Stub
│   ├── recordings/presentation/   # Stub
│   ├── fake_call/presentation/    # Stub
│   ├── tutorial/presentation/     # Stub
│   ├── settings/presentation/     # Stub
│   └── profile/presentation/      # Stub
├── shared/
│   ├── theme/
│   │   ├── app_theme.dart         # ThemeData + dark theme
│   │   ├── app_colors.dart        # Color tokens from Section 6
│   │   └── app_text_styles.dart   # Typography from Section 6
│   └── widgets/
└── main.dart
```

Each feature stub is a single `StatelessWidget` returning a centered `Text` with the screen name — just enough to prove routing works.

## Dependencies (Phase 0 only)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  google_fonts: ^6.2.1
  phosphor_flutter: ^2.1.1
```

Feature-specific packages (telephony, geolocator, camera, etc.) are deferred to their respective phases.

## Theme (Section 6 tokens)

Dark-only `ThemeData`:

- **Scaffold background:** `#0B0B0F` (bg.base)
- **Card/sheet background:** `#17171D` (bg.elevated)
- **Nested card/input background:** `#202028` (bg.elevated2)
- **Primary text:** `#F5F5F7` (text.primary)
- **Secondary text:** `#9B9BA8` (text.secondary)
- **Disabled text:** `#55555F` (text.disabled)
- **Border:** `#2A2A33` (border.subtle)
- **Accent alert (SOS):** `#FF3B5C`
- **Accent brand:** `#7C5CFC`
- **Accent safe:** `#2ED573`
- **Accent warning:** `#FFB020`
- **Gradient hero:** `linear-gradient(135deg, #FF3B5C 0%, #7C5CFC 100%)`

Colors exposed via `ThemeExtension<AppColors>`. Text styles via `ThemeExtension<AppTextStyles>`.

Fonts loaded via `google_fonts`: Sora (display/heading), Inter (body), JetBrains Mono (data).

## Router

All 14 routes from Section 5 as stubs:

| Path | Stub screen |
|---|---|
| `/splash` | SplashStub (initial route, with redirect) |
| `/onboarding` | OnboardingStub |
| `/login` | LoginStub |
| `/signup` | SignupStub |
| `/home` | HomeStub |
| `/sos` | SosStub |
| `/contacts` | ContactsStub |
| `/location` | LocationStub |
| `/recordings` | RecordingsStub |
| `/recordings/:id` | RecordingDetailStub |
| `/fake-call` | FakeCallStub |
| `/tutorial` | TutorialStub |
| `/settings` | SettingsStub |
| `/profile` | ProfileStub |

Splash screen redirect logic (stubbed for now, will be wired in Phase 1):
- Default: route to `/home` (placeholder — real logic in Phase 1)

## Firebase

- `flutterfire configure` for Android only (`com.shesecure.app`)
- `Firebase.initializeApp()` in `main.dart` before `runApp()`
- Firebase options from generated `firebase_options.dart`

## Riverpod

Minimal scaffolding:
- `ProviderScope` at root in `main.dart`
- `GoRouter` instance provided via `Provider<AppRouter>`
- No feature-level providers yet

## Entry point

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: SheSecureApp()));
}
```

`SheSecureApp` is a `ConsumerWidget` that reads the `AppRouter` provider and builds a `MaterialApp.router` with the dark theme and router config.
