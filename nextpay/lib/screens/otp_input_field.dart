// otp_input_field.dart
//
// OTP box row backed by ONE real, invisible TextField — not one TextField
// per digit.
//
// Why: the previous per-box version tried to catch Backspace-on-an-empty-box
// with Focus.onKeyEvent / a hardware key listener. That only ever sees
// hardware key events. On iOS, the on-screen keyboard's delete key is NOT a
// hardware key event — it goes straight through the text-input channel — so
// that handler silently never fired there. That's why backspace still
// looked broken on the iPhone in the screenshots even after adding it.
//
// Fix: keep the whole code in a single TextEditingController, on a single
// TextField stretched invisibly over the row. The N boxes are pure display,
// painted from that one string. Backspace, forward typing, paste, and SMS
// autofill are then all just normal single-field text editing — the same
// code path Flutter already gets right on every platform, so there's no
// platform-specific "catch the key" trick to get wrong.
//
// Usage: give it a length and an onCompleted callback. Call `.clear()` on
// the controller to reset (e.g. on "Resend OTP"), and `.shakeError()` /
// `.showSuccess()` to react to a verify result.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputController {
  _OtpInputFieldState? _state;
  void _attach(_OtpInputFieldState s) => _state = s;
  void _detach(_OtpInputFieldState s) {
    if (_state == s) _state = null;
  }

  String get value => _state?._controller.text ?? '';

  /// Reset back to an empty row and refocus.
  void clear() => _state?._clearAll();

  /// Wrong code: red border + short shake, then clears itself.
  Future<void> shakeError() async => _state?._triggerError();

  /// Correct code: green border, field becomes read-only.
  void showSuccess() => _state?._triggerSuccess();
}

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.length,
    required this.onCompleted,
    this.controller,
    this.enabled = true,
    this.autoFocus = true,
    this.boxSize = 46,
    this.accent = const Color(0xFFBBA4FF),
    this.error = const Color(0xFFFF4D4D),
    this.success = const Color(0xFF2EB872),
    this.border = const Color(0xFFE3E1DC),
    this.textColor = const Color(0xFF1A1A1A),
  });

  final int length;

  /// Called once, as soon as the full code is entered.
  final ValueChanged<String> onCompleted;

  final OtpInputController? controller;
  final bool enabled;
  final bool autoFocus;
  final double boxSize;
  final Color accent;
  final Color error;
  final Color success;
  final Color border;
  final Color textColor;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

enum _Status { idle, error, success }

class _OtpInputFieldState extends State<OtpInputField>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Only used for the brief error shake — nothing else animates.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  _Status _status = _Status.idle;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {}); // repaint the "active box" highlight
  }

  void _clearAll() {
    _submitted = false;
    _controller.clear();
    _shake.reset();
    setState(() => _status = _Status.idle);
    if (mounted) _focusNode.requestFocus();
  }

  Future<void> _triggerError() async {
    if (!mounted) return;
    setState(() => _status = _Status.error);
    HapticFeedback.mediumImpact();
    await _shake.forward(from: 0);
    if (!mounted || _status != _Status.error) return; // reset() may have won the race
    _clearAll();
  }

  void _triggerSuccess() {
    if (!mounted) return;
    setState(() => _status = _Status.success);
    _focusNode.unfocus();
  }

  void _onChanged() {
    if (_status == _Status.error) {
      setState(() => _status = _Status.idle);
    } else {
      setState(() {}); // repaint boxes from the new text
    }
    if (_controller.text.length == widget.length && !_submitted) {
      _submitted = true;
      widget.onCompleted(_controller.text);
    }
  }

  bool get _locked => !widget.enabled || _status == _Status.success;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = _status == _Status.error
            ? math.sin(t * math.pi * 6) * (1 - t) * 8
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: SizedBox(
        width: double.infinity,
        height: widget.boxSize * 1.2,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, _box),
            ),
            // The one real TextField — invisible, stretched over the whole
            // row, topmost in the Stack so it receives every tap directly.
            // It owns the actual text/focus/editing; the boxes above are
            // pure display, painted from _controller.text.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_locked,
                  autofocus: false,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  autocorrect: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  // A tap anywhere should mean "keep typing from where I left
                  // off", not "place the cursor under my finger".
                  onTap: () {
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i) {
    final text = _controller.text;
    final char = i < text.length ? text[i] : '';
    final isNextToFill = i == text.length && _focusNode.hasFocus;
    final isError = _status == _Status.error;
    final isSuccess = _status == _Status.success;

    Color borderColor = widget.border;
    if (isError) {
      borderColor = widget.error;
    } else if (isSuccess) {
      borderColor = widget.success;
    } else if (char.isNotEmpty || isNextToFill) {
      borderColor = widget.accent;
    }

    return SizedBox(
      width: widget.boxSize,
      height: widget.boxSize * 1.2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError ? widget.error.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width:
            char.isNotEmpty || isError || isSuccess || isNextToFill ? 1.6 : 1,
          ),
        ),
        child: Center(
          child: Text(
            char,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isError
                  ? widget.error
                  : (isSuccess ? widget.success : widget.textColor),
            ),
          ),
        ),
      ),
    );
  }
}