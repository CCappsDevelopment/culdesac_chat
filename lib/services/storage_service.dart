// services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Create a reference to 'profile_images/user_id.jpg'
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');

      // Create metadata with the correct content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );

      // Upload the file with metadata
      await ref.putFile(imageFile, metadata);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImageWeb(Uint8List bytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Create a reference to 'profile_images/user_id.jpg'
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');

      // Create metadata with the correct content type
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload the bytes with metadata
      await ref.putData(bytes, metadata);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Get profile image URL
  Future<String> getProfileImageUrl(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      // Return default image URL if no custom image exists
      return await _storage
          .ref()
          .child('default_images/default_avatar.jpg')
          .getDownloadURL();
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
