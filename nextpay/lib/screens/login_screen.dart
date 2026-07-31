import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../widgets/app_feedback.dart';

// ── Design tokens (matches home_screen.dart) ───────────────────
const _bg = Color(0xFFF7F6F2);
const _surface = Colors.white;
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B68);
const _border = Color(0xFFE9E7E1);

const _purple = Color(0xFF534AB7);
const _purpleDark = Color(0xFF26215C);
const _purpleLight = Color(0xFFEEEDFE);

const _otpLength = 6;
const _resendSeconds = 30;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  final List<TextEditingController> _otpControllers =
  List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(_otpLength, (_) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;

  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    final trimmed = phone.trim();
    return trimmed.startsWith('+') ? trimmed : '+91$trimmed';
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showAlert("Error", "Enter your mobile number");
      return;
    }

    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _showAlert("Error", "Enter a valid 10-digit mobile number");
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(_normalizePhone(phone));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() => _otpSent = true);
      _startResendTimer();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _otpFocusNodes[0].requestFocus());

      final devOtp = result["devOtp"];
      if (devOtp != null) {
        _showAlert("OTP sent (dev mode)", "Your OTP is: $devOtp");
      }
    } else {
      _showAlert("Error", result["message"] ?? "Failed to send OTP");
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpValue;

    if (phone.isEmpty || otp.length < _otpLength) {
      _showAlert("Error", "Enter the complete OTP");
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.loginWithOtp(_normalizePhone(phone), otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result["success"] != true) {
      _showAlert("Error", result["message"] ?? "Login failed");
    }
  }

  void _handleChangeNumber() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _secondsLeft = 0;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index + 1 < _otpLength) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
    if (_otpValue.length == _otpLength) {
      _handleVerifyOtp();
    }
  }

  void _showAlert(String title, String message) {
    final isError = title.toLowerCase().contains("error");
    AppDialog.show(
      context,
      title: title,
      message: message,
      type: isError ? AppDialogType.error : AppDialogType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _otpSent ? _buildOtpStep() : _buildPhoneStep(),
        ),
      ),
    );
  }

  // ── STEP 1: Phone number ─────────────────────────────────────
  Widget _buildPhoneStep() {
    return Padding(
      key: const ValueKey('phone-step'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Enter your Mobile Number\nto get OTP",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            "Mobile Number",
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Text("🇮🇳", style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        "+91",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 24, color: _border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      enabled: !_isLoading,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary),
                      decoration: const InputDecoration(
                        hintText: "9876543210",
                        hintStyle: TextStyle(color: _textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _primaryButton(
            label: "GET OTP",
            onTap: _handleSendOtp,
            loading: _isLoading,
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: _textSecondary),
              children: [
                const TextSpan(text: "By clicking, I accept the "),
                TextSpan(
                  text: "Terms & Conditions",
                  style: const TextStyle(
                      color: _purple, decoration: TextDecoration.underline),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy.",
                  style: const TextStyle(
                      color: _purple, decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("New here? ",
                  style: TextStyle(fontSize: 13, color: _textSecondary)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "Create account",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _purpleDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 2: OTP entry ────────────────────────────────────────
  Widget _buildOtpStep() {
    final phone = _phoneController.text.trim();
    return Padding(
      key: const ValueKey('otp-step'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _isLoading ? null : _handleChangeNumber,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _textPrimary),
            ),
          ),
          const SizedBox(height: 28),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.3,
              ),
              children: [
                const TextSpan(text: "Enter the OTP sent to\n"),
                TextSpan(text: "+91 $phone  "),
                TextSpan(
                  text: "(Change)",
                  style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (i) => _otpBox(i)),
          ),
          const SizedBox(height: 32),
          _primaryButton(
            label: "LOG IN",
            onTap: _handleVerifyOtp,
            loading: _isLoading,
            enabled: _otpValue.length == _otpLength,
          ),
          const SizedBox(height: 20),
          Center(
            child: _secondsLeft > 0
                ? Text(
              "Didn't receive the code? Retry in: ${_formatSeconds(_secondsLeft)}",
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            )
                : GestureDetector(
              onTap: _isLoading ? null : _handleSendOtp,
              child: const Text(
                "Didn't receive the code? Resend OTP",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _purple),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    final filled = _otpControllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: !_isLoading,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: _surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: filled ? _purple : _border,
                width: filled ? 1.5 : 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: filled ? _purple : _border,
                width: filled ? 1.5 : 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
        onChanged: (v) => _onOtpDigitChanged(index, v),
      ),
    );
  }

  String _formatSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
    bool enabled = true,
  }) {
    final active = enabled && !loading;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: active ? _purple : _purple.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: active ? onTap : null,
          child: Center(
            child: loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
