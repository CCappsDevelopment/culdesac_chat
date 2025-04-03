import 'dart:async';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';
import 'secure_storage_service.dart';

/// Manages cryptographic key generation and lifecycle for E2EE
class KeyService {
  static const int _minOneTimePreKeys = 20;
  static const int _batchGenerateSize = 100;
  static const Duration _preKeyRotationInterval = Duration(days: 7);

  final SecureStorageService _storage;
  final X25519 _algorithm;
  Timer? _rotationTimer;
  bool _isInitialized = false;

  KeyService({SecureStorageService? storage})
    : _storage = storage ?? SecureStorageService(),
      _algorithm = X25519();

  /// Initialize the key service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Ensure we have an identity key pair
    final hasIdentityKey = await _storage.hasKey('identity_key_pair_private');
    if (!hasIdentityKey) {
      final identityKeyPair = await _algorithm.newKeyPair();
      await _storage.storeIdentityKeyPair(identityKeyPair);
    }

    // Generate initial signed pre-key if none exists
    final hasSignedPreKey = await _storage.hasKey('signed_prekey_pair_private');
    if (!hasSignedPreKey) {
      await rotateSignedPreKey();
    }

    // Start pre-key rotation timer
    _rotationTimer = Timer.periodic(_preKeyRotationInterval, (_) async {
      await rotateSignedPreKey();
    });

    // Ensure minimum one-time pre-keys
    await replenishOneTimePreKeys();

    _isInitialized = true;
  }

  /// Get the device's identity key pair
  Future<SimpleKeyPair> getIdentityKeyPair() async {
    final keyPair = await _storage.getIdentityKeyPair();
    if (keyPair == null) {
      throw StateError(
        'Identity key pair not found. Did you call initialize()?',
      );
    }
    return keyPair;
  }

  /// Get the current signed pre-key pair
  Future<SimpleKeyPair> getSignedPreKey() async {
    final keyPair = await _storage.getSignedPreKeyPair();
    if (keyPair == null) {
      throw StateError('Signed pre-key not found. Did you call initialize()?');
    }
    return keyPair;
  }

  /// Rotate the signed pre-key
  @visibleForTesting
  Future<void> rotateSignedPreKey() async {
    final newPreKey = await _algorithm.newKeyPair();
    await _storage.storeSignedPreKeyPair(newPreKey);
  }

  /// Get a one-time pre-key and remove it from storage
  Future<SimpleKeyPair?> getOneTimePreKey() async {
    final keys = await _storage.getOneTimePreKeys();
    if (keys.isEmpty) {
      await replenishOneTimePreKeys();
      return (await _storage.getOneTimePreKeys()).firstOrNull;
    }

    // Store remaining keys
    final remainingKeys = keys.sublist(1);
    await _storage.storeOneTimePreKeys(remainingKeys);

    // Schedule replenishment if running low
    if (remainingKeys.length < _minOneTimePreKeys) {
      // Use microtask to not block the current operation
      scheduleMicrotask(replenishOneTimePreKeys);
    }

    return keys.first;
  }

  /// Generate new one-time pre-keys if running low
  @visibleForTesting
  Future<void> replenishOneTimePreKeys() async {
    final currentKeys = await _storage.getOneTimePreKeys();
    if (currentKeys.length >= _minOneTimePreKeys) return;

    final newKeys = await Future.wait(
      List.generate(
        _batchGenerateSize - currentKeys.length,
        (_) => _algorithm.newKeyPair(),
      ),
    );

    await _storage.storeOneTimePreKeys([...currentKeys, ...newKeys]);
  }

  /// Clean up resources
  void dispose() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _isInitialized = false;
  }

  /// Get public key bytes from a key pair
  Future<Uint8List> getPublicKeyBytes(SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    return Uint8List.fromList(publicKey.bytes);
  }

  /// Generate a random key pair (for testing or one-off use)
  Future<SimpleKeyPair> generateKeyPair() async {
    return await _algorithm.newKeyPair();
  }
}
