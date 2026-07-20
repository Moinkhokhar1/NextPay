// lib/services/sync_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'api_service.dart';

class SyncService {
  static const String _secretKey = 'offline-payment-secret';

  // ✅ Must match TransactionEngine & SyncEngine key pattern
  static String _pendingKey(String senderId) => "pending_transactions_$senderId";

  static Future<Map<String, dynamic>> syncPendingTransactions(String senderId) async {
    try {
      final storageKey = _pendingKey(senderId);
      debugPrint("SYNC SERVICE KEY: $storageKey");

      final transactions = await getPendingTransactions(senderId);
      if (transactions.isEmpty) {
        return {'success': false, 'message': 'No pending transactions'};
      }

      final res = await ApiService.instance.post(
        '/sync/transactions',
        data: {'transactions': transactions},
      );

      if (res.data['success'] == true) {
        final results = res.data['results'] as List;

        final syncedIds = results
            .where((r) => r['status'] == 'synced')
            .map((r) => r['txId'] as String)
            .toSet();

        final remaining = transactions
            .where((tx) => !syncedIds.contains(tx['txId']))
            .toList();

        if (remaining.isEmpty) {
          await StorageService.removeItem(storageKey);
          await StorageService.removeItem("local_wallet");
        } else {
          await StorageService.setItem(storageKey, jsonEncode(remaining));
        }

        return {
          'success': true,
          'results': results,
          'syncedCount': syncedIds.length,
          'remainingCount': remaining.length,
        };
      }

      return {'success': false, 'message': res.data['message'] ?? 'Sync failed'};
    } catch (e) {
      debugPrint("SYNC SERVICE ERROR: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getPendingTransactions(String senderId) async {
    final raw = await StorageService.getItem(_pendingKey(senderId));
    if (raw == null) return [];
    return jsonDecode(raw);
  }

  static Future<int> getPendingCount(String senderId) async {
    final txs = await getPendingTransactions(senderId);
    return txs.length;
  }
}