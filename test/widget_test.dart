import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:she_secure/features/auth/presentation/login_screen.dart';
import 'package:she_secure/features/onboarding/presentation/onboarding_screen.dart';

Widget _wrapWithRouter(Widget child, {String initialLocation = '/onboarding'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Signup'))),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('Onboarding tests', () {
    testWidgets('Onboarding shows first page', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(_wrapWithRouter(const OnboardingScreen()));

      expect(find.text('Welcome to SheSecure'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Onboarding navigates to next page', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(_wrapWithRouter(const OnboardingScreen()));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency SOS'), findsOneWidget);
    });

    testWidgets('Skip button completes onboarding', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_wrapWithRouter(const OnboardingScreen()));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('hasSeenOnboarding'), true);
    });
  });

  group('Login tests', () {
    testWidgets('Login shows email and password fields', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _wrapWithRouter(
          const LoginScreen(),
          initialLocation: '/login',
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login validates empty fields', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _wrapWithRouter(
          const LoginScreen(),
          initialLocation: '/login',
        ),
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Login validates email format', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _wrapWithRouter(
          const LoginScreen(),
          initialLocation: '/login',
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Login validates password length', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _wrapWithRouter(
          const LoginScreen(),
          initialLocation: '/login',
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Minimum 6 characters'), findsOneWidget);
    });
  });
}