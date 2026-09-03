import 'package:dio/dio.dart';
import '../models/wallet.dart';
import 'api_service.dart';

/// Talks to the server's offline-wallet recharge endpoint. This is what
/// actually moves money server-side (see rechargeOfflineWallet in
/// server/src/controllers/walletController.js) — as opposed to the old
/// client-only "budget" that never touched the server at all.
class OfflineWalletService {
  static Future<Map<String, dynamic>> recharge(num amount) async {
    try {
      final res = await ApiService.instance.post(
        '/wallet/offline-wallet/recharge',
        data: {'amount': amount},
      );

      if (res.data['success'] == true) {
        final wallet = Wallet.fromJson(
          Map<String, dynamic>.from(res.data['wallet']),
        );
        return {'success': true, 'wallet': wallet};
      }

      return {
        'success': false,
        'message': res.data['message'] ?? 'Recharge failed',
      };
    } on DioException catch (e) {
      // Server returns a proper message on 400s (e.g. insufficient
      // balance) — surface that instead of a generic network error.
      final serverMessage = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      return {
        'success': false,
        'message': serverMessage ?? 'Recharge failed. Check your connection.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}