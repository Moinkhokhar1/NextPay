import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

const _bg = Color(0xFFF3EBDD);
const _dark = Color(0xFF1A0A00);
const _border = Color(0xFF111111);
const _orange = Color(0xFFC85A1E);
const _muted = Color(0xFF9A7A5A);
const _green = Color(0xFF1E6B37);

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  bool _scanned = false;
  Map<String, dynamic>? _lastPayment;
  final MobileScannerController _controller = MobileScannerController();
  final FlutterTts _tts = FlutterTts();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final data = barcodes.first.rawValue;
    if (data == null) return;

    setState(() => _scanned = true);

    try {
      final payload = Map<String, dynamic>.from(jsonDecode(data));

      if (payload["type"] != "PAYMENT_CONFIRMATION") {
        _showAlert("Invalid QR", "This is not a payment QR");
        setState(() => _scanned = false);
        return;
      }

      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final walletUserId = user?.wallet?.extra['user_id']?.toString();

      if (payload["receiverId"].toString() != walletUserId) {
        _showAlert("Wrong Receiver", "This payment is not for your wallet");
        setState(() => _scanned = false);
        return;
      }

      // Duplicate prevention
      final scannedKey = "scanned_${payload["txId"]}";
      final alreadyScanned = await StorageService.getItem(scannedKey);
      if (alreadyScanned != null) {
        _showAlert("Already Received", "This payment was already confirmed");
        setState(() => _scanned = false);
        return;
      }

      // Save scanned receipt locally
      await StorageService.setItem(scannedKey, jsonEncode(payload));

      // Save to receiver's pending so it syncs to backend
      final storageKey = "pending_received_$walletUserId";
      final existingRaw = await StorageService.getItem(storageKey);
      final List<dynamic> list = existingRaw != null ? jsonDecode(existingRaw) : [];
      list.add(payload);
      await StorageService.setItem(storageKey, jsonEncode(list));

      setState(() => _lastPayment = payload);

      // TTS announcement
      await _tts.setLanguage("en-IN");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.9);
      await _tts.speak("${payload["amount"]} rupees received from ${payload["senderName"]}");
    } catch (e) {
      _showAlert("Error", "Invalid QR code");
      setState(() => _scanned = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // HEADER
          Container(
            color: _dark,
            padding: EdgeInsets.fromLTRB(
              20,
              Theme.of(context).platform == TargetPlatform.iOS ? 54 : 40,
              20,
              20,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text("←", style: TextStyle(color: _bg, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("VENDOR", style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    Text("Receive Payment", style: TextStyle(color: _bg, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: _lastPayment == null
                ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: _border, width: 3)),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _handleScan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Scan the sender's confirmation QR",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5A3A00)),
                  ),
                ],
              ),
            )
                : _buildSuccessCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    final payment = _lastPayment!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("✓", style: TextStyle(fontSize: 64, color: _green)),
            const SizedBox(height: 8),
            const Text(
              "PAYMENT RECEIVED",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 3),
            ),
            const SizedBox(height: 12),
            Text(
              "₹${payment["amount"]}",
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: _green),
            ),
            Text(
              "from ${payment["senderName"]}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
            ),
            const SizedBox(height: 16),
            const Text(
              "Will sync to your wallet when internet is restored",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted, height: 1.4),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(color: _orange, border: Border.all(color: _border, width: 3)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _scanned = false;
                    _lastPayment = null;
                  }),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    child: Text(
                      "SCAN NEXT PAYMENT",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}