import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:culdesac_chat/services/secure_storage_service.dart';
import 'package:culdesac_chat/services/key_service.dart';

import 'secure_storage_service_test.dart' show MockSecureStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyService keyService;
  late SecureStorageService secureStorage;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    secureStorage = SecureStorageService.withStorage(mockStorage);
    keyService = KeyService(storage: secureStorage);
  });

  tearDown(() {
    keyService.dispose();
  });

  group('KeyService', () {
    test('initializes with identity key pair', () async {
      await keyService.initialize();
      final identityKeyPair = await keyService.getIdentityKeyPair();
      expect(identityKeyPair, isNotNull);
    });

    test('initializes with signed pre-key', () async {
      await keyService.initialize();
      final signedPreKey = await keyService.getSignedPreKey();
      expect(signedPreKey, isNotNull);
    });

    test('initializes with one-time pre-keys', () async {
      await keyService.initialize();
      final preKey = await keyService.getOneTimePreKey();
      expect(preKey, isNotNull);
    });

    test('maintains minimum one-time pre-keys', () async {
      await keyService.initialize();

      // Get multiple pre-keys to trigger replenishment
      for (var i = 0; i < 25; i++) {
        final preKey = await keyService.getOneTimePreKey();
        expect(preKey, isNotNull);
      }

      // Verify we still have keys available
      final remainingKeys = await secureStorage.getOneTimePreKeys();
      expect(remainingKeys.length, greaterThanOrEqualTo(20));
    });

    test('rotates signed pre-key', () async {
      await keyService.initialize();
      final originalPreKey = await keyService.getSignedPreKey();

      // Manually trigger rotation
      await keyService.rotateSignedPreKey();

      final newPreKey = await keyService.getSignedPreKey();
      final originalPub = await originalPreKey.extractPublicKey();
      final newPub = await newPreKey.extractPublicKey();

      expect(newPub.bytes, isNot(equals(originalPub.bytes)));
    });

    test('generates key pair bytes correctly', () async {
      await keyService.initialize();
      final keyPair = await keyService.generateKeyPair();
      final publicKeyBytes = await keyService.getPublicKeyBytes(keyPair);

      expect(publicKeyBytes, isNotNull);
      expect(publicKeyBytes.length, equals(32)); // X25519 public key size
    });

    test('preserves keys across reinitializations', () async {
      await keyService.initialize();
      final originalIdentityKey = await keyService.getIdentityKeyPair();
      final originalPreKey = await keyService.getSignedPreKey();

      // Create new service instance
      keyService.dispose();
      final newKeyService = KeyService(storage: secureStorage);
      await newKeyService.initialize();

      final restoredIdentityKey = await newKeyService.getIdentityKeyPair();
      final restoredPreKey = await newKeyService.getSignedPreKey();

      final originalIdPub = await originalIdentityKey.extractPublicKey();
      final restoredIdPub = await restoredIdentityKey.extractPublicKey();
      expect(restoredIdPub.bytes, equals(originalIdPub.bytes));

      final originalPrePub = await originalPreKey.extractPublicKey();
      final restoredPrePub = await restoredPreKey.extractPublicKey();
      expect(restoredPrePub.bytes, equals(originalPrePub.bytes));

      newKeyService.dispose();
    });

    test('throws when accessing keys before initialization', () async {
      expect(() => keyService.getIdentityKeyPair(), throwsStateError);
      expect(() => keyService.getSignedPreKey(), throwsStateError);
    });
  });
}
