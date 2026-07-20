import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../services/app_lock_service.dart';

const _pinLength = 6;

class SetPinScreen extends StatefulWidget {
  /// Called after the PIN has been successfully saved.
  final VoidCallback? onPinSet;

  const SetPinScreen({super.key, this.onPinSet});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0 = enter, 1 = confirm
  String _firstPin = '';
  String _currentInput = '';
  bool _saving = false;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_currentInput.length >= _pinLength || _saving) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentInput += digit;
      _errorMessage = null;
    });
    if (_currentInput.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 120), _onComplete);
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty || _saving) return;
    HapticFeedback.lightImpact();
    setState(() =>
    _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  void _onClear() {
    if (_saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _currentInput = '');
  }

  Future<void> _onComplete() async {
    if (_step == 0) {
      setState(() {
        _firstPin = _currentInput;
        _currentInput = '';
        _step = 1;
      });
    } else {
      if (_currentInput == _firstPin) {
        await _savePin(_currentInput);
      } else {
        _shake();
        setState(() {
          _currentInput = '';
          _errorMessage = "PINs don't match. Try again.";
        });
      }
    }
  }

  Future<void> _savePin(String pin) async {
    setState(() => _saving = true);
    try {
      await AppLockService.instance.setPin(pin);
      HapticFeedback.heavyImpact();
      if (mounted) widget.onPinSet?.call();
    } catch (e) {
      debugPrint('❌ PIN SAVE ERROR: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Could not save PIN. Please try again.';
          _currentInput = '';
        });
      }
    }
  }

  void _shake() {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);
  }

  void _goBack() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _firstPin = '';
        _currentInput = '';
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    final title = _step == 0 ? 'Set your PIN' : 'Confirm your PIN';
    final subtitle = _step == 0
        ? 'Choose a 6-digit PIN to lock the app'
        : 'Enter the same PIN again to confirm';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary)),
                      Text(subtitle,
                          style:
                          TextStyle(fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Step pill indicator ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _step;
                final done = i < _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done || active ? c.purple : c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // ── PIN dots ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _currentInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: filled ? 18 : 16,
                    height: filled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? c.purple : Colors.transparent,
                      border: Border.all(
                        color: filled ? c.purple : c.border,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ── Error ────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _errorMessage != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: c.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 14, color: c.dangerText),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.dangerText),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Numpad ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['clear', '0', 'back'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: row.map((key) {
                          if (key == 'back') {
                            return _IconKey(
                              icon: Icons.backspace_outlined,
                              onTap: _onBackspace,
                              onLongPress: _onClear,
                              c: c,
                            );
                          }
                          if (key == 'clear') {
                            return _TextKey(
                                label: 'CLR',
                                onTap: _onClear,
                                c: c,
                                muted: true);
                          }
                          return _DigitKey(
                              digit: key,
                              onTap: () => _onDigit(key),
                              c: c);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            if (_saving)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.purple),
                    ),
                    const SizedBox(width: 10),
                    Text('Saving…',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Key widgets (unchanged) ───────────────────────────────────────────────────

class _DigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  final AppColors c;
  const _DigitKey({required this.digit, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) => _KeyBase(
    onTap: onTap,
    c: c,
    child: Text(digit,
        style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: c.textPrimary)),
  );
}

class _TextKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppColors c;
  final bool muted;
  const _TextKey(
      {required this.label,
        required this.onTap,
        required this.c,
        this.muted = false});

  @override
  Widget build(BuildContext context) => _KeyBase(
    onTap: onTap,
    c: c,
    transparent: true,
    child: Text(label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: muted ? c.textSecondary : c.textPrimary)),
  );
}

class _IconKey extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final AppColors c;
  const _IconKey(
      {required this.icon,
        required this.onTap,
        this.onLongPress,
        required this.c});

  @override
  Widget build(BuildContext context) => _KeyBase(
    onTap: onTap,
    onLongPress: onLongPress,
    c: c,
    transparent: true,
    child: Icon(icon, size: 22, color: c.textPrimary),
  );
}

class _KeyBase extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final AppColors c;
  final bool transparent;
  const _KeyBase(
      {required this.child,
        required this.onTap,
        required this.c,
        this.onLongPress,
        this.transparent = false});

  @override
  State<_KeyBase> createState() => _KeyBaseState();
}

class _KeyBaseState extends State<_KeyBase> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 72,
        decoration: BoxDecoration(
          color: widget.transparent
              ? Colors.transparent
              : _pressed
              ? widget.c.purpleLight
              : widget.c.surface,
          borderRadius: BorderRadius.circular(16),
          border: widget.transparent
              ? null
              : Border.all(
              color: _pressed ? widget.c.purple : widget.c.border,
              width: 1),
          boxShadow: widget.transparent || _pressed
              ? null
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}