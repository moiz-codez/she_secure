# Phase 1 — Auth & Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Splash redirect logic, Onboarding flow, Login/Signup with Firebase Auth, and view-only Profile screen.

**Architecture:** Splash reads SharedPreferences + Firebase Auth state to route users. Onboarding is a PageView that sets `onboardingSeen` flag. Login/Signup use Firebase Auth email/password with inline validation. Profile displays user data from Firestore.

**Tech Stack:** Flutter, Dart, Riverpod, go_router, firebase_auth, cloud_firestore, shared_preferences, google_fonts, phosphor_flutter

## Global Constraints

- Android only — no iOS platform channels or config in v1
- Package name: `com.shesecure.app`
- Dark theme only — no theme-switching abstraction
- Fonts: Sora (display), Inter (body), JetBrains Mono (data) via google_fonts
- Icons: phosphor_flutter
- Spec doc: `docs/she-secure-spec.md` (Sections 8.1, 8.2, 8.3, 8.12)
- Design spec: `docs/superpowers/specs/2026-07-21-phase1-auth-onboarding-design.md`

---

## File Map

| File | Purpose |
|---|---|
| `lib/features/splash/presentation/splash_screen.dart` | Rewrite: redirect logic based on onboardingSeen + auth state |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | Rewrite: 5-slide PageView with Skip/Next/Get Started |
| `lib/features/auth/presentation/login_screen.dart` | Rewrite: email/password form + Firebase Auth sign-in |
| `lib/features/auth/presentation/signup_screen.dart` | Rewrite: registration form + Firebase Auth create user |
| `lib/features/profile/presentation/profile_screen.dart` | Rewrite: view-only profile display + logout |
| `lib/core/router/app_router.dart` | Modify: may need redirect logic for auth guard |
| `test/features/splash/presentation/splash_screen_test.dart` | Create: 3 redirect outcome tests |
| `test/features/onboarding/presentation/onboarding_screen_test.dart` | Create: Skip/Get Started tests |
| `test/features/auth/presentation/login_screen_test.dart` | Create: validation tests |
| `test/features/auth/presentation/signup_screen_test.dart` | Create: validation tests |

---

## Tasks

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: none
- Produces: `shared_preferences` and `cloud_firestore` available

- [ ] **Step 1: Add packages to pubspec.yaml dependencies**

Add after the existing Firebase section:

```yaml
  # Local storage
  shared_preferences: ^2.3.4

  # Cloud Firestore
  cloud_firestore: ^5.6.5
```

- [ ] **Step 2: Run flutter pub get**

```powershell
flutter pub get
```

Expected: exit code 0.

- [ ] **Step 3: Commit**

```powershell
git add pubspec.yaml pubspec.lock; if ($?) { git commit -m "feat: add shared_preferences and cloud_firestore" }
```

---

### Task 2: Splash screen — redirect logic + tests

**Files:**
- Modify: `lib/features/splash/presentation/splash_screen.dart`
- Create: `test/features/splash/presentation/splash_screen_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences` (for `onboardingSeen`), `FirebaseAuth` (for current user)
- Produces: navigates to `/onboarding`, `/login`, or `/home` based on state

**TDD: Write tests first, then implement.**

- [ ] **Step 1: Create test directory**

```powershell
mkdir -p test\features\splash\presentation
```

- [ ] **Step 2: Write the failing tests**

Create `test/features/splash/presentation/splash_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:she_secure/core/router/routes.dart';
import 'package:she_secure/features/splash/presentation/splash_screen.dart';

// Mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  group('SplashScreen redirect logic', () {
    testWidgets('routes to Onboarding when onboardingSeen is false', (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(mockPrefs.getBool('onboardingSeen')).thenReturn(false);

      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => SplashScreen(prefs: mockPrefs),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const Scaffold(body: Text('Onboarding')),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('routes to Login when onboardingSeen but not authenticated', (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(mockPrefs.getBool('onboardingSeen')).thenReturn(true);

      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => SplashScreen(prefs: mockPrefs),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const Scaffold(body: Text('Onboarding')),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('routes to Home when onboardingSeen and authenticated', (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(mockPrefs.getBool('onboardingSeen')).thenReturn(true);

      final mockAuth = MockFirebaseAuth();
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);

      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => SplashScreen(
              prefs: mockPrefs,
              auth: mockAuth,
            ),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const Scaffold(body: Text('Onboarding')),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

```powershell
flutter test test\features\splash\presentation\splash_screen_test.dart
```

Expected: FAIL — `SplashScreen` doesn't accept `prefs` or `auth` parameters yet.

- [ ] **Step 4: Implement SplashScreen**

Replace `lib/features/splash/presentation/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    SharedPreferences? prefs,
    FirebaseAuth? auth,
  })  : _prefs = prefs,
        _auth = auth;

  final SharedPreferences? _prefs;
  final FirebaseAuth? _auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final prefs = widget._prefs ?? await SharedPreferences.getInstance();
    final auth = widget._auth ?? FirebaseAuth.instance;

    final onboardingSeen = prefs.getBool('onboardingSeen') ?? false;

    if (!onboardingSeen) {
      if (mounted) context.go(AppRoutes.onboarding);
      return;
    }

    final user = auth.currentUser;
    if (user != null) {
      if (mounted) context.go(AppRoutes.home);
    } else {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with gradient glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppColors.gradientHeroColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentAlert.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 60,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'She-Secure',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
flutter test test\features\splash\presentation\splash_screen_test.dart
```

Expected: 3/3 PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib\features\splash\ test\features\splash\; if ($?) { git commit -m "feat(splash): add redirect logic based on onboardingSeen and auth state" }
```

---

### Task 3: Onboarding screen — PageView + tests

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart`
- Create: `test/features/onboarding/presentation/onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences` (for setting `onboardingSeen`)
- Produces: navigates to `/login` after Skip or Get Started

- [ ] **Step 1: Create test directory**

```powershell
mkdir -p test\features\onboarding\presentation
```

- [ ] **Step 2: Write the failing tests**

Create `test/features/onboarding/presentation/onboarding_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:she_secure/core/router/routes.dart';
import 'package:she_secure/features/onboarding/presentation/onboarding_screen.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('OnboardingScreen', () {
    testWidgets('Skip sets onboardingSeen and navigates to Login', (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(mockPrefs.setBool('onboardingSeen', true)).thenAnswer((_) async => true);

      final router = GoRouter(
        initialLocation: AppRoutes.onboarding,
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => OnboardingScreen(prefs: mockPrefs),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      verify(mockPrefs.setBool('onboardingSeen', true)).called(1);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Get Started sets onboardingSeen and navigates to Login', (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(mockPrefs.setBool('onboardingSeen', true)).thenAnswer((_) async => true);

      final router = GoRouter(
        initialLocation: AppRoutes.onboarding,
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => OnboardingScreen(prefs: mockPrefs),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Swipe to last slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      verify(mockPrefs.setBool('onboardingSeen', true)).called(1);
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

```powershell
flutter test test\features\onboarding\presentation\onboarding_screen_test.dart
```

Expected: FAIL — `OnboardingScreen` doesn't accept `prefs` parameter yet.

- [ ] **Step 4: Implement OnboardingScreen**

Replace `lib/features/onboarding/presentation/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, SharedPreferences? prefs})
      : _prefs = prefs;

  final SharedPreferences? _prefs;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: PhosphorIcons.shieldCheck,
      title: 'Welcome to She-Secure',
      description: 'Your personal safety companion. One tap to alert the people you trust.',
    ),
    _OnboardingSlide(
      icon: PhosphorIcons.warning,
      title: 'SOS Alert',
      description: 'Press the SOS button to immediately notify your trusted contacts with your location.',
    ),
    _OnboardingSlide(
      icon: PhosphorIcons.users,
      title: 'Trusted Contacts',
      description: 'Add the people who matter most. They\'ll be alerted when you need help.',
    ),
    _OnboardingSlide(
      icon: PhosphorIcons.phone,
      title: 'Fake Call',
      description: 'A believable exit from uncomfortable situations. Schedule a call that looks real.',
    ),
    _OnboardingSlide(
      icon: PhosphorIcons.videoCamera,
      title: 'Recordings',
      description: 'Discreet evidence capture. Video, audio, or photos — stored only on your device.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = widget._prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: isLastPage
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: AppColors.gradientHeroColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 60,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          style: GoogleFonts.sora(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.accentBrand
                        : AppColors.borderSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
flutter test test\features\onboarding\presentation\onboarding_screen_test.dart
```

Expected: 2/2 PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib\features\onboarding\ test\features\onboarding\; if ($?) { git commit -m "feat(onboarding): add 5-slide PageView with Skip/Get Started" }
```

---

### Task 4: Login screen — form + Firebase Auth + tests

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart`
- Create: `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Consumes: `FirebaseAuth` (for sign-in)
- Produces: navigates to `/home` on success, shows error messages on failure

- [ ] **Step 1: Create test directory**

```powershell
mkdir -p test\features\auth\presentation
```

- [ ] **Step 2: Write the failing tests**

Create `test/features/auth/presentation/login_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:she_secure/core/router/routes.dart';
import 'package:she_secure/features/auth/presentation/login_screen.dart';

void main() {
  group('LoginScreen validation', () {
    testWidgets('shows error for empty email', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Tap login without entering email
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'test@example.com',
      );

      // Enter short password
      await tester.enterText(
        find.byKey(const Key('login-password')),
        '123',
      );

      // Tap login
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

```powershell
flutter test test\features\auth\presentation\login_screen_test.dart
```

Expected: FAIL — `LoginScreen` doesn't have the required keys or validation yet.

- [ ] **Step 4: Implement LoginScreen**

Replace `lib/features/auth/presentation/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  FirebaseAuth get _auth => widget._auth ?? FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'network-request-failed':
        return 'Check your connection and try again';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(
                    PhosphorIcons.shieldCheck,
                    size: 64,
                    color: AppColors.accentBrand,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'She-Secure',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    key: const Key('login-email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(PhosphorIcons.envelope),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    key: const Key('login-password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(PhosphorIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? PhosphorIcons.eye
                              : PhosphorIcons.eyeSlash,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.accentAlert,
                        ),
                      ),
                    ),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.accentBrand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signup),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign up',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.accentBrand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
flutter test test\features\auth\presentation\login_screen_test.dart
```

Expected: 2/2 PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib\features\auth\presentation\login_screen.dart test\features\auth\; if ($?) { git commit -m "feat(auth): add login form with Firebase Auth and validation" }
```

---

### Task 5: Signup screen — form + Firebase Auth + tests

**Files:**
- Modify: `lib/features/auth/presentation/signup_screen.dart`
- Create: `test/features/auth/presentation/signup_screen_test.dart`

**Interfaces:**
- Consumes: `FirebaseAuth` (for create user), `FirebaseFirestore` (for user doc)
- Produces: navigates to `/home` on success, shows error messages on failure

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/presentation/signup_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:she_secure/core/router/routes.dart';
import 'package:she_secure/features/auth/presentation/signup_screen.dart';

void main() {
  group('SignupScreen validation', () {
    testWidgets('shows error for empty name', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.signup,
        routes: [
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const SignupScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('shows error for password mismatch', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.signup,
        routes: [
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const SignupScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('signup-name')), 'Test User');
      await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('signup-password')), 'password123');
      await tester.enterText(find.byKey(const Key('signup-confirm-password')), 'different123');

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.signup,
        routes: [
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const SignupScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('signup-name')), 'Test User');
      await tester.enterText(find.byKey(const Key('signup-email')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('signup-password')), '123');
      await tester.enterText(find.byKey(const Key('signup-confirm-password')), '123');

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test\features\auth\presentation\signup_screen_test.dart
```

Expected: FAIL — `SignupScreen` doesn't have the required keys or validation yet.

- [ ] **Step 3: Implement SignupScreen**

Replace `lib/features/auth/presentation/signup_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  FirebaseAuth get _auth => widget._auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget._firestore ?? FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Create user document
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text.trim()
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Signup failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 8 characters';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'network-request-failed':
        return 'Check your connection and try again';
      default:
        return 'Signup failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.shieldCheck,
                    size: 64,
                    color: AppColors.accentBrand,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name
                  TextFormField(
                    key: const Key('signup-name'),
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(PhosphorIcons.user),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    key: const Key('signup-email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(PhosphorIcons.envelope),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    key: const Key('signup-password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(PhosphorIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? PhosphorIcons.eye
                              : PhosphorIcons.eyeSlash,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    key: const Key('signup-confirm-password'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(PhosphorIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? PhosphorIcons.eye
                              : PhosphorIcons.eyeSlash,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 16),

                  // Age (optional)
                  TextFormField(
                    key: const Key('signup-age'),
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Age (optional)',
                      prefixIcon: Icon(PhosphorIcons.calendar),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location (optional)
                  TextFormField(
                    key: const Key('signup-location'),
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      prefixIcon: Icon(PhosphorIcons.mapPin),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.accentAlert,
                        ),
                      ),
                    ),

                  // Signup button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Log in',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.accentBrand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test\features\auth\presentation\signup_screen_test.dart
```

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib\features\auth\presentation\signup_screen.dart test\features\auth\; if ($?) { git commit -m "feat(auth): add signup form with Firebase Auth and validation" }
```

---

### Task 6: Profile screen — view-only + logout

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart`

**Interfaces:**
- Consumes: `FirebaseAuth` (for current user sign-out), `FirebaseFirestore` (for user data)
- Produces: displays user profile, logs out on tap

- [ ] **Step 1: Implement ProfileScreen**

Replace `lib/features/profile/presentation/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.bgElevated2,
                  child: Icon(
                    PhosphorIcons.user,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              _ProfileField(
                label: 'Name',
                value: data?['name'] as String? ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Email
              _ProfileField(
                label: 'Email',
                value: user?.email ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Age
              _ProfileField(
                label: 'Age',
                value: (data?['age'] as int?)?.toString() ?? 'Not set',
              ),
              const SizedBox(height: 16),

              // Location
              _ProfileField(
                label: 'Location',
                value: data?['location'] as String? ?? 'Not set',
              ),
              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showModalBottomSheet<bool>(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Log out?',
                              style: GoogleFonts.sora(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll need to log in again to use She-Secure.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentAlert,
                                    ),
                                    child: const Text('Log out'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await FirebaseAuth.instance.signOut();
                      context.go(AppRoutes.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentAlert),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Log out',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentAlert,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

```powershell
dart analyze lib\features\profile\
```

Expected: no errors.

- [ ] **Step 3: Commit**

```powershell
git add lib\features\profile\; if ($?) { git commit -m "feat(profile): add view-only profile screen with logout" }
```

---

### Task 7: End-to-end verification

**Files:**
- No new files — verification only

- [ ] **Step 1: Run all tests**

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

```powershell
flutter analyze
```

Expected: no errors.

- [ ] **Step 3: Verify app builds**

```powershell
flutter build apk --debug
```

Expected: build succeeds.

- [ ] **Step 4: Final commit (if any fixes needed)**

```powershell
git add -A; if ($?) { git commit -m "chore: Phase 1 auth & onboarding complete" }
```
