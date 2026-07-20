import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextpay/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _shareButtonKey = GlobalKey();
  File? _profileImage;

  static const _prefKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        setState(() => _profileImage = file);
      } else {
        await prefs.remove(_prefKey);
      }
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, path);
  }

  Future<void> _clearImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  Future<File> _persistImage(File tempFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final permanent = File('${appDir.path}/profile_photo.jpg');
    return tempFile.copy(permanent.path);
  }

  Future<void> _handleShare() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/offlinepay_qr.png');
      await file.writeAsBytes(imageBytes);

      // Get screen size for a safe center-screen anchor
      final size = MediaQuery.of(context).size;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.75),
        width: 200,
        height: 50,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan to pay me',
        sharePositionOrigin: rect,
      );
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;
      final permanent = await _persistImage(File(picked.path));
      await _saveImagePath(permanent.path);
      setState(() => _profileImage = permanent);
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> _removeImage() async {
    if (_profileImage != null) {
      try {
        if (await _profileImage!.exists()) await _profileImage!.delete();
      } catch (_) {}
    }
    await _clearImagePath();
    setState(() => _profileImage = null);
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();

    // Check locked balance
    final hasLockedBalance =
        (auth.user?.wallet?.lockedBalance ?? 0) > 0;

    // Check pending offline transactions
    final prefs = await SharedPreferences.getInstance();
    final key = "pending_transactions_${auth.user?.id}";
    final pending = prefs.getStringList(key) ?? [];

    final hasPendingTransactions = pending.isNotEmpty;

    if (hasLockedBalance || hasPendingTransactions) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please sync all offline payments before logging out.",
          ),
        ),
      );
      return;
    }

    await auth.logout();

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openPhotoViewer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _PhotoViewerScreen(image: _profileImage!),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _showImageSourceSheet(AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Change photo",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary),
              ),
            ),
            _sheetOption(
              c: c,
              icon: Icons.photo_library_outlined,
              label: "Choose from gallery",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _sheetOption(
              c: c,
              icon: Icons.camera_alt_outlined,
              label: "Take a photo",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImage != null)
              _sheetOption(
                c: c,
                icon: Icons.delete_outline_rounded,
                label: "Remove photo",
                color: c.dangerText,
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required AppColors c,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: effectiveColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    if (!auth.hydrated) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: CircularProgressIndicator(color: c.purple)),
      );
    }

    final user = auth.user;
    final userId = user?.id ?? "";
    final userName = user?.name.isNotEmpty == true ? user!.name : "User";
    final userEmail = user?.email ?? "";

    final initials = userName
        .split(" ")
        .where((n) => n.isNotEmpty)
        .map((n) => n[0])
        .join("")
        .toUpperCase();
    final initialsShort =
    initials.length > 2 ? initials.substring(0, 2) : initials;

    final qrValue = jsonEncode({"userId": userId, "receiverName": userName});

    String memberSince = "—";
    final createdAt = user?.extra['created_at'];
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        const months = [
          "Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ];
        memberSince = "${months[date.month - 1]} ${date.year}";
      } catch (_) {}
    }

    // QR code colours — always white background so QR is scannable
    const qrFg = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: c.textSecondary, size: 20),
                    ),
                  ),
                  Text(
                    "My profile",
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 40), // ← balances the back button
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    // ── AVATAR SECTION ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _profileImage != null
                                    ? _openPhotoViewer
                                    : () => _showImageSourceSheet(c),
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: c.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _profileImage != null
                                      ? Image.file(_profileImage!,
                                      fit: BoxFit.cover,
                                      width: 84,
                                      height: 84)
                                      : Center(
                                    child: Text(
                                      initialsShort,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showImageSourceSheet(c),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: c.purple,
                                      shape: BoxShape.circle,
                                      border:
                                      Border.all(color: c.bg, width: 2),
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userName,
                            style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          if (_profileImage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Tap photo to view",
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── QR CARD ───────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Scan to pay me",
                            style: TextStyle(
                                fontSize: 13, color: c.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          // QR always on white background for scannability
                          Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border, width: 1),
                              ),
                              child: QrImageView(
                                data: qrValue.isNotEmpty ? qrValue : "empty",
                                size: 200,
                                backgroundColor: Colors.white,
                                eyeStyle:
                                const QrEyeStyle(color: qrFg),
                                dataModuleStyle: const QrDataModuleStyle(
                                    color: qrFg),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              color: c.purpleLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              userName,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.purpleDark,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            key: _shareButtonKey,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: c.purple,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _handleShare,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.ios_share_rounded,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          "Share QR code",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── INFO CARD ─────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          _infoRow(c, "User name",
                              userId.isNotEmpty ? userName : "—"),
                          _infoDivider(c),
                          _infoRow(c, "Email",
                              userEmail.isNotEmpty ? userEmail : "—"),
                          _infoDivider(c),
                          _infoRow(
                              c, "User ID", userId.isNotEmpty ? userId : "—"),
                          _infoDivider(c),
                          _infoRow(c, "Member since", memberSince),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── LOGOUT ────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: c.dangerBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _handleLogout,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded,
                                    size: 18, color: c.dangerText),
                                const SizedBox(width: 8),
                                Text(
                                  "Log out",
                                  style: TextStyle(
                                      color: c.dangerText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "© 2025 Built by moinworksonlocalhost",
                      style:
                      TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(AppColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider(AppColors c) {
    return Container(
        height: 1,
        color: c.border,
        margin: const EdgeInsets.symmetric(horizontal: 18));
  }
}

// ── Full-screen photo viewer ─────────────────────────────────────────────────

class _PhotoViewerScreen extends StatelessWidget {
  final File image;
  const _PhotoViewerScreen({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(image, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: const Text(
              "Your photo",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}