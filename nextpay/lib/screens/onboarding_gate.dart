import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import 'set_pin_screen.dart';
import 'biometric_prompt_screen.dart';
import 'lock_screen.dart';

/// Drop this widget around the signed-in part of the app (e.g. wrap
/// `HomeScreen` once `AuthProvider` has a user). It decides what to show
/// each time someone is signed in:
///
///   No PIN set yet  →  SetPinScreen → BiometricPromptScreen → [child]
///   PIN set         →  LockScreen → [child]
///
/// It should NOT wrap the login/register screens — PIN setup only makes
/// sense once someone actually has an account to protect.
///
/// Usage:
///
/// ```dart
/// if (auth.user != null) return OnboardingGate(child: const HomeScreen());
/// ```
class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  // null = still checking, true = go to child, false = still in gate flow
  bool? _ready;
  _GateStep _step = _GateStep.checking;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pinSet = await AppLockService.instance.isPinSet();
    if (!mounted) return;
    setState(() {
      _step = pinSet ? _GateStep.lock : _GateStep.setPin;
      _ready = false;
    });
  }

  void _onPinSet() => setState(() => _step = _GateStep.biometric);
  void _onBiometricDone() => setState(() => _ready = true);
  void _onUnlocked() => setState(() => _ready = true);

  @override
  Widget build(BuildContext context) {
    // Still checking storage
    if (_ready == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // All gates passed — show the app
    if (_ready == true) return widget.child;

    return switch (_step) {
      _GateStep.setPin => SetPinScreen(onPinSet: _onPinSet),
      _GateStep.biometric =>
          BiometricPromptScreen(onDone: _onBiometricDone),
      _GateStep.lock => LockScreen(onUnlocked: _onUnlocked),
      _GateStep.checking => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

enum _GateStep { checking, setPin, biometric, lock }