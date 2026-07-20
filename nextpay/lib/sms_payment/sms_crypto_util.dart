import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../services/api_service.dart';

/// Handles HMAC signing and verification for SMS payment payloads.
class SmsCryptoUtil {
  static const _secretKeyPref = 'sms_secret_key';

  /// Returns the stored secret key, or generates one on first run.
  static Future<String> getOrCreateSecretKey({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString(_secretKeyPref);
    if (key == null) {
      key = _generateRandomKey(32);
      await prefs.setString(_secretKeyPref, key);

      // ── Sync to backend so gateway can verify HMAC ──────────
      if (userId != null) {
        try {
          await ApiService.instance.post('/users/sms-key', data: {
            'secretKey': key,
          });
        } catch (e) {
          debugPrint('SMS KEY SYNC FAILED: $e');
          // Key is saved locally — will retry next time
        }
      }
    }
    return key;
  }

  /// Generates a cryptographically random hex key.
  static String _generateRandomKey(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Builds and signs the SMS payload.
  /// Format: PAY#senderId#receiverId#amount#timestamp#hmac
  static Future<String> buildPayload({
    required String senderId,
    required String receiverId,
    required double amount,
  }) async {
    final secretKey = await getOrCreateSecretKey(userId: senderId); // ← pass userId
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final amountStr = amount.toStringAsFixed(2);
    final raw = '$senderId:$receiverId:$amountStr:$timestamp';
    final hmac = _sign(raw, secretKey);
    return 'PAY#$senderId#$receiverId#$amountStr#$timestamp#$hmac';
  }

  /// Verifies an incoming payload. Returns parsed fields or null if invalid.
  static Future<Map<String, dynamic>?> verifyPayload(String sms) async {
    try {
      if (!sms.startsWith('PAY#')) return null;
      final parts = sms.split('#');
      if (parts.length != 6) return null;

      final senderId = parts[1];
      final receiverId = parts[2];
      final amount = parts[3];
      final timestamp = int.parse(parts[4]);
      final receivedHmac = parts[5];

      // Reject if older than 120 seconds (replay protection)
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((now - timestamp).abs() > 120) return null;

      final secretKey = await getOrCreateSecretKey();
      final raw = '$senderId:$receiverId:$amount:$timestamp';
      final expectedHmac = _sign(raw, secretKey);
      if (expectedHmac != receivedHmac) return null;

      return {
        'senderId': senderId,
        'receiverId': receiverId,
        'amount': double.parse(amount),
        'timestamp': timestamp,
      };
    } catch (_) {
      return null;
    }
  }

  static String _sign(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(dataBytes).toString().substring(0, 16);
  }
}