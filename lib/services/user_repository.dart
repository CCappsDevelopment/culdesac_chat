import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class UserRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StorageService _storageService = StorageService();
  UserProfile? _currentUserProfile;
  final Map<String, UserProfile> _userProfileCache = {};

  UserProfile? get currentUserProfile => _currentUserProfile;

  // Initialize user profile data
  Future<void> initializeUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await getUserProfile(user.uid);
      await ensureUserHasProfileImage();
    }
  }

  // Get user profile from Firestore with caching
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        UserProfile profile = UserProfile.fromMap(doc.data()!, doc.id);

        // If no avatar URL, try to get from storage
        if (profile.avatarUrl == null || profile.avatarUrl!.isEmpty) {
          final imageUrl = await _storageService.getProfileImageUrl(uid);
          // Update profile with the found image URL
          profile = profile.copyWith(avatarUrl: imageUrl);
          // Update Firestore
          await _firestore.collection('users').doc(uid).update({
            'avatarUrl': imageUrl,
          });
        }

        _userProfileCache[uid] = profile;

        if (_auth.currentUser?.uid == uid) {
          _currentUserProfile = profile;
          notifyListeners();
        }

        return profile;
      } else {
        // Create new profile if doesn't exist
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

  Future<void> updateProfileImageWeb(Uint8List bytes, String fileName) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && _currentUserProfile != null) {
        // Upload image to Firebase Storage
        final imageUrl = await _storageService.uploadProfileImageWeb(bytes);

        if (imageUrl != null) {
          // Update Firestore with the new image URL
          await updateUserProfile(avatarUrl: imageUrl);
        }
      }
    } catch (e) {
      print('Error updating profile image: $e');
      rethrow;
    }
  }

  Future<void> ensureUserHasProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if user already has a profile image
      await _storage
          .ref()
          .child('profile_images/${user.uid}.jpg')
          .getDownloadURL();
    } catch (e) {
      // User doesn't have a profile image, use the default one
      final defaultImageUrl = await _storageService.getProfileImageUrl(
        'default',
      );
      await updateUserProfile(avatarUrl: defaultImageUrl);
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && _currentUserProfile != null) {
        // Upload image to Firebase Storage
        final imageUrl = await _storageService.uploadProfileImage(imageFile);

        if (imageUrl != null) {
          // Update Firestore with the new image URL
          await updateUserProfile(avatarUrl: imageUrl);
        }
      }
    } catch (e) {
      print('Error updating profile image: $e');
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
