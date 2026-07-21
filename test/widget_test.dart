import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:she_secure/features/onboarding/presentation/onboarding_screen.dart';

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Login'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
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
}
