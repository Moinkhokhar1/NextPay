/// Represents a chat message between the current user and a contact,
/// as returned by GET/POST /messages.
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdRaw =
        (json['created_at'] ?? json['createdAt'])?.toString();

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      receiverId:
          (json['receiver_id'] ?? json['receiverId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: createdRaw != null && createdRaw.isNotEmpty
          ? DateTime.parse(createdRaw).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
