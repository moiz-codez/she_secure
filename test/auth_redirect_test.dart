import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:she_secure/core/router/routes.dart';

void main() {
  group('Auth-state redirect (Section 8.1)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'hasSeenOnboarding': true,
      });
    });

    testWidgets(
      'Cold-start with signed-in user redirects to Home, never builds Login',
      (tester) async {
        final mockUser = MockUser(uid: 'abc123', email: 'test@test.com');
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final router = GoRouter(
          initialLocation: AppRoutes.splash,
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final hasSeenOnboarding =
                prefs.getBool('hasSeenOnboarding') ?? false;
            final location = state.matchedLocation;
            final user = mockAuth.currentUser;

            if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
              return AppRoutes.onboarding;
            }

            if (hasSeenOnboarding &&
                user == null &&
                location != AppRoutes.login &&
                location != AppRoutes.signup) {
              return AppRoutes.login;
            }

            if (user != null &&
                (location == AppRoutes.login ||
                    location == AppRoutes.signup ||
                    location == AppRoutes.splash)) {
              return AppRoutes.home;
            }

            return null;
          },
          routes: [
            GoRoute(
              path: AppRoutes.splash,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Splash'))),
            ),
            GoRoute(
              path: AppRoutes.onboarding,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Onboarding'))),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Login'))),
            ),
            GoRoute(
              path: AppRoutes.signup,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Signup'))),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Home'))),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Login'), findsNothing);
        expect(find.text('Splash'), findsNothing);
      },
    );

    testWidgets(
      'Cold-start with no user redirects to Login',
      (tester) async {
        final mockAuth = MockFirebaseAuth(signedIn: false);

        final router = GoRouter(
          initialLocation: AppRoutes.splash,
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final hasSeenOnboarding =
                prefs.getBool('hasSeenOnboarding') ?? false;
            final location = state.matchedLocation;
            final user = mockAuth.currentUser;

            if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
              return AppRoutes.onboarding;
            }

            if (hasSeenOnboarding &&
                user == null &&
                location != AppRoutes.login &&
                location != AppRoutes.signup) {
              return AppRoutes.login;
            }

            if (user != null &&
                (location == AppRoutes.login ||
                    location == AppRoutes.signup ||
                    location == AppRoutes.splash)) {
              return AppRoutes.home;
            }

            return null;
          },
          routes: [
            GoRoute(
              path: AppRoutes.splash,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Splash'))),
            ),
            GoRoute(
              path: AppRoutes.onboarding,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Onboarding'))),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Login'))),
            ),
            GoRoute(
              path: AppRoutes.signup,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Signup'))),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Home'))),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Home'), findsNothing);
      },
    );

    testWidgets(
      'First-ever launch redirects to Onboarding regardless of auth state',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'hasSeenOnboarding': false,
        });

        final mockUser = MockUser(uid: 'abc123', email: 'test@test.com');
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final router = GoRouter(
          initialLocation: AppRoutes.splash,
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final hasSeenOnboarding =
                prefs.getBool('hasSeenOnboarding') ?? false;
            final location = state.matchedLocation;
            final user = mockAuth.currentUser;

            if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
              return AppRoutes.onboarding;
            }

            if (hasSeenOnboarding &&
                user == null &&
                location != AppRoutes.login &&
                location != AppRoutes.signup) {
              return AppRoutes.login;
            }

            if (user != null &&
                (location == AppRoutes.login ||
                    location == AppRoutes.signup ||
                    location == AppRoutes.splash)) {
              return AppRoutes.home;
            }

            return null;
          },
          routes: [
            GoRoute(
              path: AppRoutes.splash,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Splash'))),
            ),
            GoRoute(
              path: AppRoutes.onboarding,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Onboarding'))),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Login'))),
            ),
            GoRoute(
              path: AppRoutes.signup,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Signup'))),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Home'))),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('Onboarding'), findsOneWidget);
        expect(find.text('Login'), findsNothing);
        expect(find.text('Home'), findsNothing);
      },
    );
  });
}
