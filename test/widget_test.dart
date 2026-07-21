import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:she_secure/features/splash/presentation/splash_screen.dart';
import 'package:she_secure/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('SplashScreen displays branding', (tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});

    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Login'))),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Onboarding'))),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('SheSecure'), findsOneWidget);
    expect(find.text('Safety at your fingertips'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
