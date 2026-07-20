import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:another_telephony/telephony.dart'; // ← replaces telephony
import 'sms_crypto_util.dart';

const String kGatewayNumber = '+15054793064';
const _notifChannelId = 'offlinepay_sms';
const _notifChannelName = 'OfflinePay SMS Listener';

Future<void> initSmsListenerService() async {
  final service = FlutterBackgroundService();

  final notifPlugin = FlutterLocalNotificationsPlugin();
  const androidChannel = AndroidNotificationChannel(
    _notifChannelId,
    _notifChannelName,
    description: 'Listens for incoming payment confirmations',
    importance: Importance.low,
  );
  await notifPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: _notifChannelId,
      initialNotificationTitle: 'OfflinePay',
      initialNotificationContent: 'Listening for payment confirmations...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onServiceStart,
      onBackground: _onIosBackground,
    ),
  );

  await service.startService();
}

Future<void> stopSmsListenerService() async {
  final service = FlutterBackgroundService();
  service.invoke('stop');
}

@pragma('vm:entry-point')
Future<void> _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('stop').listen((_) => service.stopSelf());
    await service.setAsForegroundService();
  }

  final tts = FlutterTts();
  await _configureTts(tts);

  final telephony = Telephony.instance; // ← another_telephony API is identical

  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) async {
      final body = message.body ?? '';
      final from = message.address ?? '';

      if (_isConfirmationSms(from, body)) {
        final parsed = _parseConfirmation(body);
        if (parsed != null) {
          final amount = parsed['amount'] as String;
          final sender = parsed['sender'] as String;
          final announcement = 'Payment received. Rupees $amount. From $sender.';

          await tts.speak(announcement);

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Payment Received ✓',
              content: '₹$amount from $sender',
            );
          }

          service.invoke('payment_received', {
            'amount': amount,
            'sender': sender,
          });
        }
      }
    },
    listenInBackground: false,
  );

  Timer.periodic(const Duration(seconds: 30), (_) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'OfflinePay',
        content: 'Listening for payment confirmations...',
      );
    }
  });
}

@pragma('vm:entry-point')
bool _onIosBackground(ServiceInstance service) => true;

Future<void> _configureTts(FlutterTts tts) async {
  await tts.setLanguage('en-IN');
  await tts.setSpeechRate(0.45);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
}

bool _isConfirmationSms(String from, String body) {
  return from.contains('7201074880') || body.startsWith('PAY_CONFIRM#');
}

Map<String, String>? _parseConfirmation(String body) {
  try {
    final parts = body.trim().split('#');
    if (parts.length < 3) return null;
    if (parts[0] != 'PAY_CONFIRM') return null;
    return {
      'amount': parts[1],
      'sender': parts[2],
    };
  } catch (_) {
    return null;
  }
}

class SmsPaymentEvents {
  static final _controller = StreamController<Map<String, String>>.broadcast();
  static Stream<Map<String, String>> get stream => _controller.stream;

  static void listenFromService() {
    FlutterBackgroundService().on('payment_received').listen((event) {
      if (event != null) {
        _controller.add({
          'amount': event['amount']?.toString() ?? '0',
          'sender': event['sender']?.toString() ?? 'Unknown',
        });
      }
    });
  }

  static void dispose() => _controller.close();
}