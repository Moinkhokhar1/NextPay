import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _PaymentSuccessAnimationState extends State<PaymentSuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final AnimationController _checkController;
  late final AnimationController _confettiController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _circleScale;
  late final Animation<double> _checkProgress;
  late final Animation<double> _pulseScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _amountFade;
  late final Animation<double> _detailFade;

  final AudioPlayer _player = AudioPlayer();
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _circleScale = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeOutBack,
    );

    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOutCubic,
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _titleFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _amountFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    _detailFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    );

    _generateConfetti();
    _startAnimations();
  }

  void _generateConfetti() {
    final colors = [
      widget.c.teal,
      widget.c.purple,
      widget.c.successText,
      Colors.white,
      Colors.amber,
      Colors.orange,
      Colors.pink,
    ];

    _particles.clear();

    for (int i = 0; i < 40; i++) {
      _particles.add(
        _ConfettiParticle(
          // tighter fan spread
          angle: (-pi / 2.5) + (_random.nextDouble() * pi * 0.9),

          // reduced speed
          speed: 70 + _random.nextDouble() * 90,

          size: 5 + _random.nextDouble() * 6,

          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }
  }

  Future<void> _startAnimations() async {
    HapticFeedback.heavyImpact();

    try {
      await _player.play(
        AssetSource('sounds/success.mp3'),
      );
    } catch (_) {}

    // Circle first
    await _circleController.forward();

    // Tick draw second
    await _checkController.forward();

    // Blast after tick completes
    HapticFeedback.mediumImpact();
    _confettiController.forward();

    // Pulse after blast
    _pulseController.repeat(reverse: true);

    // Text animations
    await _textController.forward();

    Future.delayed(
      const Duration(seconds: 3),
      widget.onDone,
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _confettiController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  // Only showing the changed UI parts

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.c.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseScale,
                  child: ScaleTransition(
                    scale: _circleScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.c.successText,
                        boxShadow: [
                          BoxShadow(
                            color: widget.c.successText.withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _checkProgress,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    "Payment Successful",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.c.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                FadeTransition(
                  opacity: _amountFade,
                  child: Text(
                    "₹${widget.amount}",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: widget.c.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _detailFade,
                  child: Column(
                    children: [
                      Text(
                        "Paid to ${widget.receiverName}",
                        style: TextStyle(
                          fontSize: 17,
                          color: widget.c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.timestamp,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.c.textSecondary.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.c.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Transaction ID",
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.transactionId,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.mode == "offline"
                              ? widget.c.amberLight
                              : widget.c.tealLight,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          widget.mode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.mode == "offline"
                                ? widget.c.amber
                                : widget.c.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(
      size.width / 2,
      size.height / 2 - 120, // exact tick position
    );

    for (final p in particles) {
      final blast = Curves.easeOutExpo.transform(progress);

      final distance = p.speed * blast * 1.5;

      final dx = cos(p.angle) * distance;

      final gravity = 180 * progress * progress;
      final dy = (sin(p.angle) * distance) + gravity;

      final opacity = (1 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);

      canvas.rotate(progress * 10);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.45,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}