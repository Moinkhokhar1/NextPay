import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and manages a per-device Ed25519 key pair used to sign
/// offline transactions.
///
/// The PRIVATE key never leaves the device and is stored only in
/// hardware-backed secure storage (Android Keystore / iOS Keychain
/// via flutter_secure_storage). Only the PUBLIC key is ever sent to
/// the server — at registration time, and again bound to each device
/// if you support multiple devices per user.
///
/// This replaces a shared static secret (which every device knows and
/// which can be extracted from the app binary or debug logs) with a
/// scheme where forging a signature "as" another user is not possible
/// without their private key.
class KeyManagementService {
  KeyManagementService._();
  static final KeyManagementService instance = KeyManagementService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _privateKeyStorageKey = 'device_signing_private_key';
  static const _publicKeyStorageKey = 'device_signing_public_key';

  final _algorithm = Ed25519();
  SimpleKeyPair? _cachedKeyPair;

  /// Call once at app startup (e.g. after login) to ensure a key pair
  /// exists for this device. Idempotent — if a key pair already
  /// exists it is reused, never regenerated silently (regenerating
  /// would invalidate the device's ability to be recognized by the
  /// server without re-registering the new public key).
  Future<SimpleKeyPair> ensureKeyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair!;

    final existingPrivate = await _storage.read(key: _privateKeyStorageKey);
    if (existingPrivate != null) {
      final bytes = base64Decode(existingPrivate);
      final publicBytes = base64Decode(
        (await _storage.read(key: _publicKeyStorageKey))!,
      );
      _cachedKeyPair = SimpleKeyPairData(
        bytes,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      return _cachedKeyPair!;
    }

    final newKeyPair = await _algorithm.newKeyPair();
    final privateBytes = await newKeyPair.extractPrivateKeyBytes();
    final publicKey = await newKeyPair.extractPublicKey();

    await _storage.write(
      key: _privateKeyStorageKey,
      value: base64Encode(privateBytes),
    );
    await _storage.write(
      key: _publicKeyStorageKey,
      value: base64Encode(publicKey.bytes),
    );

    _cachedKeyPair = newKeyPair;
    return newKeyPair;
  }

  /// Returns the base64-encoded public key to register with the
  /// server (POST /auth/device-keys or similar, tied to the
  /// authenticated user + device ID).
  Future<String> getPublicKeyBase64() async {
    final keyPair = await ensureKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// Signs a payload string, returning a base64-encoded signature.
  /// The server verifies this against the device's registered public
  /// key — it never needs, and never receives, the private key.
  Future<String> sign(String payload) async {
    final keyPair = await ensureKeyPair();
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  /// Local-only verification helper (useful for tests / sanity checks).
  /// The authoritative verification must always happen server-side.
  Future<bool> verify(String payload, String signatureBase64) async {
    final keyPair = await ensureKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final signature = Signature(
      base64Decode(signatureBase64),
      publicKey: publicKey,
    );
    return _algorithm.verify(utf8.encode(payload), signature: signature);
  }
}