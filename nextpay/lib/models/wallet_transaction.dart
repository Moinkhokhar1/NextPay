/// Represents a server-side wallet transaction record
/// returned by GET /wallet/transactions
class WalletTransaction {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final num amount;
  final bool isOffline;
  final String status;
  final Map<String, dynamic> extra;

  WalletTransaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.isOffline,
    required this.status,
    required this.senderName,
    required this.receiverName,
    this.extra = const {},
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    final id         = copy.remove('id');
    final senderId   = copy.remove('sender_id') ?? copy.remove('senderId');
    final receiverId = copy.remove('receiver_id') ?? copy.remove('receiverId');
    final amount     = copy.remove('amount');
    final isOffline  = copy.remove('is_offline') ?? copy.remove('isOffline');
    final status     = copy.remove('status');

    var senderName = copy.remove('sender_name') ?? copy.remove('senderName');
    var receiverName = copy.remove('receiver_name') ?? copy.remove('receiverName');

    return WalletTransaction(
      id:           id.toString(),
      senderId:     senderId.toString(),
      senderName:   senderName?.toString() ?? 'Unknown',
      receiverId:   receiverId.toString(),
      receiverName: receiverName?.toString() ?? 'Unknown',
      amount:    amount is num ? amount : num.parse(amount.toString()),
      isOffline: isOffline == true || isOffline == 1,
      status:    (status ?? '').toString(),
      extra:     copy,
    );
  }
  DateTime get createdAt {
    final raw = extra['created_at']?.toString();
    if (raw == null || raw.isEmpty) return DateTime.now();
    return DateTime.parse(raw).toLocal();
  }
}