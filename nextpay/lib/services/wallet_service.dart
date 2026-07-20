// lib/services/wallet_service.dart
import 'api_service.dart';

class WalletService {
  // GET /wallet/
  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final res = await ApiService.instance.get('/wallet/');
      return {'success': true, 'wallet': res.data};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  // GET /wallet/transactions
  static Future<Map<String, dynamic>> getTransactions() async {
    try {
      final res = await ApiService.instance.get('/wallet/transactions');
      return {'success': true, 'transactions': res.data as List};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  // POST /wallet/transfer
  // Body: { receiverId, amount }
  // Returns: { success: true, receiverName }
  static Future<Map<String, dynamic>> transfer({
    required String receiverId,
    required double amount,
  }) async {
    try {
      final res = await ApiService.instance.post('/wallet/transfer', data: {
        'receiverId': receiverId,
        'amount': amount,
      });
      if (res.data['success'] == true) {
        return {'success': true, 'receiverName': res.data['receiverName']};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Transfer failed'};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  // GET /wallet/transactions/latest-incoming?after=<ISO timestamp>
  // Pass [after] to only fetch transactions newer than that time (for polling)
  static Future<Map<String, dynamic>> getLatestIncoming({String? after}) async {
    try {
      final res = await ApiService.instance.get(
        '/wallet/transactions/latest-incoming',
        queryParameters: after != null ? {'after': after} : null,
      );
      return {'success': true, 'transactions': res.data['transactions'] as List};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  static String _extractError(dynamic e) {
    try {
      return e.response?.data['message'] ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }
}