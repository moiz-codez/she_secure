import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authStateProvider = ChangeNotifierProvider<AuthStateNotifier>(
  (ref) => AuthStateNotifier(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final location = state.matchedLocation;
      final user = authNotifier.user;

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
});
