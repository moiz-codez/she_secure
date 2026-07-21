import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:she_secure/features/contacts/data/contacts_repository.dart';
import 'package:she_secure/features/contacts/data/trusted_contact.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ContactsRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ContactsRepository(uid: 'test-uid', firestore: fakeFirestore);
  });

  group('ContactsRepository', () {
    test('addContact adds a contact to Firestore', () async {
      final contact = TrustedContact(
        id: '',
        name: 'Test Contact',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 1,
        createdAt: DateTime.now(),
      );

      await repo.addContact(contact);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'Test Contact');
      expect(snapshot.docs.first.data()['phone'], '+923001234567');
    });

    test('addContact throws ContactsLimitException when at max', () async {
      // Add 5 contacts
      for (var i = 0; i < 5; i++) {
        final contact = TrustedContact(
          id: '',
          name: 'Contact $i',
          phone: '+92300123456$i',
          notifyVia: ['sms'],
          priority: i + 1,
          createdAt: DateTime.now(),
        );
        await repo.addContact(contact);
      }

      // Try to add a 6th
      final sixth = TrustedContact(
        id: '',
        name: 'Contact 6',
        phone: '+923001234566',
        notifyVia: ['sms'],
        priority: 6,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.addContact(sixth),
        throwsA(isA<ContactsLimitException>()),
      );
    });

    test('addContact throws DuplicatePhoneException for duplicate phone', () async {
      final first = TrustedContact(
        id: '',
        name: 'First Contact',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 1,
        createdAt: DateTime.now(),
      );
      await repo.addContact(first);

      final duplicate = TrustedContact(
        id: '',
        name: 'Duplicate Contact',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 2,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.addContact(duplicate),
        throwsA(isA<DuplicatePhoneException>()),
      );
    });

    test('updateContact updates an existing contact', () async {
      final contact = TrustedContact(
        id: '',
        name: 'Original Name',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 1,
        createdAt: DateTime.now(),
      );
      await repo.addContact(contact);

      // Get the ID of the added contact
      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .get();
      final docId = snapshot.docs.first.id;

      final updated = contact.copyWith(
        id: docId,
        name: 'Updated Name',
      );

      await repo.updateContact(updated);

      final updatedSnapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .doc(docId)
          .get();

      expect(updatedSnapshot.data()!['name'], 'Updated Name');
    });

    test('deleteContact removes a contact', () async {
      final contact = TrustedContact(
        id: '',
        name: 'To Delete',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 1,
        createdAt: DateTime.now(),
      );
      await repo.addContact(contact);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .get();
      final docId = snapshot.docs.first.id;

      await repo.deleteContact(docId);

      final deletedSnapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .doc(docId)
          .get();

      expect(deletedSnapshot.exists, false);
    });

    test('reorderContacts updates priority for all contacts', () async {
      // Add 3 contacts
      for (var i = 0; i < 3; i++) {
        final contact = TrustedContact(
          id: '',
          name: 'Contact $i',
          phone: '+92300123456$i',
          notifyVia: ['sms'],
          priority: i + 1,
          createdAt: DateTime.now(),
        );
        await repo.addContact(contact);
      }

      // Get all contact IDs
      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .get();
      final ids = snapshot.docs.map((d) => d.id).toList();

      // Reverse the order
      await repo.reorderContacts(ids.reversed.toList());

      // Verify new order
      final reorderedSnapshot = await fakeFirestore
          .collection('users')
          .doc('test-uid')
          .collection('trustedContacts')
          .orderBy('priority')
          .get();

      expect(reorderedSnapshot.docs.first.data()['name'], 'Contact 2');
      expect(reorderedSnapshot.docs.last.data()['name'], 'Contact 0');
    });

    test('hasValidContact returns true when contact has enabled channel', () async {
      final contact = TrustedContact(
        id: '',
        name: 'Contact',
        phone: '+923001234567',
        notifyVia: ['sms'],
        priority: 1,
        createdAt: DateTime.now(),
      );
      await repo.addContact(contact);

      final result = await repo.hasValidContact();
      expect(result, true);
    });

    test('hasValidContact returns false when no contacts', () async {
      final result = await repo.hasValidContact();
      expect(result, false);
    });

    test('hasValidContact returns false when no enabled channels', () async {
      final contact = TrustedContact(
        id: '',
        name: 'Contact',
        phone: '+923001234567',
        notifyVia: [],
        priority: 1,
        createdAt: DateTime.now(),
      );
      await repo.addContact(contact);

      final result = await repo.hasValidContact();
      expect(result, false);
    });
  });
}
