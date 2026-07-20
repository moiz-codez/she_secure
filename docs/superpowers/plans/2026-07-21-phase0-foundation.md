# Phase 0 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold a running Flutter app with themed empty shell screens, go_router navigation, Firebase connection, and Riverpod provider setup.

**Architecture:** Feature-first folder structure with shared theme system. All screens are stubs. go_router handles navigation. Firebase initialized at startup. Riverpod wraps the app for state management.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, go_router, Firebase Core/Auth, google_fonts, phosphor_flutter

## Global Constraints

- Android only — no iOS platform channels or config in v1
- Package name: `com.shesecure.app`
- Dark theme only — no theme-switching abstraction
- Fonts: Sora (display), Inter (body), JetBrains Mono (data) via google_fonts
- Icons: phosphor_flutter
- No feature-specific packages until their phase
- Spec doc: `docs/she-secure-spec.md` (Sections 5, 6)
- Design spec: `docs/superpowers/specs/2026-07-21-phase0-foundation-design.md`

---

## File Map

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point: Firebase init, ProviderScope, MaterialApp.router |
| `lib/shared/theme/app_colors.dart` | Color token constants |
| `lib/shared/theme/app_text_styles.dart` | Text style definitions |
| `lib/shared/theme/app_theme.dart` | ThemeData builder with ThemeExtensions |
| `lib/core/router/routes.dart` | Route path constants |
| `lib/core/router/app_router.dart` | GoRouter config with all 14 routes |
| `lib/features/splash/presentation/splash_screen.dart` | Stub |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | Stub |
| `lib/features/auth/presentation/login_screen.dart` | Stub |
| `lib/features/auth/presentation/signup_screen.dart` | Stub |
| `lib/features/home/presentation/home_screen.dart` | Stub |
| `lib/features/sos/presentation/sos_screen.dart` | Stub |
| `lib/features/contacts/presentation/contacts_screen.dart` | Stub |
| `lib/features/location/presentation/location_screen.dart` | Stub |
| `lib/features/recordings/presentation/recordings_screen.dart` | Stub |
| `lib/features/recordings/presentation/recording_detail_screen.dart` | Stub |
| `lib/features/fake_call/presentation/fake_call_screen.dart` | Stub |
| `lib/features/tutorial/presentation/tutorial_screen.dart` | Stub |
| `lib/features/settings/presentation/settings_screen.dart` | Stub |
| `lib/features/profile/presentation/profile_screen.dart` | Stub |

---

## Tasks

### Task 1: Create folder structure and stub screens

**Files:**
- Create: all 16 files in File Map above (excluding `lib/main.dart` — created later)

**Interfaces:**
- Consumes: none
- Produces: each stub screen is a `StatelessWidget` with a `const` constructor, taking a `Key?` parameter, returning `Center(child: Text('Screen Name'))`

- [ ] **Step 1: Create directories**

```powershell
mkdir -p lib\core\router
mkdir -p lib\core\constants
mkdir -p lib\shared\theme
mkdir -p lib\shared\widgets
mkdir -p lib\features\splash\presentation
mkdir -p lib\features\onboarding\presentation
mkdir -p lib\features\auth\presentation
mkdir -p lib\features\home\presentation
mkdir -p lib\features\sos\presentation
mkdir -p lib\features\contacts\presentation
mkdir -p lib\features\location\presentation
mkdir -p lib\features\recordings\presentation
mkdir -p lib\features\fake_call\presentation
mkdir -p lib\features\tutorial\presentation
mkdir -p lib\features\settings\presentation
mkdir -p lib\features\profile\presentation
```

- [ ] **Step 2: Create all stub screens**

Create each file with this pattern (example for splash):

```dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Splash'));
  }
}
```

Create identical stubs for: `OnboardingScreen`, `LoginScreen`, `SignupScreen`, `HomeScreen`, `SosScreen`, `ContactsScreen`, `LocationScreen`, `RecordingsScreen`, `RecordingDetailScreen`, `FakeCallScreen`, `TutorialScreen`, `SettingsScreen`, `ProfileScreen`. Each uses the class name from the filename (PascalCase) and the screen name as the text.

- [ ] **Step 3: Verify folder structure**

```powershell
Get-ChildItem -Path lib -Recurse -Directory | Select-Object FullName
```

Expected: all 16 directories exist under `lib/`.

- [ ] **Step 4: Commit**

```powershell
git add lib/; if ($?) { git commit -m "feat: create folder structure and stub screens" }
```

---

### Task 2: Add dependencies to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: none
- Produces: `flutter pub get` succeeds, all Phase 0 packages available

- [ ] **Step 1: Update pubspec.yaml dependencies**

Replace the dependencies section with:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.6.1

  # Routing
  go_router: ^14.8.1

  # Firebase
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1

  # Design system
  google_fonts: ^6.2.1
  phosphor_flutter: ^2.1.1

  cupertino_icons: ^1.0.8
```

Replace dev_dependencies with:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Run flutter pub get**

```powershell
flutter pub get
```

Expected: exit code 0, "Changed X dependencies!" (no errors).

- [ ] **Step 3: Verify packages resolve**

```powershell
dart analyze lib/main.dart 2>&1 | Select-String "error"
```

Expected: no errors about unresolved imports (main.dart doesn't import them yet, so just confirms pub resolution worked).

- [ ] **Step 4: Commit**

```powershell
git add pubspec.yaml pubspec.lock; if ($?) { git commit -m "feat: add Phase 0 dependencies" }
```

---

### Task 3: Create color tokens and text styles

**Files:**
- Create: `lib/shared/theme/app_colors.dart`
- Create: `lib/shared/theme/app_text_styles.dart`

**Interfaces:**
- Consumes: google_fonts package (Sora, Inter, JetBrains Mono)
- Produces: `AppColors` class with static color constants; `AppTextStyles` class with static `TextStyle` getters

- [ ] **Step 1: Create app_colors.dart**

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const bgBase = Color(0xFF0B0B0F);
  static const bgElevated = Color(0xFF17171D);
  static const bgElevated2 = Color(0xFF202028);

  // Accent
  static const accentAlert = Color(0xFFFF3B5C);
  static const accentAlertPressed = Color(0xFFE62E4D);
  static const accentBrand = Color(0xFF7C5CFC);
  static const accentSafe = Color(0xFF2ED573);
  static const accentWarning = Color(0xFFFFB020);

  // Text
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9B9BA8);
  static const textDisabled = Color(0xFF55555F);

  // Border
  static const borderSubtle = Color(0xFF2A2A33);

  // Gradient
  static const gradientHeroColors = [accentAlert, accentBrand];
}
```

- [ ] **Step 2: Create app_text_styles.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Display / H1 — Sora Bold 28-32
  static TextStyle displayLarge = GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // H2 — Sora SemiBold 22-24
  static TextStyle headingLarge = GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle headingMedium = GoogleFonts.sora(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // H3 / section label — Sora SemiBold 18
  static TextStyle sectionLabel = GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body — Inter Regular 15-16
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Caption / meta — Inter Medium 12-13
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle captionSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Button label — Sora SemiBold 16
  static TextStyle buttonLabel = GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Mono / data — JetBrains Mono Regular/Medium 13
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle monoMedium = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
```

- [ ] **Step 3: Verify no analysis errors**

```powershell
dart analyze lib/shared/theme/
```

Expected: "No issues found!" (or only info-level hints).

- [ ] **Step 4: Commit**

```powershell
git add lib/shared/theme/; if ($?) { git commit -m "feat: add color tokens and text styles" }
```

---

### Task 4: Create ThemeData with ThemeExtensions

**Files:**
- Create: `lib/shared/theme/app_theme.dart`

**Interfaces:**
- Consumes: `AppColors` from Task 3, `AppTextStyles` from Task 3
- Produces: `AppTheme` class with a static `darkTheme` getter returning `ThemeData`

- [ ] **Step 1: Create app_theme.dart**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class _AppColorsExtension extends ThemeExtension<_AppColorsExtension> {
  const _AppColorsExtension({
    required this.bgBase,
    required this.bgElevated,
    required this.bgElevated2,
    required this.accentAlert,
    required this.accentAlertPressed,
    required this.accentBrand,
    required this.accentSafe,
    required this.accentWarning,
    required this.borderSubtle,
  });

  final Color bgBase;
  final Color bgElevated;
  final Color bgElevated2;
  final Color accentAlert;
  final Color accentAlertPressed;
  final Color accentBrand;
  final Color accentSafe;
  final Color accentWarning;
  final Color borderSubtle;

  static const instance = _AppColorsExtension(
    bgBase: AppColors.bgBase,
    bgElevated: AppColors.bgElevated,
    bgElevated2: AppColors.bgElevated2,
    accentAlert: AppColors.accentAlert,
    accentAlertPressed: AppColors.accentAlertPressed,
    accentBrand: AppColors.accentBrand,
    accentSafe: AppColors.accentSafe,
    accentWarning: AppColors.accentWarning,
    borderSubtle: AppColors.borderSubtle,
  );

  @override
  _AppColorsExtension copyWith({
    Color? bgBase,
    Color? bgElevated,
    Color? bgElevated2,
    Color? accentAlert,
    Color? accentAlertPressed,
    Color? accentBrand,
    Color? accentSafe,
    Color? accentWarning,
    Color? borderSubtle,
  }) {
    return _AppColorsExtension(
      bgBase: bgBase ?? this.bgBase,
      bgElevated: bgElevated ?? this.bgElevated,
      bgElevated2: bgElevated2 ?? this.bgElevated2,
      accentAlert: accentAlert ?? this.accentAlert,
      accentAlertPressed: accentAlertPressed ?? this.accentAlertPressed,
      accentBrand: accentBrand ?? this.accentBrand,
      accentSafe: accentSafe ?? this.accentSafe,
      accentWarning: accentWarning ?? this.accentWarning,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  _AppColorsExtension lerp(
    covariant ThemeExtension<_AppColorsExtension>? other,
    double t,
  ) {
    if (other is! _AppColorsExtension) return this;
    return _AppColorsExtension(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgElevated2: Color.lerp(bgElevated2, other.bgElevated2, t)!,
      accentAlert: Color.lerp(accentAlert, other.accentAlert, t)!,
      accentAlertPressed: Color.lerp(accentAlertPressed, other.accentAlertPressed, t)!,
      accentBrand: Color.lerp(accentBrand, other.accentBrand, t)!,
      accentSafe: Color.lerp(accentSafe, other.accentSafe, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgBase,
        primary: AppColors.accentBrand,
        secondary: AppColors.accentBrand,
        error: AppColors.accentAlert,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        titleLarge: AppTextStyles.sectionLabel,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.caption,
        labelMedium: AppTextStyles.buttonLabel,
      ),
      extensions: const [_AppColorsExtension.instance],
    );
  }
}

/// Extension on BuildContext for convenient access to app colors.
extension AppColorsExtension on BuildContext {
  _AppColorsExtension get appColors =>
      Theme.of(this).extension<_AppColorsExtension>()!;
}
```

- [ ] **Step 2: Verify no analysis errors**

```powershell
dart analyze lib/shared/theme/
```

Expected: "No issues found!" or only info-level hints.

- [ ] **Step 3: Commit**

```powershell
git add lib/shared/theme/; if ($?) { git commit -m "feat: add ThemeData with ThemeExtensions" }
```

---

### Task 5: Create route constants and go_router config

**Files:**
- Create: `lib/core/router/routes.dart`
- Create: `lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: all 14 stub screens from Task 1
- Produces: `AppRoutes` class with static path constants; `AppRouter` class with a `router` getter returning `GoRouter`

- [ ] **Step 1: Create routes.dart**

```dart
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const sos = '/sos';
  static const contacts = '/contacts';
  static const location = '/location';
  static const recordings = '/recordings';
  static const recordingDetail = '/recordings/:id';
  static const fakeCall = '/fake-call';
  static const tutorial = '/tutorial';
  static const settings = '/settings';
  static const profile = '/profile';
}
```

- [ ] **Step 2: Create app_router.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/location/presentation/location_screen.dart';
import '../../features/recordings/presentation/recordings_screen.dart';
import '../../features/recordings/presentation/recording_detail_screen.dart';
import '../../features/fake_call/presentation/fake_call_screen.dart';
import '../../features/tutorial/presentation/tutorial_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'routes.dart';

final goRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.sos,
      builder: (context, state) => const SosScreen(),
    ),
    GoRoute(
      path: AppRoutes.contacts,
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: AppRoutes.location,
      builder: (context, state) => const LocationScreen(),
    ),
    GoRoute(
      path: AppRoutes.recordings,
      builder: (context, state) => const RecordingsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => const RecordingDetailScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.fakeCall,
      builder: (context, state) => const FakeCallScreen(),
    ),
    GoRoute(
      path: AppRoutes.tutorial,
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
```

- [ ] **Step 3: Verify no analysis errors**

```powershell
dart analyze lib/core/router/
```

Expected: "No issues found!" or only info-level hints.

- [ ] **Step 4: Commit**

```powershell
git add lib/core/router/; if ($?) { git commit -m "feat: add go_router config with all routes" }
```

---

### Task 6: Create main.dart entry point

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `AppTheme.darkTheme` from Task 4, `goRouter` from Task 5
- Produces: running app that shows Splash screen on launch

- [ ] **Step 1: Replace lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SheSecureApp()));
}

class SheSecureApp extends StatelessWidget {
  const SheSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'She-Secure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
```

Note: This won't compile yet because `firebase_options.dart` doesn't exist (created by `flutterfire configure` in Task 7). For now, create this file but comment out the Firebase lines temporarily:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SheSecureApp()));
}

class SheSecureApp extends StatelessWidget {
  const SheSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'She-Secure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
```

- [ ] **Step 2: Verify app compiles and runs**

```powershell
flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```powershell
git add lib/main.dart; if ($?) { git commit -m "feat: add app entry point with Riverpod and router" }
```

---

### Task 7: Configure Firebase for Android

**Files:**
- Modify: `lib/main.dart` (uncomment Firebase lines)
- Create: `lib/firebase_options.dart` (generated by flutterfire)

**Interfaces:**
- Consumes: existing `main.dart` from Task 6
- Produces: app that initializes Firebase on startup

- [ ] **Step 1: Run flutterfire configure**

```powershell
flutterfire configure --project <your-firebase-project-id> --platforms android
```

This generates `lib/firebase_options.dart` with Android-specific config values.

Note: You need an existing Firebase project. If you don't have one, create it at https://console.firebase.google.com first. The `flutterfire` CLI must be installed (`dart pub global activate flutterfire_cli`).

- [ ] **Step 2: Update main.dart with Firebase init**

Replace the temporary `main()` with:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SheSecureApp()));
}
```

Add imports:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
```

- [ ] **Step 3: Verify no analysis errors**

```powershell
dart analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```powershell
git add lib/; if ($?) { git commit -m "feat: configure Firebase for Android" }
```

---

### Task 8: End-to-end verification

**Files:**
- No new files — verification only

**Interfaces:**
- Consumes: all previous tasks
- Produces: app runs, shows themed Splash screen, all routes accessible

- [ ] **Step 1: Run flutter analyze on full project**

```powershell
flutter analyze
```

Expected: no errors (info-level hints acceptable).

- [ ] **Step 2: Verify app builds**

```powershell
flutter build apk --debug
```

Expected: build succeeds, APK produced at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 3: Verify routing works**

Check that the app launches to the Splash stub screen, and that `goRouter` is configured with all 14 routes. Manually verify by reading `lib/core/router/app_router.dart` and confirming route count.

- [ ] **Step 4: Verify theme applies**

Check that the Splash screen renders with `bg.base` (#0B0B0F) background and centered text. The `MaterialApp.router` in `main.dart` uses `AppTheme.darkTheme`.

- [ ] **Step 5: Final commit (if any fixes needed)**

```powershell
git add -A; if ($?) { git commit -m "chore: Phase 0 foundation complete" }
```
