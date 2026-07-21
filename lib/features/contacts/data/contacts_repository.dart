import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_contact.dart';

class ContactsRepository {
  final String uid;
  final FirebaseFirestore _firestore;

  static const int maxContacts = 5;

  ContactsRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _contactsRef =>
      _firestore.collection('users').doc(uid).collection('trustedContacts');

  Stream<List<TrustedContact>> watchContacts() {
    return _contactsRef
        .orderBy('priority')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrustedContact.fromFirestore(doc))
            .toList());
  }

  Future<void> addContact(TrustedContact contact) async {
    final snapshot = await _contactsRef.get();
    if (snapshot.docs.length >= maxContacts) {
      throw ContactsLimitException(maxContacts);
    }

    final duplicate = await _contactsRef
        .where('phone', isEqualTo: contact.phone)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw DuplicatePhoneException(contact.phone);
    }

    await _contactsRef.add(contact.toFirestore());
  }

  Future<void> updateContact(TrustedContact contact) async {
    final existing = await _contactsRef.doc(contact.id).get();
    if (!existing.exists) {
      throw ContactNotFoundException(contact.id);
    }

    if (contact.phone != (existing.data() as Map<String, dynamic>)['phone']) {
      final duplicate = await _contactsRef
          .where('phone', isEqualTo: contact.phone)
          .get();
      if (duplicate.docs.isNotEmpty) {
        throw DuplicatePhoneException(contact.phone);
      }
    }

    await _contactsRef.doc(contact.id).update(contact.toFirestore());
  }

  Future<void> deleteContact(String contactId) async {
    await _contactsRef.doc(contactId).delete();
  }

  Future<void> reorderContacts(List<String> orderedIds) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(_contactsRef.doc(orderedIds[i]), {'priority': i + 1});
    }
    await batch.commit();
  }

  Future<bool> hasValidContact() async {
    final snapshot = await _contactsRef.get();
    if (snapshot.docs.isEmpty) return false;

    return snapshot.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final notifyVia = List<String>.from(data['notifyVia'] ?? []);
      return notifyVia.isNotEmpty;
    });
  }
}

class ContactsLimitException implements Exception {
  final int max;
  ContactsLimitException(this.max);
  @override
  String toString() => 'Maximum of $max trusted contacts reached.';
}

class DuplicatePhoneException implements Exception {
  final String phone;
  DuplicatePhoneException(this.phone);
  @override
  String toString() => 'This number is already in your contacts.';
}

class ContactNotFoundException implements Exception {
  final String id;
  ContactNotFoundException(this.id);
  @override
  String toString() => 'Contact not found.';
}
