import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:culdesac_chat/services/secure_storage_service.dart';

class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map<String, String>.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService secureStorage;
  late X25519 algorithm;

  setUp(() {
    secureStorage = SecureStorageService.withStorage(MockSecureStorage());
    algorithm = X25519();
  });

  group('SecureStorageService', () {
    test('stores and retrieves identity key pair', () async {
      final keyPair = await algorithm.newKeyPair();
      await secureStorage.storeIdentityKeyPair(keyPair);

      final retrieved = await secureStorage.getIdentityKeyPair();
      expect(retrieved, isNotNull);

      final originalPub = await keyPair.extractPublicKey();
      final retrievedPub = await retrieved!.extractPublicKey();

      expect(retrievedPub.bytes, equals(originalPub.bytes));
    });

    test('stores and retrieves signed pre-key pair', () async {
      final keyPair = await algorithm.newKeyPair();
      await secureStorage.storeSignedPreKeyPair(keyPair);

      final retrieved = await secureStorage.getSignedPreKeyPair();
      expect(retrieved, isNotNull);

      final originalPub = await keyPair.extractPublicKey();
      final retrievedPub = await retrieved!.extractPublicKey();

      expect(retrievedPub.bytes, equals(originalPub.bytes));
    });

    test('stores and retrieves multiple one-time pre-keys', () async {
      final preKeys = await Future.wait(
        List.generate(5, (_) => algorithm.newKeyPair()),
      );

      await secureStorage.storeOneTimePreKeys(preKeys);
      final retrieved = await secureStorage.getOneTimePreKeys();

      expect(retrieved.length, equals(preKeys.length));

      for (var i = 0; i < preKeys.length; i++) {
        final originalPub = await preKeys[i].extractPublicKey();
        final retrievedPub = await retrieved[i].extractPublicKey();

        expect(retrievedPub.bytes, equals(originalPub.bytes));
      }
    });

    test('stores and retrieves device ID', () async {
      const deviceId = 'test-device-123';
      await secureStorage.storeLocalDeviceId(deviceId);

      final retrieved = await secureStorage.getLocalDeviceId();
      expect(retrieved, equals(deviceId));
    });

    test('clears all stored keys', () async {
      // Store some test data
      final keyPair = await algorithm.newKeyPair();
      await secureStorage.storeIdentityKeyPair(keyPair);
      await secureStorage.storeLocalDeviceId('test-device');

      // Clear everything
      await secureStorage.clearAllKeys();

      // Verify everything is cleared
      expect(await secureStorage.getIdentityKeyPair(), isNull);
      expect(await secureStorage.getLocalDeviceId(), isNull);
    });

    test('checks key existence correctly', () async {
      const testKey = 'test_key';
      final keyMaterial = List<int>.generate(32, (i) => i);

      // Initially key should not exist
      expect(await secureStorage.hasKey(testKey), isFalse);

      // Store key and verify it exists
      await secureStorage.storeKeyMaterial(testKey, keyMaterial);
      expect(await secureStorage.hasKey(testKey), isTrue);

      // Clear and verify it no longer exists
      await secureStorage.clearAllKeys();
      expect(await secureStorage.hasKey(testKey), isFalse);
    });
  });
}
