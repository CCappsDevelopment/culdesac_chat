import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart';
import 'chat_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
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
