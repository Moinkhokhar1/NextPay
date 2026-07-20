import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import 'sms_crypto_util.dart';

/// Call this once after login and whenever connectivity is restored.
/// It uploads the on-device HMAC key to the backend so the gateway
/// can verify this user's offline SMS payments.
class SmsKeySyncService {
  static bool _synced = false;

  static Future<void> syncIfNeeded() async {
    if (_synced) return;

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((r) => r != ConnectivityResult.none);
    if (!isOnline) return;

    try {
      final secretKey = await SmsCryptoUtil.getOrCreateSecretKey();
      final response = await ApiService.instance.post(
        '/users/sync-sms-key',
        data: {'secretKey': secretKey},
      );
      if (response.data['success'] == true) {
        _synced = true;
      }
    } catch (e) {
      // Silent fail — will retry next time app is online
    }
  }
}