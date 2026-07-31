import 'dart:async';
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
  late final AnimationController _confettiController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _pulseScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _amountFade;
  late final Animation<double> _detailFade;

  final AudioPlayer _player = AudioPlayer();
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _ringKey = GlobalKey();
  Offset _confettiOrigin = Offset.zero;

  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureConfettiOrigin());
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
          angle: (-pi / 2.5) + (_random.nextDouble() * pi * 0.9),
          speed: 70 + _random.nextDouble() * 90,
          size: 5 + _random.nextDouble() * 6,
          rotationSpeed: 4 + _random.nextDouble() * 10,
          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }
  }

  void _measureConfettiOrigin() {
    final ringBox = _ringKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (ringBox == null || stackBox == null) return;

    final ringCenterGlobal = ringBox.localToGlobal(ringBox.size.center(Offset.zero));
    final localCenter = stackBox.globalToLocal(ringCenterGlobal);

    if (mounted) setState(() => _confettiOrigin = localCenter);
  }

  Future<void> _startAnimations() async {
    HapticFeedback.heavyImpact();

    // Fire-and-forget: don't block the ring animation on audio decode/playback.
    _player.play(AssetSource('sounds/success.mp3')).catchError((_) {});

    // The ring + checkmark animate themselves (see DashingRingCheck below);
    // _onRingComplete continues the sequence once the check is actually drawn.
  }

  void _onRingComplete() {
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    _confettiController.forward();
    _pulseController.repeat(reverse: true);
    _textController.forward();

    _doneTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _confettiController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.c.bg,
      child: Stack(
        key: _stackKey,
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
                      origin: _confettiOrigin,
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
                  child: Container(
                    key: _ringKey,
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.c.successText.withOpacity(0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: DashingRingCheck(
                      size: 140,
                      color: widget.c.successText,
                      trackColor: widget.c.border,
                      onComplete: _onRingComplete,
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

/// A dashed ring that spins into place, then draws a checkmark stroke-by-stroke.
class DashingRingCheck extends StatefulWidget {
  final double size;
  final Color color;
  final Color trackColor;
  final VoidCallback? onComplete;

  const DashingRingCheck({
    super.key,
    this.size = 140,
    this.color = const Color(0xFF1D9E75),
    this.trackColor = const Color(0x33000000),
    this.onComplete,
  });

  @override
  State<DashingRingCheck> createState() => _DashingRingCheckState();
}

class _DashingRingCheckState extends State<DashingRingCheck>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _checkController;
  late final Animation<double> _ringDraw;
  late final Animation<double> _ringSpin;
  late final Animation<double> _checkDraw;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _ringDraw = CurvedAnimation(
      parent: _ringController,
      curve: const Cubic(0.2, 0.7, 0.3, 1.0),
    );

    _ringSpin = Tween<double>(begin: -pi / 2, end: pi * 1.5).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _checkDraw = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );

    _run();
  }

  Future<void> _run() async {
    await _ringController.forward();
    if (!mounted) return;
    await _checkController.forward();
    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ringController, _checkController]),
        builder: (_, __) {
          return CustomPaint(
            painter: _DashingRingPainter(
              ringProgress: _ringDraw.value,
              rotation: _ringSpin.value,
              checkProgress: _checkDraw.value,
              color: widget.color,
              trackColor: widget.trackColor,
            ),
          );
        },
      ),
    );
  }
}

class _DashingRingPainter extends CustomPainter {
  final double ringProgress;
  final double rotation;
  final double checkProgress;
  final Color color;
  final Color trackColor;

  _DashingRingPainter({
    required this.ringProgress,
    required this.rotation,
    required this.checkProgress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, trackPaint);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final ringPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation,
        2 * pi * ringProgress,
      );

    canvas.drawPath(_dashPath(ringPath, dashLength: 14, gapLength: 10), ringPaint);

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final w = size.width;
      final h = size.height;
      final checkPath = Path()
        ..moveTo(w * 0.30, h * 0.52)
        ..lineTo(w * 0.44, h * 0.66)
        ..lineTo(w * 0.72, h * 0.36);

      canvas.drawPath(_trimPath(checkPath, checkProgress), checkPaint);
    }
  }

  Path _trimPath(Path source, double t) {
    if (t >= 1) return source;
    final metrics = source.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * t;

    final result = Path();
    double consumed = 0;
    for (final metric in metrics) {
      if (consumed >= targetLength) break;
      final remaining = targetLength - consumed;
      final take = min(metric.length, remaining);
      result.addPath(metric.extractPath(0, take), Offset.zero);
      consumed += metric.length;
    }
    return result;
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final next = min(distance + segmentLength, metric.length);
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashingRingPainter oldDelegate) {
    return oldDelegate.ringProgress != ringProgress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.checkProgress != checkProgress;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Offset origin;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final p in particles) {
      final blast = Curves.easeOutExpo.transform(progress);

      final distance = p.speed * blast * 1.5;
      final dx = cos(p.angle) * distance;

      final gravity = 180 * progress * progress;
      final dy = (sin(p.angle) * distance) + gravity;

      final opacity = (1 - progress).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(progress * p.rotationSpeed);

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
    return oldDelegate.progress != progress || oldDelegate.origin != origin;
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final Color color;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });
}