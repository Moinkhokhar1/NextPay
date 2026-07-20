import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/theme_provider.dart';
import 'payment_success_animation.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String amount;
  final String receiverName;
  final String transactionId;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.receiverName,
    this.transactionId = '',
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _navigated = false;

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      body: PaymentSuccessAnimation(
        amount: widget.amount,
        receiverName: widget.receiverName,
        transactionId: widget.transactionId.isNotEmpty
            ? widget.transactionId
            : "TXN${DateTime.now().millisecondsSinceEpoch}",
        mode: "Wallet Transfer",
        timestamp: DateTime.now().toLocal().toString(),
        onDone: _goHome,
        c: c,
      ),
    );
  }
}