import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches contact display names and phones keyed by user id so the People
/// row shows real names even when the transactions API omits them.
class ContactCacheService {
  ContactCacheService._();

  static final ContactCacheService instance =
      ContactCacheService._();

  String _key(String ownerUserId) =>
      'contact_name_cache_$ownerUserId';

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Future<Map<String, Map<String, String>>> _readAll(
    String ownerUserId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(
      _key(ownerUserId),
    );

    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      return decoded.map(
        (id, value) => MapEntry(
          id,
          Map<String, String>.from(value as Map),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> save({
    required String ownerUserId,
    required String userId,
    required String name,
    String phone = '',
  }) async {
    if (ownerUserId.isEmpty ||
        userId.isEmpty ||
        name.isEmpty) {
      return;
    }

    final all = await _readAll(ownerUserId);

    all[userId] = {
      'name': name,
      'phone': phone,
    };

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key(ownerUserId),
      jsonEncode(all),
    );
  }

  Future<Map<String, String>?> get({
    required String ownerUserId,
    required String userId,
  }) async {
    final all = await _readAll(ownerUserId);
    return all[userId];
  }

  Future<Map<String, String>?> findByPhone({
    required String ownerUserId,
    required String phone,
  }) async {
    final target = _normalizePhone(phone);

    if (target.isEmpty) return null;

    final all = await _readAll(ownerUserId);

    for (final entry in all.entries) {
      final cachedPhone =
          _normalizePhone(entry.value['phone'] ?? '');

      if (cachedPhone.isEmpty) continue;

      if (cachedPhone == target ||
          cachedPhone.endsWith(target) ||
          target.endsWith(cachedPhone)) {
        return {
          'userId': entry.key,
          'name': entry.value['name'] ?? '',
          'phone': entry.value['phone'] ?? phone,
        };
      }
    }

    return null;
  }

  Future<List<Map<String, String>>> getAllContacts(
    String ownerUserId,
  ) async {
    final all = await _readAll(ownerUserId);

    return all.entries
        .map(
          (e) => {
            'userId': e.key,
            'name': e.value['name'] ?? '',
            'phone': e.value['phone'] ?? '',
          },
        )
        .toList();
  }
}