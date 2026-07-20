class OfflineTransaction {
  final String txId;
  final String sender;
  final String receiver;
  final num amount;
  final int timestamp;
  final int nonce;
  final String status;
  final bool synced;
  final String? signature;

  OfflineTransaction({
    required this.txId,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.timestamp,
    required this.nonce,
    this.status = "pending",
    this.synced = false,
    this.signature,
  });

  factory OfflineTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final num amount = rawAmount is int
        ? rawAmount
        : (rawAmount is double && rawAmount % 1 == 0)
        ? rawAmount.toInt()
        : rawAmount as num;

    return OfflineTransaction(
      txId: json['txId'] as String,
      sender: json['sender'].toString(),
      receiver: json['receiver'].toString(),
      amount: amount,
      timestamp: json['timestamp'] as int,
      nonce: json['nonce'] as int,
      status: json['status'] ?? "pending",
      synced: json['synced'] ?? false,
      signature: json['signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'txId': txId,
      'sender': sender,
      'receiver': receiver,
      'amount': amount,
      'timestamp': timestamp,
      'nonce': nonce,
      'status': status,
      'synced': synced,
      if (signature != null) 'signature': signature,
    };
  }

  OfflineTransaction copyWith({String? signature, String? status, bool? synced}) {
    return OfflineTransaction(
      txId: txId,
      sender: sender,
      receiver: receiver,
      amount: amount,
      timestamp: timestamp,
      nonce: nonce,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      signature: signature ?? this.signature,
    );
  }
}