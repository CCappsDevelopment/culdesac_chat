import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:culdesac_chat/services/key_service.dart';
import 'package:culdesac_chat/services/secure_storage_service.dart';
import 'package:culdesac_chat/services/x3dh_service.dart';

import 'secure_storage_service_test.dart' show MockSecureStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late X3DHService aliceService;
  late X3DHService bobService;
  late SecureStorageService aliceStorage;
  late SecureStorageService bobStorage;
  late KeyService aliceKeys;
  late KeyService bobKeys;

  setUp(() async {
    // Set up Alice's services
    aliceStorage = SecureStorageService.withStorage(MockSecureStorage());
    aliceKeys = KeyService(storage: aliceStorage);
    aliceService = X3DHService(keyService: aliceKeys);

    // Set up Bob's services
    bobStorage = SecureStorageService.withStorage(MockSecureStorage());
    bobKeys = KeyService(storage: bobStorage);
    bobService = X3DHService(keyService: bobKeys);

    // Set device IDs
    await aliceKeys.setLocalDeviceId('alice-device-1');
    await bobKeys.setLocalDeviceId('bob-device-1');

    // Initialize both services
    await aliceService.initialize();
    await bobService.initialize();
  });

  tearDown(() {
    aliceService.dispose();
    bobService.dispose();
  });

  group('X3DHService', () {
    test('initializes with required keys', () async {
      final bundle = await aliceService.getPublicBundle();
      
      expect(bundle.identityKey, isNotNull);
      expect(bundle.signedPreKey, isNotNull);
      expect(bundle.oneTimePreKey, isNotNull);
      expect(bundle.deviceId, isNotNull);
    });

    test('performs key agreement with one-time pre-key', () async {
      // Bob publishes his bundle which internally caches his one-time pre-key
      final bobBundle = await bobService.getPublicBundle();
      expect(bobBundle.oneTimePreKey, isNotNull);

      // Alice initiates session with Bob
      final aliceResult = await aliceService.initiateSession(bobBundle);
      expect(aliceResult.usedOneTimePreKey, isNotNull);
      
      // Get Alice's identity key for Bob
      final aliceIdentityKey = await aliceKeys.getIdentityKeyPair();
      final aliceIdentityPub = await aliceKeys.getPublicKeyBytes(aliceIdentityKey);

      // Bob accepts session using the same one-time pre-key from his bundle
      final bobResult = await bobService.acceptSession(
        senderIdentityKey: aliceIdentityPub,
        senderEphemeralKey: aliceResult.ephemeralKey,
        usedOneTimePreKey: aliceResult.usedOneTimePreKey!,
      );

      // Verify shared secrets match
      expect(aliceResult.sharedSecret, equals(bobResult.sharedSecret));
      
      // Verify associated data matches (should include all public keys)
      expect(aliceResult.associatedData.length, equals(bobResult.associatedData.length));
      
      // Verify one-time pre-key was used
      expect(aliceResult.usedOneTimePreKey, equals(bobBundle.oneTimePreKey));
    });

    test('handles JSON serialization of pre-key bundle', () async {
      final originalBundle = await aliceService.getPublicBundle();
      
      final json = originalBundle.toJson();
      final restoredBundle = PublicPreKeyBundle.fromJson(json);
      
      expect(restoredBundle.identityKey, equals(originalBundle.identityKey));
      expect(restoredBundle.signedPreKey, equals(originalBundle.signedPreKey));
      expect(restoredBundle.oneTimePreKey, equals(originalBundle.oneTimePreKey));
      expect(restoredBundle.deviceId, equals(originalBundle.deviceId));
    });
  });
}