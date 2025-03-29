import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final String creatorId;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.creatorId,
    required this.createdAt,
  });

  // Create a Group from Firestore document
  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Group to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'memberIds': memberIds,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of the Group with some changes
  Group copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    String? creatorId,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
