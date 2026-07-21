import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? location;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.location,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      location: data['location'],
    );
  }
}

class SosEvent {
  final String id;
  final DateTime timestamp;
  final GeoPoint? location;
  final double? accuracy;
  final List<String> channelsAttempted;
  final List<String> contactsNotified;
  final String status;
  final String? recordingId;

  const SosEvent({
    required this.id,
    required this.timestamp,
    this.location,
    this.accuracy,
    this.channelsAttempted = const [],
    this.contactsNotified = const [],
    required this.status,
    this.recordingId,
  });

  factory SosEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosEvent(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'],
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      channelsAttempted: List<String>.from(data['channelsAttempted'] ?? []),
      contactsNotified: List<String>.from(data['contactsNotified'] ?? []),
      status: data['status'] ?? 'unknown',
      recordingId: data['recordingId'],
    );
  }
}

class HomeRepository {
  final String uid;
  final FirebaseFirestore _firestore;

  HomeRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference get _userRef => _firestore.collection('users').doc(uid);

  CollectionReference get _sosEventsRef => _userRef.collection('sosEvents');

  Stream<UserProfile?> watchUserProfile() {
    return _userRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Stream<List<SosEvent>> watchRecentSosEvents({int limit = 3}) {
    return _sosEventsRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosEvent.fromFirestore(doc))
            .toList());
  }
}
