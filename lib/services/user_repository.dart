import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _currentUserProfile;
  final Map<String, UserProfile> _userProfileCache = {};

  UserProfile? get currentUserProfile => _currentUserProfile;

  // Initialize user profile data
  Future<void> initializeUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await getUserProfile(user.uid);
    }
  }

  // Get user profile from Firestore with caching
  Future<UserProfile?> getUserProfile(String uid) async {
    // Clear cache if this is the current user to ensure we get fresh data
    if (_auth.currentUser?.uid == uid) {
      _userProfileCache.remove(uid);
    }

    // Check cache first
    if (_userProfileCache.containsKey(uid)) {
      // If this is the current user, update the current profile
      if (_auth.currentUser?.uid == uid) {
        _currentUserProfile = _userProfileCache[uid];
        notifyListeners();
      }
      return _userProfileCache[uid];
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final profile = UserProfile.fromMap(doc.data()!, doc.id);

        // Cache the profile
        _userProfileCache[uid] = profile;

        // If this is the current user, update the current profile
        if (_auth.currentUser?.uid == uid) {
          _currentUserProfile = profile;
          notifyListeners();
        }

        return profile;
      } else {
        // If user doesn't exist in Firestore yet, create a new profile
        final User? user = _auth.currentUser;
        if (user != null && user.uid == uid) {
          return await createUserProfile(user);
        }
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  // Create a new user profile in Firestore
  Future<UserProfile?> createUserProfile(User user) async {
    try {
      final newProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newProfile.toMap());

      _currentUserProfile = newProfile;
      _userProfileCache[user.uid] = newProfile;
      notifyListeners();
      return newProfile;
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && _currentUserProfile != null) {
        final updatedData = <String, dynamic>{
          'lastActive': FieldValue.serverTimestamp(),
        };

        if (displayName != null) {
          updatedData['displayName'] = displayName;

          // Update sender name in all messages
          await _updateSenderNameInMessages(user.uid, displayName);
        }

        if (avatarUrl != null) {
          updatedData['avatarUrl'] = avatarUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updatedData);

        // Update both the current profile and the cache
        _currentUserProfile = _currentUserProfile!.copyWith(
          displayName: displayName,
          avatarUrl: avatarUrl,
        );

        _userProfileCache[user.uid] = _currentUserProfile!;

        notifyListeners();
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update sender names in messages
  Future<void> _updateSenderNameInMessages(
    String userId,
    String newName,
  ) async {
    try {
      // Get all message collections in all groups
      final groupsSnapshot = await _firestore.collection('groups').get();

      for (var group in groupsSnapshot.docs) {
        final messagesRef = _firestore.collection(
          'groups/${group.id}/messages',
        );
        final userMessagesSnapshot =
            await messagesRef.where('senderId', isEqualTo: userId).get();

        // Batch update for better performance
        final batch = _firestore.batch();
        var count = 0;

        for (var doc in userMessagesSnapshot.docs) {
          batch.update(doc.reference, {'senderName': newName});
          count++;

          // Firestore batches are limited to 500 operations
          if (count >= 450) {
            await batch.commit();
            count = 0;
          }
        }

        if (count > 0) {
          await batch.commit();
        }
      }
    } catch (e) {
      print('Error updating message sender names: $e');
    }
  }

  // Clear user profile data
  Future<void> clearCurrentUserProfile() async {
    _currentUserProfile = null;
    _userProfileCache.clear();
    notifyListeners();
  }
}
