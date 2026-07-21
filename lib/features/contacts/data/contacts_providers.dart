import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contacts_repository.dart';
import 'trusted_contact.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('No authenticated user');
  return ContactsRepository(uid: user.uid);
});

final contactsStreamProvider = StreamProvider<List<TrustedContact>>((ref) {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.watchContacts();
});

final hasValidContactProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.hasValidContact();
});
