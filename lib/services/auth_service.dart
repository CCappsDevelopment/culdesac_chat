import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  AuthService({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initialize user data after successful login
      if (credential.user != null) {
        await _userRepository.getUserProfile(credential.user!.uid);
        await _userRepository.ensureUserHasProfileImage();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      return null;
    }
  }

  // Check if email exists
  Future<bool> checkIfEmailExists(String email) async {
    try {
      // Check Firebase Authentication users
      // final methods = await _auth.fetchSignInMethodsForEmail(email);
      // if (methods.isNotEmpty) {
      //   return true;
      // }

      // Also check Firestore users collection
      final userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return userQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Create user in Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name for the user in Firebase Authentication
      await credential.user?.updateDisplayName(displayName);

      // Create user profile in Firestore with the explicit display name
      if (credential.user != null) {
        // Create a user document directly with the provided display name
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName':
              displayName, // Use the display name from the registration form
          'uid': credential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });

        // Ensure the user has a default profile image
        await _userRepository.ensureUserHasProfileImage();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // First clear the user profile
    await _userRepository.clearCurrentUserProfile();
    // Then sign out from Firebase
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
