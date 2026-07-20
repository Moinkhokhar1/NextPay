import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches contact display names and phones keyed by user id so the People
/// row shows real names even when the transactions API omits them.
class ContactCacheService {
  ContactCacheService._();
  static final ContactCacheService instance = ContactCacheService._();

  static const _key = 'contact_name_cache';

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Future<Map<String, Map<String, String>>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
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
    required String userId,
    required String name,
    String phone = '',
  }) async {
    if (userId.isEmpty || name.isEmpty) return;
    final all = await _readAll();
    all[userId] = {'name': name, 'phone': phone};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }

  Future<Map<String, String>?> get(String userId) async {
    final all = await _readAll();
    return all[userId];
  }

  /// Returns `{userId, name, phone}` when a cached contact matches [phone].
  Future<Map<String, String>?> findByPhone(String phone) async {
    final target = _normalizePhone(phone);
    if (target.isEmpty) return null;

    final all = await _readAll();
    for (final entry in all.entries) {
      final cachedPhone = _normalizePhone(entry.value['phone'] ?? '');
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

  Future<List<Map<String, String>>> getAllContacts() async {
    final all = await _readAll();
    return all.entries
        .map((e) => {
              'userId': e.key,
              'name': e.value['name'] ?? '',
              'phone': e.value['phone'] ?? '',
            })
        .toList();
  }

  Future<String?> getName(String userId) async {
    final entry = await get(userId);
    return entry?['name'];
  }

  Future<String?> getPhone(String userId) async {
    final entry = await get(userId);
    return entry?['phone'];
  }
}
