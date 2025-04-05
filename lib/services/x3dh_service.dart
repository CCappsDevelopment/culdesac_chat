import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';
import 'key_service.dart';

/// Bundle of public keys needed to establish a session
class PublicPreKeyBundle {
  final Uint8List identityKey;
  final Uint8List signedPreKey;
  final Uint8List? oneTimePreKey;
  final String deviceId;

  const PublicPreKeyBundle({
    required this.identityKey,
    required this.signedPreKey,
    required this.deviceId,
    this.oneTimePreKey,
  });

  Map<String, dynamic> toJson() => {
    'identityKey': identityKey.toList(),
    'signedPreKey': signedPreKey.toList(),
    'oneTimePreKey': oneTimePreKey?.toList(),
    'deviceId': deviceId,
  };

  factory PublicPreKeyBundle.fromJson(Map<String, dynamic> json) {
    return PublicPreKeyBundle(
      identityKey: Uint8List.fromList(List<int>.from(json['identityKey'])),
      signedPreKey: Uint8List.fromList(List<int>.from(json['signedPreKey'])),
      oneTimePreKey: json['oneTimePreKey'] != null 
          ? Uint8List.fromList(List<int>.from(json['oneTimePreKey']))
          : null,
      deviceId: json['deviceId'] as String,
    );
  }
}

/// Result of X3DH key agreement
class X3DHResult {
  final Uint8List sharedSecret;
  final Uint8List associatedData;
  final SimplePublicKey ephemeralKey;
  final Uint8List? usedOneTimePreKey; // Store the used one-time pre-key bytes
  
  const X3DHResult({
    required this.sharedSecret,
    required this.associatedData,
    required this.ephemeralKey,
    this.usedOneTimePreKey,
  });
}

/// Implements the X3DH (Extended Triple Diffie-Hellman) key agreement protocol
class X3DHService {
  final KeyService _keyService;
  final X25519 _algorithm;
  final Sha256 _hash;
  final Map<String, SimpleKeyPair> _oneTimePreKeys = {}; // Cache of one-time pre-keys

  X3DHService({KeyService? keyService})
      : _keyService = keyService ?? KeyService(),
        _algorithm = X25519(),
        _hash = Sha256();

  /// Initialize the service
  Future<void> initialize() => _keyService.initialize();

  /// Get this device's public key bundle for sharing
  Future<PublicPreKeyBundle> getPublicBundle() async {
    final identityKey = await _keyService.getIdentityKeyPair();
    final signedPreKey = await _keyService.getSignedPreKey();
    final oneTimePreKey = await _keyService.getOneTimePreKey();
    final deviceId = await _keyService.getLocalDeviceId();

    if (deviceId == null) {
      throw StateError('Device ID not set. Did you call initialize()?');
    }

    final identityPub = await _keyService.getPublicKeyBytes(identityKey);
    final signedPrePub = await _keyService.getPublicKeyBytes(signedPreKey);
    
    Uint8List? oneTimePrePub;
    if (oneTimePreKey != null) {
      oneTimePrePub = await _keyService.getPublicKeyBytes(oneTimePreKey);
      // Cache the one-time pre-key using its public key as identifier
      _oneTimePreKeys[base64.encode(oneTimePrePub)] = oneTimePreKey;
    }

    return PublicPreKeyBundle(
      identityKey: identityPub,
      signedPreKey: signedPrePub,
      oneTimePreKey: oneTimePrePub,
      deviceId: deviceId,
    );
  }

  /// Initiate a new session with a recipient using their public bundle
  Future<X3DHResult> initiateSession(PublicPreKeyBundle recipientBundle) async {
    // Get our identity key and generate ephemeral key
    final identityKey = await _keyService.getIdentityKeyPair();
    final ephemeralKey = await _keyService.generateKeyPair();

    // Convert recipient's public keys
    final recipientIdentityPub = SimplePublicKey(
      recipientBundle.identityKey,
      type: KeyPairType.x25519,
    );
    final recipientSignedPreKey = SimplePublicKey(
      recipientBundle.signedPreKey,
      type: KeyPairType.x25519,
    );
    final recipientOneTimePreKey = recipientBundle.oneTimePreKey != null
        ? SimplePublicKey(
            recipientBundle.oneTimePreKey!,
            type: KeyPairType.x25519,
          )
        : null;

    // Calculate DH outputs in canonical order:
    // DH1 = IKa * SPKb
    final dh1 = await _algorithm.sharedSecretKey(
      keyPair: identityKey,
      remotePublicKey: recipientSignedPreKey,
    );

    // DH2 = EKa * IKb
    final dh2 = await _algorithm.sharedSecretKey(
      keyPair: ephemeralKey,
      remotePublicKey: recipientIdentityPub,
    );

    // DH3 = EKa * SPKb
    final dh3 = await _algorithm.sharedSecretKey(
      keyPair: ephemeralKey,
      remotePublicKey: recipientSignedPreKey,
    );

    // DH4 = EKa * OPKb (optional)
    final dh4 = recipientOneTimePreKey != null
        ? await _algorithm.sharedSecretKey(
            keyPair: ephemeralKey,
            remotePublicKey: recipientOneTimePreKey,
          )
        : null;

    // Combine DH outputs to derive the shared secret in canonical order
    final secretInputs = [
      await dh1.extractBytes(),
      await dh2.extractBytes(),
      await dh3.extractBytes(),
      if (dh4 != null) await dh4.extractBytes(),
    ];

    final combinedSecret = await _hash.hash(
      secretInputs.expand((x) => x).toList(),
    );

    // Get our public keys for the associated data
    final identityPub = await _keyService.getPublicKeyBytes(identityKey);
    final ephemeralPub = await _keyService.getPublicKeyBytes(ephemeralKey);

    // Combine public keys as associated data in canonical order
    final associatedData = Uint8List.fromList([
      ...identityPub,
      ...ephemeralPub,
      ...recipientBundle.identityKey,
      ...recipientBundle.signedPreKey,
      if (recipientBundle.oneTimePreKey != null)
        ...recipientBundle.oneTimePreKey!,
    ]);

    return X3DHResult(
      sharedSecret: Uint8List.fromList(combinedSecret.bytes),
      associatedData: associatedData,
      ephemeralKey: await ephemeralKey.extractPublicKey(),
      usedOneTimePreKey: recipientBundle.oneTimePreKey,
    );
  }

  /// Accept a session initiation from a sender
  Future<X3DHResult> acceptSession({
    required Uint8List senderIdentityKey,
    required SimplePublicKey senderEphemeralKey,
    required Uint8List usedOneTimePreKey,
  }) async {
    // Get our identity and signed pre-keys
    final identityKey = await _keyService.getIdentityKeyPair();
    final signedPreKey = await _keyService.getSignedPreKey();

    // Look up the cached one-time pre-key
    final oneTimePreKey = _oneTimePreKeys[base64.encode(usedOneTimePreKey)];
    if (oneTimePreKey == null) {
      throw StateError('One-time pre-key not found in cache');
    }

    // Convert sender's identity key
    final senderIdentityPub = SimplePublicKey(
      senderIdentityKey,
      type: KeyPairType.x25519,
    );

    // Calculate DH outputs in same canonical order as initiator:
    // DH1 = SPKb * IKa (matching initiator's IKa * SPKb)
    final dh1 = await _algorithm.sharedSecretKey(
      keyPair: signedPreKey,
      remotePublicKey: senderIdentityPub,
    );

    // DH2 = IKb * EKa (matching initiator's EKa * IKb)
    final dh2 = await _algorithm.sharedSecretKey(
      keyPair: identityKey,
      remotePublicKey: senderEphemeralKey,
    );

    // DH3 = SPKb * EKa (matching initiator's EKa * SPKb)
    final dh3 = await _algorithm.sharedSecretKey(
      keyPair: signedPreKey,
      remotePublicKey: senderEphemeralKey,
    );

    // DH4 = OPKb * EKa (matching initiator's EKa * OPKb)
    final dh4 = await _algorithm.sharedSecretKey(
      keyPair: oneTimePreKey,
      remotePublicKey: senderEphemeralKey,
    );

    // Remove the used one-time pre-key from cache
    _oneTimePreKeys.remove(base64.encode(usedOneTimePreKey));

    // Combine DH outputs to derive the shared secret
    final secretInputs = [
      await dh1.extractBytes(), // Same first position as initiator
      await dh2.extractBytes(), // Same second position as initiator
      await dh3.extractBytes(), // Same third position as initiator
      await dh4.extractBytes(), // Same fourth position as initiator
    ];

    final combinedSecret = await _hash.hash(
      secretInputs.expand((x) => x).toList(),
    );

    // Get our public keys for the associated data
    final identityPub = await _keyService.getPublicKeyBytes(identityKey);
    final signedPrePub = await _keyService.getPublicKeyBytes(signedPreKey);
    final oneTimePreKeyPub = await _keyService.getPublicKeyBytes(oneTimePreKey);

    // Combine public keys as associated data in same order as initiator
    final associatedData = Uint8List.fromList([
      ...senderIdentityKey,
      ...senderEphemeralKey.bytes,
      ...identityPub,
      ...signedPrePub,
      ...oneTimePreKeyPub,
    ]);

    return X3DHResult(
      sharedSecret: Uint8List.fromList(combinedSecret.bytes),
      associatedData: associatedData,
      ephemeralKey: senderEphemeralKey,
      usedOneTimePreKey: usedOneTimePreKey,
    );
  }

  /// Clean up resources
  void dispose() {
    _oneTimePreKeys.clear();
    _keyService.dispose();
  }
}