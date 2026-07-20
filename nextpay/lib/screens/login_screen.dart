// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import 'home_screen.dart';
// import 'register_screen.dart';
//
// const _bg = Color(0xFFF3EBDD);
// const _card = Color(0xFFEFE4D1);
// const _border = Color(0xFF111111);
// const _orange = Color(0xFFC85A1E);
// const _muted = Color(0xFF9A7A5A);
// const _dark = Color(0xFF1A0A00);
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _showPassword = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _handleLogin() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text;
//
//     if (email.isEmpty || password.isEmpty) {
//       _showAlert("Error", "All fields required");
//       return;
//     }
//
//     final auth = context.read<AuthProvider>();
//     final result = await auth.login(email, password);
//
//     if (!mounted) return;
//
//     if (result["success"] == true) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//             (route) => false,
//       );
//     } else {
//       _showAlert("Error", result["message"] ?? "Login failed");
//     }
//   }
//
//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     // BRAND
//                     Container(
//                       width: 72,
//                       height: 72,
//                       decoration: BoxDecoration(
//                         color: _orange,
//                         border: Border.all(color: _border, width: 3),
//                         boxShadow: const [
//                           BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
//                         ],
//                       ),
//                       alignment: Alignment.center,
//                       child: const Text(
//                         "OP",
//                         style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     const Text(
//                       "OFFLINEPAY",
//                       style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _orange, letterSpacing: 3),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       "SECURE OFFLINE PAYMENTS",
//                       style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _muted, letterSpacing: 2),
//                     ),
//                     const SizedBox(height: 36),
//
//                     // FORM CARD
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: _card,
//                         border: Border.all(color: _border, width: 3),
//                         boxShadow: const [
//                           BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Welcome back",
//                             style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _border),
//                           ),
//                           const SizedBox(height: 2),
//                           const Text(
//                             "Sign in to your account",
//                             style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7A6A5A)),
//                           ),
//                           const SizedBox(height: 20),
//
//                           // EMAIL
//                           _fieldLabel("EMAIL"),
//                           _inputField(
//                             icon: "@",
//                             controller: _emailController,
//                             hint: "you@email.com",
//                             keyboardType: TextInputType.emailAddress,
//                           ),
//                           const SizedBox(height: 16),
//
//                           // PASSWORD
//                           _fieldLabel("PASSWORD"),
//                           _inputField(
//                             icon: "🔒",
//                             controller: _passwordController,
//                             hint: "••••••••",
//                             obscure: !_showPassword,
//                             trailing: GestureDetector(
//                               onTap: () => setState(() => _showPassword = !_showPassword),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 14),
//                                 child: Text(_showPassword ? "🙈" : "👁", style: const TextStyle(fontSize: 16)),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // LOGIN BUTTON
//                     Container(
//                       width: double.infinity,
//                       height: 64,
//                       decoration: BoxDecoration(
//                         color: _orange,
//                         border: Border.all(color: _border, width: 3),
//                         boxShadow: const [
//                           BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
//                         ],
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           onTap: _handleLogin,
//                           child: const Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "SIGN IN",
//                                   style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
//                                 ),
//                                 SizedBox(width: 12),
//                                 Text(
//                                   "→",
//                                   style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // DIVIDER
//                     Row(
//                       children: const [
//                         Expanded(child: Divider(color: Color(0xFFC8B89A), thickness: 2)),
//                         SizedBox(width: 12),
//                         Text(
//                           "OR",
//                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 2),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(child: Divider(color: Color(0xFFC8B89A), thickness: 2)),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//
//                     // REGISTER LINK
//                     Container(
//                       width: double.infinity,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         color: _dark,
//                         border: Border.all(color: _border, width: 3),
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           onTap: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const RegisterScreen()),
//                           ),
//                           child: const Center(
//                             child: Text(
//                               "CREATE ACCOUNT",
//                               style: TextStyle(color: _bg, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.only(bottom: 20),
//               child: Text(
//                 "© 2025 Built by moinworksonlocalhost",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 1),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _fieldLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 2),
//       ),
//     );
//   }
//
//   Widget _inputField({
//     required String icon,
//     required TextEditingController controller,
//     required String hint,
//     bool obscure = false,
//     TextInputType? keyboardType,
//     Widget? trailing,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _bg,
//         border: Border.all(color: _border, width: 3),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 52,
//             decoration: const BoxDecoration(
//               color: _orange,
//               border: Border(right: BorderSide(color: _border, width: 3)),
//             ),
//             alignment: Alignment.center,
//             child: Text(icon, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
//           ),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               obscureText: obscure,
//               keyboardType: keyboardType,
//               autocorrect: false,
//               style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _border),
//               decoration: InputDecoration(
//                 hintText: hint,
//                 hintStyle: const TextStyle(color: _muted),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//               ),
//             ),
//           ),
//           if (trailing != null) trailing,
//         ],
//       ),
//     );
//   }
// }
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