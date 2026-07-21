import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('No authenticated user');
  return HomeRepository(uid: user.uid);
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchUserProfile();
});

final recentSosEventsProvider = StreamProvider<List<SosEvent>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchRecentSosEvents();
});
