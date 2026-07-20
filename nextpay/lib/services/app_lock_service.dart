import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  final _storage = const FlutterSecureStorage();
  final _bio = LocalAuthentication();

  static const _kPinKey = 'app_lock_pin_hash';
  static const _kBioEnabledKey = 'app_lock_bio_enabled';

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<bool> isPinSet() async => (await _storage.read(key: _kPinKey)) != null;

  Future<void> setPin(String pin) async {
    await _storage.write(key: _kPinKey, value: _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> clearLock() async {
    await _storage.delete(key: _kPinKey);
    await _storage.delete(key: _kBioEnabledKey);
  }

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBioEnabledKey)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBioEnabledKey, value: enabled.toString());
  }

  Future<bool> canUseBiometrics() async {
    final supported = await _bio.isDeviceSupported();
    final canCheck = await _bio.canCheckBiometrics;
    return supported && canCheck;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _bio.authenticate(
        localizedReason: 'Unlock to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}