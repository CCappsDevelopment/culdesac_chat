import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Handles secure storage of cryptographic keys and sensitive data
/// using platform-specific encryption capabilities.
class SecureStorageService {
  static const String _identityKeyPairKey = 'identity_key_pair';
  static const String _signedPreKeyPairKey = 'signed_prekey_pair';
  static const String _oneTimePreKeysKey = 'onetime_prekeys';
  static const String _localDeviceIdKey = 'local_device_id';

  final FlutterSecureStorage _storage;
  final X25519 _algorithm;

  /// Default constructor that uses the platform's secure storage
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        wOptions: WindowsOptions(),
        lOptions: LinuxOptions(),
        mOptions: MacOsOptions(),
      ),
      _algorithm = X25519();

  /// Test constructor that allows injection of a mock storage
  @visibleForTesting
  SecureStorageService.withStorage(FlutterSecureStorage storage)
    : _storage = storage,
      _algorithm = X25519();

  /// Stores key material securely
  Future<void> storeKeyMaterial(String key, List<int> keyMaterial) async {
    final encoded = base64.encode(keyMaterial);
    await _storage.write(key: key, value: encoded);
  }

  /// Retrieves key material
  Future<List<int>?> getKeyMaterial(String key) async {
    final encoded = await _storage.read(key: key);
    if (encoded == null) return null;
    return base64.decode(encoded);
  }

  /// Stores the identity key pair
  Future<void> storeIdentityKeyPair(SimpleKeyPair keyPair) async {
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await storeKeyMaterial(_identityKeyPairKey + '_private', privateKeyData);
    await storeKeyMaterial(_identityKeyPairKey + '_public', publicKey.bytes);
  }

  /// Retrieves the identity key pair
  Future<SimpleKeyPair?> getIdentityKeyPair() async {
    final privateKeyBytes = await getKeyMaterial(
      _identityKeyPairKey + '_private',
    );
    if (privateKeyBytes == null) return null;

    return await _algorithm.newKeyPairFromSeed(
      Uint8List.fromList(privateKeyBytes),
    );
  }

  /// Stores a signed pre-key pair
  Future<void> storeSignedPreKeyPair(SimpleKeyPair keyPair) async {
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await storeKeyMaterial(_signedPreKeyPairKey + '_private', privateKeyData);
    await storeKeyMaterial(_signedPreKeyPairKey + '_public', publicKey.bytes);
  }

  /// Retrieves the signed pre-key pair
  Future<SimpleKeyPair?> getSignedPreKeyPair() async {
    final privateKeyBytes = await getKeyMaterial(
      _signedPreKeyPairKey + '_private',
    );
    if (privateKeyBytes == null) return null;

    return await _algorithm.newKeyPairFromSeed(
      Uint8List.fromList(privateKeyBytes),
    );
  }

  /// Stores a batch of one-time pre-keys
  Future<void> storeOneTimePreKeys(List<SimpleKeyPair> preKeys) async {
    final List<Map<String, String>> serializedKeys = [];

    for (var key in preKeys) {
      final privateKeyData = await key.extractPrivateKeyBytes();
      final publicKey = await key.extractPublicKey();

      serializedKeys.add({
        'private': base64.encode(privateKeyData),
        'public': base64.encode(publicKey.bytes),
      });
    }

    await _storage.write(
      key: _oneTimePreKeysKey,
      value: jsonEncode(serializedKeys),
    );
  }

  /// Retrieves all one-time pre-keys
  Future<List<SimpleKeyPair>> getOneTimePreKeys() async {
    final encoded = await _storage.read(key: _oneTimePreKeysKey);
    if (encoded == null) return [];

    final decoded = jsonDecode(encoded) as List;
    final keys = <SimpleKeyPair>[];

    for (var keyMap in decoded) {
      final Map<String, dynamic> typedMap = keyMap as Map<String, dynamic>;
      final privateKeyData = base64.decode(typedMap['private'] as String);
      keys.add(
        await _algorithm.newKeyPairFromSeed(Uint8List.fromList(privateKeyData)),
      );
    }

    return keys;
  }

  /// Stores the local device ID
  Future<void> storeLocalDeviceId(String deviceId) async {
    await _storage.write(key: _localDeviceIdKey, value: deviceId);
  }

  /// Retrieves the local device ID
  Future<String?> getLocalDeviceId() async {
    return await _storage.read(key: _localDeviceIdKey);
  }

  /// Deletes all stored keys
  Future<void> clearAllKeys() async {
    await _storage.deleteAll();
  }

  /// Checks if a specific key exists
  Future<bool> hasKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  /// Returns all stored keys (for debugging only)
  Future<Map<String, String>> getAllKeys() async {
    return await _storage.readAll();
  }
}
