// gyre_otp_field.dart
//
// A Flutter port of the "GYRE" OTP interaction from
// https://github.com/Moinkhokhar1/otp-verification-v3
//
// The web original is a 4-digit *demo* with a hardcoded code and no backend —
// its state machine is idle -> filling -> checking -> ok, or -> error -> filling.
// Ported here 1:1 as far as the animation language goes, adapted to:
//   - N digits (your app uses 6, the original used 4)
//   - a REAL async verify (your AuthProvider.loginWithOtp), so "checking" is a
//     real network wait, not an instant mock check
//
// What's exact vs. adapted:
//   - EXACT: the animation only plays on a CORRECT code. A wrong code never
//     curls — it flashes red and shakes flat, then clears right-to-left,
//     exactly like the original's fail().
//   - EXACT: colour is reserved for verdicts only — mint = accepted, red =
//     refused. Everything else (focus, charge) is your existing purple.
//   - EXACT: the ring is one rigid body — I rotate the whole Stack once,
//     rather than animating each box's own rotation, which is the same
//     "transform-origin at the hub" trick the source article describes,
//     translated to Flutter's Transform widget.
//   - EXACT: the digits counter-rotate against the ring so they stay upright
//     while the ring spins — same "unwind" idea as the source.
//   - ADAPTED: the source's curl uses hand-tuned polar interpolation per box
//     with staggered per-box lag. I keep the polar interpolation (angle and
//     radius lerped separately, not the x/y directly — that's the part that
//     actually produces the arc) but drop the sound design / Web OTP API /
//     recording harness, none of which apply to a native app.
//   - ADAPTED: landing angles are evenly spaced for N digits (60° apart for
//     6) instead of the original's 4 cardinal points, so the ring scales to
//     your digit count.
//
// Usage: see the updated login_screen.dart alongside this file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GyreState { idle, filling, checking, ok, error }

/// Lets the parent (which owns the real network call) drive the field's
/// verdict, mirroring the source's setState('ok') / fail().
class GyreOtpController {
  _GyreOtpFieldState? _bound;
  void _attach(_GyreOtpFieldState s) => _bound = s;

  /// Code was accepted — plays curl → spin → hold → screw down to a mint tile.
  Future<void> playSuccess() async => _bound?._playSuccess();

  /// Code was refused — flashes red, shakes in place, clears right-to-left.
  Future<void> playError() async => _bound?._playError();

  /// Hard reset back to an empty, idle row (e.g. after "Resend OTP").
  void reset() => _bound?._reset();
}

class GyreOtpField extends StatefulWidget {
  const GyreOtpField({
    super.key,
    required this.length,
    required this.controllers,
    required this.focusNodes,
    required this.controller,
    required this.onCompleted,
    this.enabled = true,
    this.boxSize = 44,
    this.gap = 8,
    this.accent = const Color(0xFF534AB7),
    this.mint = const Color(0xFF2EE6A8),
    this.bad = const Color(0xFFFF4D6A),
    this.border = const Color(0xFFE9E7E1),
    this.surface = Colors.white,
    this.textColor = const Color(0xFF1A1A1A),
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final GyreOtpController controller;

  /// Called once when the row fills — this is where you kick off the real
  /// verify call, then respond with controller.playSuccess()/playError().
  final ValueChanged<String> onCompleted;

  final bool enabled;
  final double boxSize;
  final double gap;
  final Color accent;
  final Color mint;
  final Color bad;
  final Color border;
  final Color surface;
  final Color textColor;

  @override
  State<GyreOtpField> createState() => _GyreOtpFieldState();
}

class _GyreOtpFieldState extends State<GyreOtpField>
    with TickerProviderStateMixin {
  // Curl in (row -> ring) and, in reverse, curl out for a hard reset.
  late final AnimationController _curl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 660));
  // Rigid-body spin: a turn and a quarter, matching TURNS = 1.25 in the source.
  late final AnimationController _spin =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  // Hold (mint, still) then screw down to the hub.
  late final AnimationController _screw =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  // Flat shake + red flash for a refusal — never touches the ring.
  late final AnimationController _shake =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  GyreState _state = GyreState.idle;
  bool _submitted = false;
  // True while _playError is emptying the row. The clears fire _onChanged, and
  // without this they read as the user refilling — which flips us out of
  // `error` and aborts the wipe after the first digit.
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    for (final c in widget.controllers) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.removeListener(_onChanged);
    }
    _curl.dispose();
    _spin.dispose();
    _screw.dispose();
    _shake.dispose();
    super.dispose();
  }

  String get _value => widget.controllers.map((c) => c.text).join();

  void _onChanged() {
    if (_state == GyreState.checking || _state == GyreState.ok) return;
    // Our own wipe: repaint the emptied slot, but leave the verdict alone.
    if (_clearing) {
      setState(() {});
      return;
    }
    setState(() {
      if (_state == GyreState.error) _state = GyreState.filling;
      if (_state == GyreState.idle && _value.isNotEmpty) _state = GyreState.filling;
    });
    if (_value.length == widget.length && !_submitted) {
      _submitted = true;
      setState(() => _state = GyreState.checking);
      for (final f in widget.focusNodes) {
        f.unfocus();
      }
      widget.onCompleted(_value);
    }
  }

  // ---------- verdicts, called by the parent via GyreOtpController ----------

  Future<void> _playSuccess() async {
    if (!mounted) return;
    await _curl.forward(from: 0); // row -> ring
    if (!mounted) return;
    await _spin.forward(from: 0); // the turn and a quarter
    if (!mounted) return;
    setState(() => _state = GyreState.ok); // mint lands here, matches the source's beat
    await Future.delayed(const Duration(milliseconds: 360)); // HOLD_MS
    if (!mounted) return;
    await _screw.forward(from: 0); // screw down into the hub
  }

  Future<void> _playError() async {
    if (!mounted) return;
    setState(() => _state = GyreState.error);
    HapticFeedback.mediumImpact();
    await _shake.forward(from: 0);
    if (!mounted) return;
    // "rub them out from the right — the same direction they were typed,
    // reversed" — identical beat to the source's fail().
    _clearing = true;
    for (int i = widget.length - 1; i >= 0; i--) {
      // A concurrent reset() (e.g. "Resend OTP") clears _clearing and moves us
      // out of `error`; that's our cue to abandon the wipe.
      if (!mounted || _state != GyreState.error) return;
      widget.controllers[i].clear();
      await Future.delayed(const Duration(milliseconds: 56));
    }
    if (!mounted) return;
    _reset(refocus: true);
  }

  void _reset({bool refocus = false}) {
    _submitted = false;
    _clearing = false;
    _curl.reset();
    _spin.reset();
    _screw.reset();
    _shake.reset();
    setState(() => _state = GyreState.idle);
    if (refocus && mounted) {
      FocusScope.of(context).requestFocus(widget.focusNodes.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.length;
    final w = widget.boxSize;
    final gap = widget.gap;
    final rowWidth = n * w + (n - 1) * gap;
    // Row-form position of each box, relative to the row's own centre (hub).
    final rowPos = List.generate(
      n,
          (i) => Offset(-rowWidth / 2 + w / 2 + i * (w + gap), 0),
    );
    // Landing points on the ring, evenly spaced — 60° apart for 6 digits.
    // (The source uses the 4 cardinal points; this is the same idea scaled
    // to N.)
    final orbitR = w * 1.25;
    final targetAngle = List.generate(
      n,
          (i) => (-90 + i * (360 / n)) * math.pi / 180,
    );

    // Reserve the orbit's clearance permanently, like the source's
    // --gyre-clear margin, so nothing below the field twitches when it curls.
    // The boxes rotate with the ring, so the clearance has to cover a box's
    // half-*diagonal* past the orbit, not half its width — otherwise the
    // enclosing Stack (which clips by default) shaves the top and bottom of
    // the ring mid-spin.
    final slotH = w * 1.18;
    final halfDiagonal = math.sqrt(w * w + slotH * slotH) / 2;
    final reservedHeight = math.max(w * 3.2, (orbitR + halfDiagonal) * 2);

    return SizedBox(
      height: reservedHeight,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_curl, _spin, _screw, _shake]),
        builder: (context, _) {
          final curlT = Curves.easeOutBack.transform(_curl.value);
          final spinT = _spin.value;
          final ringAngle = spinT * 2 * math.pi * 1.25; // TURNS = 1.25
          final screwT = Curves.easeInCubic.transform(_screw.value);
          final shakeT = _shake.value;
          final shakeOffset = _state == GyreState.error
              ? math.sin(shakeT * math.pi * 6) * (1 - shakeT) * 6
              : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // The row/ring stays on screen through the mint hold — that's
              // what makes _slot's `isOk` styling visible — and the screw pulls
              // it into the hub rather than cutting straight to the tile.
              Opacity(
                opacity: 1 - screwT,
                child: Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: Transform.rotate(
                    angle: ringAngle,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(n, (i) {
                        final start = rowPos[i];
                        final r0 = start.distance;
                        final theta0 = start.dx >= 0 ? 0.0 : math.pi;
                        // Polar interpolation — angle and radius lerped
                        // separately, then converted to x/y. Lerping the x/y
                        // directly draws a straight line, not an arc. The screw
                        // collapses the orbit, so the boxes spiral to the hub.
                        final orbit = orbitR * (1 - screwT);
                        final r = _lerp(r0, curlT == 0 ? r0 : orbit, curlT);
                        final theta = _lerpAngle(theta0, targetAngle[i], curlT);
                        final pos = curlT == 0
                            ? start
                            : Offset(r * math.cos(theta), r * math.sin(theta));

                        return Transform.translate(
                          offset: pos,
                          child: Transform.rotate(
                            // Counter-rotate so the digit stays upright while
                            // the ring spins around it — the "unwind".
                            angle: -ringAngle,
                            child: Transform.scale(
                              scale: 1 - screwT * 0.35,
                              child: _slot(i, w),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // The mint tile the ring screws down into, fading up underneath
              // as the boxes converge.
              if (screwT > 0)
                Opacity(
                  opacity: screwT,
                  child: Transform.scale(
                    scale: 0.55 + screwT * 0.45,
                    child: Container(
                      width: w * 0.95,
                      height: w * 0.95,
                      decoration: BoxDecoration(
                        color: widget.mint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.mint.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _slot(int i, double w) {
    final hasValue = widget.controllers[i].text.isNotEmpty;
    final isError = _state == GyreState.error;
    final isChecking = _state == GyreState.checking;
    final isOk = _state == GyreState.ok;
    final editable = _state == GyreState.idle ||
        _state == GyreState.filling ||
        _state == GyreState.error;

    Color borderColor = widget.border;
    Color glow = Colors.transparent;
    if (isError) {
      borderColor = widget.bad;
    } else if (isOk || isChecking) {
      borderColor = isOk ? widget.mint : widget.accent;
      glow = borderColor.withValues(alpha: 0.25);
    } else if (hasValue) {
      borderColor = widget.accent;
    }

    return SizedBox(
      width: w,
      height: w * 1.18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError ? widget.bad.withValues(alpha: 0.08) : widget.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: hasValue || isError || isChecking || isOk ? 1.5 : 1,
          ),
          boxShadow: glow == Colors.transparent
              ? null
              : [BoxShadow(color: glow, blurRadius: 8, spreadRadius: 1)],
        ),
        child: editable
            ? Center(
          child: TextField(
            controller: widget.controllers[i],
            focusNode: widget.focusNodes[i],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            autocorrect: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isError ? widget.bad : widget.textColor,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => _onDigitInput(i, v),
          ),
        )
            : IgnorePointer(
          // During checking/ok the ring is display-only.
          child: Center(
            child: Text(
              widget.controllers[i].text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isOk ? widget.mint : widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDigitInput(int i, String value) {
    if (value.isNotEmpty) {
      if (i + 1 < widget.length) {
        widget.focusNodes[i + 1].requestFocus();
      } else {
        widget.focusNodes[i].unfocus();
      }
    } else if (i > 0) {
      widget.focusNodes[i - 1].requestFocus();
    }
    // _onChanged (added as a controller listener) handles the completion
    // check, so nothing else to do here.
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _lerpAngle(double a, double b, double t) {
    // Shortest-path angle lerp so boxes curl the short way onto the ring.
    double diff = (b - a) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return a + diff * t;
  }
}