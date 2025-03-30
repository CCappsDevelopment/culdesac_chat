import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class GroupRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache of groups
  List<Group> _userGroups = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Group> get userGroups => _userGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of groups for the current user
  Stream<List<Group>> getUserGroups() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: _auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
          final groups =
              snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList();
          _userGroups = groups; // Update the cache
          return groups;
        });
  }

  // Create a new group
  Future<void> createGroup(String name) async {
    if (_auth.currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if a group with this name already exists for the user
      final existingGroups =
          await _firestore
              .collection('groups')
              .where('name', isEqualTo: name)
              .where('memberIds', arrayContains: _auth.currentUser!.uid)
              .get();

      if (existingGroups.docs.isNotEmpty) {
        _error = 'A group with this name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Create the new group
      final groupData = {
        'name': name,
        'memberIds': [_auth.currentUser!.uid],
        'creatorId': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('groups').add(groupData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create group: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update group name
  Future<void> updateGroupName(String groupId, String newName) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Check if the user has permission to update this group
      final group = await _firestore.collection('groups').doc(groupId).get();
      final groupData = group.data();

      if (groupData == null) {
        _error = 'Group not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check if a different group with this name already exists for the user
      final existingGroups =
          await _firestore
              .collection('groups')
              .where('name', isEqualTo: newName)
              .where('memberIds', arrayContains: _auth.currentUser!.uid)
              .get();

      bool nameConflict = existingGroups.docs.any((doc) => doc.id != groupId);

      if (nameConflict) {
        _error = 'A different group with this name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Update the group name
      await _firestore.collection('groups').doc(groupId).update({
        'name': newName,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update group: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a user to a group
  Future<bool> addUserToGroup(String groupId, String email) async {
    if (_auth.currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Find the user by email
      final userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        _error = 'No user found with this email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = userQuery.docs.first.id;

      // Check if user is already in the group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final group = Group.fromFirestore(groupDoc);

      if (group.memberIds.contains(userId)) {
        _error = 'User is already in this group';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add the user to the group
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add user: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove a user from a group
  Future<void> removeUserFromGroup(String groupId, String userId) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove user: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get group by ID
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return Group.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Failed to fetch group: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Initialize the general group if it doesn't exist yet
  Future<void> initializeGeneralGroup() async {
    if (_auth.currentUser == null) return;

    try {
      final generalGroupRef = _firestore.collection('groups').doc('general');
      final generalGroupDoc = await generalGroupRef.get();

      // If the general group document doesn't exist or doesn't have memberIds field
      if (!generalGroupDoc.exists ||
          generalGroupDoc.data()?['memberIds'] is! List) {
        // Create or update the general group
        await generalGroupRef.set({
          'name': 'General',
          'memberIds': [_auth.currentUser!.uid],
          'creatorId': 'system',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      // If the general group exists but current user is not in it
      else if (!List<String>.from(
        generalGroupDoc.data()!['memberIds'] ?? [],
      ).contains(_auth.currentUser!.uid)) {
        // Add current user to the general group
        await generalGroupRef.update({
          'memberIds': FieldValue.arrayUnion([_auth.currentUser!.uid]),
        });
      }
    } catch (e) {
      _error = 'Failed to initialize general group: ${e.toString()}';
      notifyListeners();
    }
  }

  // Leave a group (remove current user from group)
  Future<void> leaveGroup(String groupId) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([_auth.currentUser!.uid]),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to leave group: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a group entirely (must be the creator)
  Future<bool> deleteGroup(String groupId) async {
    if (_auth.currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      // Get the group to check if current user is the creator
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        _error = 'Group not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final group = Group.fromFirestore(groupDoc);

      // Don't allow deleting the general group
      if (groupId == 'general') {
        _error = 'The general group cannot be deleted';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Only the creator can delete the group
      if (group.creatorId != _auth.currentUser!.uid) {
        _error = 'Only the group creator can delete the group';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Delete all messages in the group
      final batch = _firestore.batch();

      // Get messages subcollection
      final messagesSnapshot =
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .get();

      // Add delete operations to batch
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the group document itself
      batch.delete(_firestore.collection('groups').doc(groupId));

      // Commit the batch
      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete group: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if user has any groups
  Future<bool> hasAnyGroups() async {
    if (_auth.currentUser == null) return false;

    try {
      final snapshot =
          await _firestore
              .collection('groups')
              .where('memberIds', arrayContains: _auth.currentUser!.uid)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _error = 'Failed to check for groups: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
