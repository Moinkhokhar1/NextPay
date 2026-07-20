import 'dart:convert';
import '../models/transaction.dart';
import '../models/wallet_transaction.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/contact_cache_service.dart';
import '../services/storage_service.dart';

/// Loads wallet transactions from the API, local cache, and pending offline queue.
class OfflineTxService {
  OfflineTxService._();

  static String? resolveUserId(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return null;
    final walletUserId = user.wallet?.extra['user_id'];
    if (walletUserId != null) return walletUserId.toString();
    final userIdExtra = user.extra['user_id'];
    if (userIdExtra != null) return userIdExtra.toString();
    return user.id;
  }

  static WalletTransaction fromOfflineTx(
    OfflineTransaction ot, {
    String senderName = 'Unknown',
    String receiverName = 'Unknown',
    String note = '',
  }) {
    return WalletTransaction(
      id: ot.txId,
      senderId: ot.sender,
      receiverId: ot.receiver,
      senderName: senderName,
      receiverName: receiverName,
      amount: ot.amount,
      isOffline: true,
      status: ot.status.isNotEmpty ? ot.status : 'Pending',
      extra: {
        'created_at':
            DateTime.fromMillisecondsSinceEpoch(ot.timestamp).toUtc().toIso8601String(),
        'nonce': ot.nonce,
        if (note.isNotEmpty) 'note': note,
      },
    );
  }

  static Future<List<WalletTransaction>> _pendingForUser(String userId) async {
    final raw = await StorageService.getItem('pending_transactions_$userId');
    if (raw == null) return [];

    final List<dynamic> list = jsonDecode(raw);
    final cache = ContactCacheService.instance;
    final result = <WalletTransaction>[];

    for (final item in list) {
      final ot = OfflineTransaction.fromJson(Map<String, dynamic>.from(item));
      final senderCached = await cache.get(ot.sender);
      final receiverCached = await cache.get(ot.receiver);
      result.add(fromOfflineTx(
        ot,
        senderName: senderCached?['name'] ?? 'Unknown',
        receiverName: receiverCached?['name'] ?? 'Unknown',
      ));
    }
    return result;
  }

  static Future<List<WalletTransaction>> loadAll(AuthProvider auth) async {
    final merged = <String, WalletTransaction>{};

    try {
      final response = await ApiService.instance.get('/wallet/transactions');
      final List<dynamic> data = response.data;
      await StorageService.setItem('cached_transactions', jsonEncode(data));
      for (final item in data) {
        final tx = WalletTransaction.fromJson(Map<String, dynamic>.from(item));
        merged[tx.id] = tx;
      }
    } catch (_) {
      final cached = await StorageService.getItem('cached_transactions');
      if (cached != null) {
        final List<dynamic> data = jsonDecode(cached);
        for (final item in data) {
          final tx =
              WalletTransaction.fromJson(Map<String, dynamic>.from(item));
          merged[tx.id] = tx;
        }
      }
    }

    final userId = resolveUserId(auth);
    if (userId != null) {
      for (final tx in await _pendingForUser(userId)) {
        merged[tx.id] = tx;
      }
    }

    final list = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<List<WalletTransaction>> loadForContact(
    AuthProvider auth,
    String contactId,
  ) async {
    final all = await loadAll(auth);
    return all
        .where((tx) => tx.senderId == contactId || tx.receiverId == contactId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
