import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_crypto_util.dart';

/// Gateway number — replace with a real gateway SIM later.
/// For now all payment SMSes go to this number.
const String kGatewayNumber = '+917201074880';

/// Result of an SMS send attempt.
class SmsSendResult {
  final bool success;
  final String message;
  final String? payload;
  SmsSendResult({required this.success, required this.message, this.payload});
}

class SmsPaymentService {
  static final SmsPaymentService instance = SmsPaymentService._();
  SmsPaymentService._();

  final Telephony _telephony = Telephony.instance;

  /// Request SEND_SMS permission. Call once on app startup.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Sends an offline payment SMS to the gateway.
  Future<SmsSendResult> sendPayment({
    required String senderId,
    required String receiverId,
    required double amount,
  }) async {
    // 1. Permission check
    final hasPermission = await Permission.sms.isGranted;
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        return SmsSendResult(success: false, message: 'SMS permission denied. Cannot send offline payment.');
      }
    }

    // 2. Build signed payload
    final payload = await SmsCryptoUtil.buildPayload(
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
    );

    // 3. Send SMS
    try {
      bool sent = false;

      await _telephony.sendSms(
        to: kGatewayNumber,
        message: payload,
        statusListener: (SendStatus status) {
          sent = status == SendStatus.SENT;
        },
      );

      // Small wait for status callback
      await Future.delayed(const Duration(seconds: 2));

      return SmsSendResult(
        success: true,
        message: 'Payment SMS sent to gateway.',
        payload: payload,
      );
    } catch (e) {
      return SmsSendResult(
        success: false,
        message: 'Failed to send SMS: $e',
      );
    }
  }
}