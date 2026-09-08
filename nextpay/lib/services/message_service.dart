import 'dart:convert';
import '../models/chat_message.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Loads and sends chat messages for a single contact thread.
class MessageService {
  MessageService._();

  static String _cacheKey(String contactId) => 'cached_messages_$contactId';

  /// Loads the full thread with [contactId], oldest first. Falls back to
  /// the last cached copy when offline so the chat still renders.
  static Future<List<ChatMessage>> loadThread(String contactId) async {
    try {
      final response = await ApiService.instance.get('/messages/$contactId');
      final List<dynamic> data = response.data;
      await StorageService.setItem(_cacheKey(contactId), jsonEncode(data));
      return data
          .map((item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      final cached = await StorageService.getItem(_cacheKey(contactId));
      if (cached == null) return [];
      final List<dynamic> data = jsonDecode(cached);
      return data
          .map((item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
  }

  /// Sends a message to [receiverId]. Throws on failure (e.g. offline) so
  /// the caller can surface an error instead of silently dropping it.
  static Future<ChatMessage> send({
    required String receiverId,
    required String content,
  }) async {
    final response = await ApiService.instance.post(
      '/messages',
      data: {'receiverId': receiverId, 'content': content},
    );
    return ChatMessage.fromJson(Map<String, dynamic>.from(response.data));
  }
}
