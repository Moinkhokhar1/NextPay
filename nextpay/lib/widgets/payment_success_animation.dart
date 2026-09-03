import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import '../app_colors.dart';

class PaymentSuccessAnimation extends StatefulWidget {
  final String amount;
  final String receiverName;
  final String transactionId;
  final String mode;
  final String timestamp;
  final VoidCallback onDone;
  final AppColors c;

  const PaymentSuccessAnimation({
    super.key,
    required this.amount,
    required this.receiverName,
    required this.transactionId,
    required this.mode,
    required this.timestamp,
    required this.onDone,
    required this.c,
  });

  @override
  State<PaymentSuccessAnimation> createState() =>
      _PaymentSuccessAnimationState();
}

class _PaymentSuccessAnimationState extends State<PaymentSuccessAnimation> {
  final AudioPlayer _player = AudioPlayer();
  bool _showDetails = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54, // dim backdrop instead of full-screen Material
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.c.bg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 160,
                child: Lottie.asset(
                  'assets/animations/success.json',
                  repeat: false,
                  onLoaded: (composition) {
                    HapticFeedback.mediumImpact();
                    _player.play(AssetSource('sounds/success.mp3')).catchError((_) {});

                    // reveal details once the checkmark animation finishes
                    Future.delayed(composition.duration, () {
                      if (!mounted) return;
                      setState(() => _showDetails = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) widget.onDone();
                      });
                    });
                  },
                ),
              ),

              AnimatedOpacity(
                opacity: _showDetails ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    Text(
                      "Payment Successful",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${widget.amount}",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: widget.c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Paid to ${widget.receiverName}",
                      style: TextStyle(fontSize: 15, color: widget.c.textSecondary),
                    ),
                    Text(
                      widget.timestamp,
                      style: TextStyle(fontSize: 12, color: widget.c.textSecondary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.c.border),
                      ),
                      child: Column(
                        children: [
                          Text("Transaction ID",
                              style: TextStyle(fontSize: 10, color: widget.c.textSecondary)),
                          const SizedBox(height: 3),
                          Text(widget.transactionId,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.c.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.mode == "offline" ? widget.c.amberLight : widget.c.tealLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.mode.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.mode == "offline" ? widget.c.amber : widget.c.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}