import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastActive;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? lastActive,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastActive = lastActive ?? DateTime.now();

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      avatarUrl: data['avatarUrl'],
      createdAt: data['createdAt'] != null 
        ? (data['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
      lastActive: data['lastActive'] != null 
        ? (data['lastActive'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastActive: DateTime.now(),
    );
  }
}
