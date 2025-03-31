import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastActive;
  final int? themeSeedColor; // Added theme seed color property

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.themeSeedColor, // Added theme seed color parameter
    DateTime? createdAt,
    DateTime? lastActive,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now();

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      avatarUrl: data['avatarUrl'],
      themeSeedColor: data['themeSeedColor'], // Added theme seed color from map
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      lastActive:
          data['lastActive'] != null
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
      'themeSeedColor': themeSeedColor, // Added theme seed color to map
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    int? themeSeedColor, // Added theme seed color parameter to copyWith
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themeSeedColor:
          themeSeedColor ?? this.themeSeedColor, // Use updated or current theme
      createdAt: createdAt,
      lastActive: DateTime.now(),
    );
  }
}
