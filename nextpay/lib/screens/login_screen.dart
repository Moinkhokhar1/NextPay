import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

// ── Design tokens (matches home_screen.dart) ───────────────────
const _bg = Color(0xFFF7F6F2);
const _surface = Colors.white;
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B68);
const _border = Color(0xFFE9E7E1);

const _purple = Color(0xFF534AB7);
const _purpleDark = Color(0xFF26215C);
const _purpleLight = Color(0xFFEEEDFE);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    final trimmed = phone.trim();
    return trimmed.startsWith('+') ? trimmed : '+91$trimmed';
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
      setState(() => _otpSent = true);
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
    final otp = _otpController.text.trim();

    if (phone.isEmpty || otp.isEmpty) {
      _showAlert("Error", "Enter mobile number and OTP");
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

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // BRAND
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          '../assets/icons/app_icon.png', // 👈 update this path
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "OfflinePay",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Secure offline payments",
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // FORM CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sign in with OTP",
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "We'll send a code to your mobile",
                            style:
                            TextStyle(fontSize: 13, color: _textSecondary),
                          ),
                          const SizedBox(height: 22),

                          // PHONE
                          _fieldLabel("Mobile number"),
                          _inputField(
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                            hint: "9876543210",
                            keyboardType: TextInputType.phone,
                            enabled: !_otpSent,
                          ),
                          const SizedBox(height: 16),

                          if (_otpSent) ...[
                            _fieldLabel("OTP"),
                            _inputField(
                              icon: Icons.sms_outlined,
                              controller: _otpController,
                              hint: "6-digit code",
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                  setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: const Text(
                                  "Change number",
                                  style: TextStyle(color: _purple),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LOGIN BUTTON
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading
                              ? null
                              : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _otpSent ? "Verify & sign in" : "Send OTP",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(color: _purple),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // DIVIDER
                    Row(
                      children: [
                        Expanded(
                            child: Divider(color: _border, thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "or",
                            style: TextStyle(
                                fontSize: 12, color: _textSecondary),
                          ),
                        ),
                        Expanded(
                            child: Divider(color: _border, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // REGISTER LINK
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Center(
                            child: Text(
                              "Create account",
                              style: TextStyle(
                                  color: _purpleDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "© 2025 Built by moinworksonlocalhost",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
      ),
    );
  }

  Widget _inputField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? trailing,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, size: 18, color: _textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              autocorrect: false,
              enabled: enabled,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _textSecondary),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
