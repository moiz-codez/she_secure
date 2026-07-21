import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final String? photoUrl;
  final List<String> notifyVia;
  final int priority;
  final DateTime createdAt;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.photoUrl,
    this.notifyVia = const ['sms'],
    required this.priority,
    required this.createdAt,
  });

  factory TrustedContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrustedContact(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'],
      photoUrl: data['photoUrl'],
      notifyVia: List<String>.from(data['notifyVia'] ?? ['sms']),
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'photoUrl': photoUrl,
      'notifyVia': notifyVia,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  TrustedContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    String? photoUrl,
    List<String>? notifyVia,
    int? priority,
    DateTime? createdAt,
  }) {
    return TrustedContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      photoUrl: photoUrl ?? this.photoUrl,
      notifyVia: notifyVia ?? this.notifyVia,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasEnabledChannel => notifyVia.isNotEmpty;
}
