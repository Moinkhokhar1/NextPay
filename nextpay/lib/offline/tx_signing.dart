import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Must match server/src/controllers/syncController.js exactly.
const offlineTxSecretKey = 'offline-payment-secret';

num normalizeTxAmount(dynamic amount) {
  final n = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
  return n % 1 == 0 ? n.toInt() : n;
}

Map<String, dynamic> buildSigningPayload({
  required String txId,
  required String sender,
  required String receiver,
  required dynamic amount,
  required int timestamp,
  required int nonce,
  String status = 'pending',
}) {
  return {
    'txId': txId,
    'sender': sender,
    'receiver': receiver,
    'amount': normalizeTxAmount(amount),
    'timestamp': timestamp,
    'nonce': nonce,
    'status': status,
    'synced': false,
  };
}

String signPayloadMap(Map<String, dynamic> payloadMap) {
  final payload = jsonEncode(payloadMap);
  return sha256.convert(utf8.encode(payload + offlineTxSecretKey)).toString();
}

String signTransaction(Map<String, dynamic> tx) {
  return signPayloadMap(
    buildSigningPayload(
      txId: tx['txId'] as String,
      sender: tx['sender'].toString(),
      receiver: tx['receiver'].toString(),
      amount: tx['amount'],
      timestamp: tx['timestamp'] as int,
      nonce: tx['nonce'] as int,
      status: (tx['status'] as String?) ?? 'pending',
    ),
  );
}
