// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nextpay/screens/login_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../providers/auth_provider.dart';
// import '../providers/theme_provider.dart';
// import '../app_colors.dart';
// import 'home_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final ScreenshotController _screenshotController = ScreenshotController();
//   final ImagePicker _imagePicker = ImagePicker();
//   final GlobalKey _shareButtonKey = GlobalKey();
//   File? _profileImage;
//
//   static const _prefKey = 'profile_image_path';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedImage();
//   }
//
//   Future<void> _loadSavedImage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final path = prefs.getString(_prefKey);
//     if (path != null) {
//       final file = File(path);
//       if (await file.exists()) {
//         setState(() => _profileImage = file);
//       } else {
//         await prefs.remove(_prefKey);
//       }
//     }
//   }
//
//   Future<void> _saveImagePath(String path) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_prefKey, path);
//   }
//
//   Future<void> _clearImagePath() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_prefKey);
//   }
//
//   Future<File> _persistImage(File tempFile) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final permanent = File('${appDir.path}/profile_photo.jpg');
//     return tempFile.copy(permanent.path);
//   }
//
//   Future<void> _handleShare() async {
//     try {
//       final imageBytes = await _screenshotController.capture();
//       if (imageBytes == null) return;
//       final dir = await getTemporaryDirectory();
//       final file = File('${dir.path}/offlinepay_qr.png');
//       await file.writeAsBytes(imageBytes);
//
//       // Get screen size for a safe center-screen anchor
//       final size = MediaQuery.of(context).size;
//       final rect = Rect.fromCenter(
//         center: Offset(size.width / 2, size.height * 0.75),
//         width: 200,
//         height: 50,
//       );
//
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         text: 'Scan to pay me',
//         sharePositionOrigin: rect,
//       );
//     } catch (e) {
//       debugPrint("Share error: $e");
//     }
//   }
//
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? picked = await _imagePicker.pickImage(
//         source: source,
//         imageQuality: 85,
//         maxWidth: 512,
//         maxHeight: 512,
//       );
//       if (picked == null) return;
//       final permanent = await _persistImage(File(picked.path));
//       await _saveImagePath(permanent.path);
//       setState(() => _profileImage = permanent);
//     } catch (e) {
//       debugPrint("Image pick error: $e");
//     }
//   }
//
//   Future<void> _removeImage() async {
//     if (_profileImage != null) {
//       try {
//         if (await _profileImage!.exists()) await _profileImage!.delete();
//       } catch (_) {}
//     }
//     await _clearImagePath();
//     setState(() => _profileImage = null);
//   }
//
//   Future<void> _handleLogout() async {
//     final auth = context.read<AuthProvider>();
//
//     // Check locked balance
//     final hasLockedBalance =
//         (auth.user?.wallet?.lockedBalance ?? 0) > 0;
//
//     // Check pending offline transactions
//     final prefs = await SharedPreferences.getInstance();
//     final key = "pending_transactions_${auth.user?.id}";
//     final pending = prefs.getStringList(key) ?? [];
//
//     final hasPendingTransactions = pending.isNotEmpty;
//
//     if (hasLockedBalance || hasPendingTransactions) {
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Please sync all offline payments before logging out.",
//           ),
//         ),
//       );
//       return;
//     }
//
//     await auth.logout();
//
//     if (!mounted) return;
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   }
//
//   void _openPhotoViewer() {
//     Navigator.of(context).push(
//       PageRouteBuilder(
//         opaque: false,
//         barrierColor: Colors.black,
//         pageBuilder: (_, __, ___) => _PhotoViewerScreen(image: _profileImage!),
//         transitionsBuilder: (_, animation, __, child) =>
//             FadeTransition(opacity: animation, child: child),
//       ),
//     );
//   }
//
//   void _showImageSourceSheet(AppColors c) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: c.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 8),
//             Container(
//               width: 36,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: c.border,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               child: Text(
//                 "Change photo",
//                 style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: c.textPrimary),
//               ),
//             ),
//             _sheetOption(
//               c: c,
//               icon: Icons.photo_library_outlined,
//               label: "Choose from gallery",
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//             _sheetOption(
//               c: c,
//               icon: Icons.camera_alt_outlined,
//               label: "Take a photo",
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//             if (_profileImage != null)
//               _sheetOption(
//                 c: c,
//                 icon: Icons.delete_outline_rounded,
//                 label: "Remove photo",
//                 color: c.dangerText,
//                 onTap: () {
//                   Navigator.pop(context);
//                   _removeImage();
//                 },
//               ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _sheetOption({
//     required AppColors c,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     final effectiveColor = color ?? c.textPrimary;
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
//         child: Row(
//           children: [
//             Icon(icon, color: effectiveColor, size: 20),
//             const SizedBox(width: 14),
//             Text(
//               label,
//               style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: effectiveColor),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final theme = context.watch<ThemeProvider>();
//     final c = AppColors(isDark: theme.isDark);
//
//     if (!auth.hydrated) {
//       return Scaffold(
//         backgroundColor: c.bg,
//         body: Center(child: CircularProgressIndicator(color: c.purple)),
//       );
//     }
//
//     final user = auth.user;
//     final userId = user?.id ?? "";
//     final userName = user?.name.isNotEmpty == true ? user!.name : "User";
//     final userEmail = user?.email ?? "";
//
//     final initials = userName
//         .split(" ")
//         .where((n) => n.isNotEmpty)
//         .map((n) => n[0])
//         .join("")
//         .toUpperCase();
//     final initialsShort =
//     initials.length > 2 ? initials.substring(0, 2) : initials;
//
//     final qrValue = jsonEncode({"userId": userId, "receiverName": userName});
//
//     String memberSince = "—";
//     final createdAt = user?.extra['created_at'];
//     if (createdAt != null) {
//       try {
//         final date = DateTime.parse(createdAt.toString());
//         const months = [
//           "Jan", "Feb", "Mar", "Apr", "May", "Jun",
//           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
//         ];
//         memberSince = "${months[date.month - 1]} ${date.year}";
//       } catch (_) {}
//     }
//
//     // QR code colours — always white background so QR is scannable
//     const qrFg = Color(0xFF1A1A1A);
//
//     return Scaffold(
//       backgroundColor: c.bg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ── HEADER ───────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (_) => const HomeScreen()),
//                     ),
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: c.surface,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: c.border, width: 1),
//                       ),
//                       child: Icon(Icons.arrow_back_rounded,
//                           color: c.textSecondary, size: 20),
//                     ),
//                   ),
//                   Text(
//                     "My profile",
//                     style: TextStyle(
//                         color: c.textPrimary,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(width: 40), // ← balances the back button
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.only(bottom: 32),
//                 child: Column(
//                   children: [
//                     // ── AVATAR SECTION ───────────────────────────────
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       child: Column(
//                         children: [
//                           Stack(
//                             children: [
//                               GestureDetector(
//                                 onTap: _profileImage != null
//                                     ? _openPhotoViewer
//                                     : () => _showImageSourceSheet(c),
//                                 child: Container(
//                                   width: 84,
//                                   height: 84,
//                                   decoration: BoxDecoration(
//                                     color: c.purple,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   clipBehavior: Clip.antiAlias,
//                                   child: _profileImage != null
//                                       ? Image.file(_profileImage!,
//                                       fit: BoxFit.cover,
//                                       width: 84,
//                                       height: 84)
//                                       : Center(
//                                     child: Text(
//                                       initialsShort,
//                                       style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 26,
//                                           fontWeight: FontWeight.w600),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 bottom: 0,
//                                 right: 0,
//                                 child: GestureDetector(
//                                   onTap: () => _showImageSourceSheet(c),
//                                   child: Container(
//                                     width: 28,
//                                     height: 28,
//                                     decoration: BoxDecoration(
//                                       color: c.purple,
//                                       shape: BoxShape.circle,
//                                       border:
//                                       Border.all(color: c.bg, width: 2),
//                                     ),
//                                     child: const Icon(
//                                         Icons.camera_alt_rounded,
//                                         color: Colors.white,
//                                         size: 13),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             userName,
//                             style: TextStyle(
//                                 color: c.textPrimary,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600),
//                           ),
//                           if (_profileImage != null) ...[
//                             const SizedBox(height: 4),
//                             Text(
//                               "Tap photo to view",
//                               style: TextStyle(
//                                   color: c.textSecondary, fontSize: 12),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//
//                     // ── QR CARD ───────────────────────────────────────
//                     Container(
//                       margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                       padding: const EdgeInsets.all(22),
//                       decoration: BoxDecoration(
//                         color: c.surface,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: c.border, width: 1),
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             "Scan to pay me",
//                             style: TextStyle(
//                                 fontSize: 13, color: c.textSecondary),
//                           ),
//                           const SizedBox(height: 16),
//                           // QR always on white background for scannability
//                           Screenshot(
//                             controller: _screenshotController,
//                             child: Container(
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(color: c.border, width: 1),
//                               ),
//                               child: QrImageView(
//                                 data: qrValue.isNotEmpty ? qrValue : "empty",
//                                 size: 200,
//                                 backgroundColor: Colors.white,
//                                 eyeStyle:
//                                 const QrEyeStyle(color: qrFg),
//                                 dataModuleStyle: const QrDataModuleStyle(
//                                     color: qrFg),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                                 vertical: 10, horizontal: 20),
//                             decoration: BoxDecoration(
//                               color: c.purpleLight,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             alignment: Alignment.center,
//                             child: Text(
//                               userName,
//                               style: TextStyle(
//                                   fontFamily: 'monospace',
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                   color: c.purpleDark,
//                                   letterSpacing: 0.5),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Container(
//                             key: _shareButtonKey,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: c.purple,
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Material(
//                               color: Colors.transparent,
//                               borderRadius: BorderRadius.circular(16),
//                               child: InkWell(
//                                 borderRadius: BorderRadius.circular(16),
//                                 onTap: _handleShare,
//                                 child: const Padding(
//                                   padding: EdgeInsets.symmetric(vertical: 15),
//                                   child: Center(
//                                     child: Row(
//                                       mainAxisAlignment:
//                                       MainAxisAlignment.center,
//                                       children: [
//                                         Icon(Icons.ios_share_rounded,
//                                             color: Colors.white, size: 16),
//                                         SizedBox(width: 8),
//                                         Text(
//                                           "Share QR code",
//                                           style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 14),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // ── INFO CARD ─────────────────────────────────────
//                     Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: c.surface,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: c.border, width: 1),
//                       ),
//                       child: Column(
//                         children: [
//                           _infoRow(c, "User name",
//                               userId.isNotEmpty ? userName : "—"),
//                           _infoDivider(c),
//                           _infoRow(c, "Email",
//                               userEmail.isNotEmpty ? userEmail : "—"),
//                           _infoDivider(c),
//                           _infoRow(
//                               c, "User ID", userId.isNotEmpty ? userId : "—"),
//                           _infoDivider(c),
//                           _infoRow(c, "Member since", memberSince),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // ── LOGOUT ────────────────────────────────────────
//                     Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: c.dangerBg,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         borderRadius: BorderRadius.circular(16),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(16),
//                           onTap: _handleLogout,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.logout_rounded,
//                                     size: 18, color: c.dangerText),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "Log out",
//                                   style: TextStyle(
//                                       color: c.dangerText,
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//                     Text(
//                       "© 2025 Built by moinworksonlocalhost",
//                       style:
//                       TextStyle(fontSize: 11, color: c.textSecondary),
//                     ),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _infoRow(AppColors c, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(fontSize: 13, color: c.textSecondary)),
//           Flexible(
//             child: Text(
//               value,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: c.textPrimary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoDivider(AppColors c) {
//     return Container(
//         height: 1,
//         color: c.border,
//         margin: const EdgeInsets.symmetric(horizontal: 18));
//   }
// }
//
// // ── Full-screen photo viewer ─────────────────────────────────────────────────
//
// class _PhotoViewerScreen extends StatelessWidget {
//   final File image;
//   const _PhotoViewerScreen({required this.image});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Center(
//             child: InteractiveViewer(
//               minScale: 0.5,
//               maxScale: 4.0,
//               child: Image.file(image, fit: BoxFit.contain),
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 12,
//             left: 16,
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.close_rounded,
//                     color: Colors.white, size: 20),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: MediaQuery.of(context).padding.bottom + 24,
//             left: 0,
//             right: 0,
//             child: const Text(
//               "Your photo",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.white54, fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:nextpay/screens/login_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../providers/auth_provider.dart';
// import '../providers/theme_provider.dart';
// import '../app_colors.dart';
// import 'home_screen.dart';
// import 'scanner_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final ScreenshotController _screenshotController = ScreenshotController();
//   final ImagePicker _imagePicker = ImagePicker();
//   File? _profileImage;
//
//   static const _prefKey = 'profile_image_path';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedImage();
//   }
//
//   // ── Persistence / image handling (unchanged logic) ─────────────────────
//
//   Future<void> _loadSavedImage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final path = prefs.getString(_prefKey);
//     if (path != null) {
//       final file = File(path);
//       if (await file.exists()) {
//         setState(() => _profileImage = file);
//       } else {
//         await prefs.remove(_prefKey);
//       }
//     }
//   }
//
//   Future<void> _saveImagePath(String path) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_prefKey, path);
//   }
//
//   Future<void> _clearImagePath() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_prefKey);
//   }
//
//   Future<File> _persistImage(File tempFile) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final permanent = File('${appDir.path}/profile_photo.jpg');
//     return tempFile.copy(permanent.path);
//   }
//
//   Future<void> _handleShare() async {
//     try {
//       final imageBytes = await _screenshotController.capture();
//       if (imageBytes == null) return;
//       final dir = await getTemporaryDirectory();
//       final file = File('${dir.path}/offlinepay_qr.png');
//       await file.writeAsBytes(imageBytes);
//
//       final size = MediaQuery.of(context).size;
//       final rect = Rect.fromCenter(
//         center: Offset(size.width / 2, size.height * 0.75),
//         width: 200,
//         height: 50,
//       );
//
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         text: 'Scan to pay me',
//         sharePositionOrigin: rect,
//       );
//     } catch (e) {
//       debugPrint("Share error: $e");
//     }
//   }
//
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? picked = await _imagePicker.pickImage(
//         source: source,
//         imageQuality: 85,
//         maxWidth: 512,
//         maxHeight: 512,
//       );
//       if (picked == null) return;
//       final permanent = await _persistImage(File(picked.path));
//       await _saveImagePath(permanent.path);
//       setState(() => _profileImage = permanent);
//     } catch (e) {
//       debugPrint("Image pick error: $e");
//     }
//   }
//
//   Future<void> _removeImage() async {
//     if (_profileImage != null) {
//       try {
//         if (await _profileImage!.exists()) await _profileImage!.delete();
//       } catch (_) {}
//     }
//     await _clearImagePath();
//     setState(() => _profileImage = null);
//   }
//
//   Future<void> _handleLogout() async {
//     final auth = context.read<AuthProvider>();
//
//     final hasLockedBalance = (auth.user?.wallet?.lockedBalance ?? 0) > 0;
//
//     final prefs = await SharedPreferences.getInstance();
//     final key = "pending_transactions_${auth.user?.id}";
//     final pending = prefs.getStringList(key) ?? [];
//     final hasPendingTransactions = pending.isNotEmpty;
//
//     if (hasLockedBalance || hasPendingTransactions) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please sync all offline payments before logging out."),
//         ),
//       );
//       return;
//     }
//
//     await auth.logout();
//
//     if (!mounted) return;
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   }
//
//   void _openPhotoViewer() {
//     Navigator.of(context).push(
//       PageRouteBuilder(
//         opaque: false,
//         barrierColor: Colors.black,
//         pageBuilder: (_, __, ___) => _PhotoViewerScreen(image: _profileImage!),
//         transitionsBuilder: (_, animation, __, child) =>
//             FadeTransition(opacity: animation, child: child),
//       ),
//     );
//   }
//
//   void _copyToClipboard(String value, String label) {
//     Clipboard.setData(ClipboardData(text: value));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("$label copied"), duration: const Duration(seconds: 1)),
//     );
//   }
//
//   // ── Bottom sheets ────────────────────────────────────────────────────
//
//   void _showImageSourceSheet(AppColors c) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: c.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 8),
//             Container(
//               width: 36,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: c.border,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               child: Text(
//                 "Change photo",
//                 style: TextStyle(
//                     fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
//               ),
//             ),
//             _sheetOption(
//               c: c,
//               icon: Icons.photo_library_outlined,
//               label: "Choose from gallery",
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//             _sheetOption(
//               c: c,
//               icon: Icons.camera_alt_outlined,
//               label: "Take a photo",
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//             if (_profileImage != null)
//               _sheetOption(
//                 c: c,
//                 icon: Icons.delete_outline_rounded,
//                 label: "Remove photo",
//                 color: c.dangerText,
//                 onTap: () {
//                   Navigator.pop(context);
//                   _removeImage();
//                 },
//               ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _openQrScreen(AppColors c, String qrValue, String userName, String userId) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => _QrCodeScreen(
//           screenshotController: _screenshotController,
//           profileImage: _profileImage,
//           userName: userName,
//           userId: userId,
//           qrValue: qrValue,
//           onShare: _handleShare,
//         ),
//       ),
//     );
//   }
//
//   void _showAccountInfoSheet(
//       AppColors c, String userName, String userEmail, String userId, String memberSince) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: c.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 36,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: c.border,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Text(
//                   "Account details",
//                   style: TextStyle(
//                       fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
//                 ),
//               ),
//               _infoRow(c, "User name", userName),
//               _infoDivider(c),
//               _infoRow(c, "Email", userEmail.isNotEmpty ? userEmail : "—"),
//               _infoDivider(c),
//               _infoRow(c, "User ID", userId.isNotEmpty ? userId : "—"),
//               _infoDivider(c),
//               _infoRow(c, "Member since", memberSince),
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _sheetOption({
//     required AppColors c,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     final effectiveColor = color ?? c.textPrimary;
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
//         child: Row(
//           children: [
//             Icon(icon, color: effectiveColor, size: 20),
//             const SizedBox(width: 14),
//             Text(
//               label,
//               style: TextStyle(
//                   fontSize: 14, fontWeight: FontWeight.w500, color: effectiveColor),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ── Build ────────────────────────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final theme = context.watch<ThemeProvider>();
//     final c = AppColors(isDark: theme.isDark);
//
//     if (!auth.hydrated) {
//       return Scaffold(
//         backgroundColor: c.bg,
//         body: Center(child: CircularProgressIndicator(color: c.purple)),
//       );
//     }
//
//     final user = auth.user;
//     final userId = user?.id ?? "";
//     final userName = user?.name.isNotEmpty == true ? user!.name : "User";
//     final userEmail = user?.email ?? "";
//
//     final initials = userName
//         .split(" ")
//         .where((n) => n.isNotEmpty)
//         .map((n) => n[0])
//         .join("")
//         .toUpperCase();
//     final initialsShort = initials.length > 2 ? initials.substring(0, 2) : initials;
//
//     final qrValue = jsonEncode({"userId": userId, "receiverName": userName});
//     final walletBalance = user?.wallet?.balance ?? 0;
//     final lockedBalance = user?.wallet?.lockedBalance ?? 0;
//
//     String memberSince = "—";
//     final createdAt = user?.extra['created_at'];
//     if (createdAt != null) {
//       try {
//         final date = DateTime.parse(createdAt.toString());
//         const months = [
//           "Jan", "Feb", "Mar", "Apr", "May", "Jun",
//           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
//         ];
//         memberSince = "${months[date.month - 1]} ${date.year}";
//       } catch (_) {}
//     }
//
//     return Scaffold(
//       backgroundColor: c.bg,
//       body: Stack(
//         children: [
//           // ── HERO BACKGROUND ─────────────────────────────────────────
//           Container(
//             height: 300,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   c.purple.withOpacity(0.55),
//                   c.purple.withOpacity(0.18),
//                   c.bg,
//                 ],
//               ),
//             ),
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Positioned(
//                   top: -40,
//                   right: -30,
//                   child: Container(
//                     width: 160,
//                     height: 160,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white.withOpacity(0.05),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 60,
//                   left: -50,
//                   child: Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white.withOpacity(0.04),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // ── FOREGROUND CONTENT ───────────────────────────────────────
//           SafeArea(
//             child: Column(
//               children: [
//                 // Top bar
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(builder: (_) => const HomeScreen()),
//                         ),
//                         child: Container(
//                           width: 38,
//                           height: 38,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.10),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(Icons.arrow_back_rounded,
//                               color: Colors.white, size: 20),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Name + avatar row
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               userName,
//                               style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 26,
//                                   fontWeight: FontWeight.w700),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               "User ID",
//                               style: TextStyle(
//                                   color: Colors.white.withOpacity(0.6), fontSize: 12),
//                             ),
//                             const SizedBox(height: 4),
//                             GestureDetector(
//                               onTap: userId.isNotEmpty
//                                   ? () => _copyToClipboard(userId, "User ID")
//                                   : null,
//                               child: Row(
//                                 children: [
//                                   Flexible(
//                                     child: Text(
//                                       userId.isNotEmpty ? userId : "—",
//                                       style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w600),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                   if (userId.isNotEmpty) ...[
//                                     const SizedBox(width: 6),
//                                     Icon(Icons.copy_rounded,
//                                         size: 14, color: Colors.white.withOpacity(0.6)),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Stack(
//                         clipBehavior: Clip.none,
//                         children: [
//                           GestureDetector(
//                             onTap: _profileImage != null
//                                 ? _openPhotoViewer
//                                 : () => _showImageSourceSheet(c),
//                             child: Container(
//                               width: 76,
//                               height: 76,
//                               decoration: BoxDecoration(
//                                 color: c.purple,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(color: Colors.white, width: 2),
//                               ),
//                               clipBehavior: Clip.antiAlias,
//                               child: _profileImage != null
//                                   ? Image.file(_profileImage!,
//                                   fit: BoxFit.cover, width: 76, height: 76)
//                                   : Center(
//                                 child: Text(
//                                   initialsShort,
//                                   style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             bottom: -2,
//                             right: -2,
//                             child: GestureDetector(
//                               onTap: () => _showImageSourceSheet(c),
//                               child: Container(
//                                 width: 26,
//                                 height: 26,
//                                 decoration: BoxDecoration(
//                                   color: c.purple,
//                                   shape: BoxShape.circle,
//                                   border: Border.all(color: c.bg, width: 2),
//                                 ),
//                                 child: const Icon(Icons.camera_alt_rounded,
//                                     color: Colors.white, size: 12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 22),
//
//                 // Scrollable content on solid background
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.only(bottom: 32),
//                     child: Column(
//                       children: [
//                         // ── QUICK STAT PILLS ─────────────────────────
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: _pillCard(
//                                   c: c,
//                                   color: c.purpleLight,
//                                   textColor: c.purpleDark,
//                                   icon: Icons.account_balance_wallet_rounded,
//                                   title: "₹${walletBalance.toStringAsFixed(0)}",
//                                   subtitle: "Wallet balance",
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _pillCard(
//                                   c: c,
//                                   color: c.surface,
//                                   textColor: c.textPrimary,
//                                   icon: Icons.lock_clock_rounded,
//                                   title: "₹${lockedBalance.toStringAsFixed(0)}",
//                                   subtitle: "Locked balance",
//                                   bordered: true,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // ── ACTION LIST ───────────────────────────────
//                         Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: c.surface,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: c.border, width: 1),
//                           ),
//                           child: Column(
//                             children: [
//                               _listRow(
//                                 c: c,
//                                 icon: Icons.qr_code_2_rounded,
//                                 title: "Your QR code",
//                                 subtitle: "Use to receive money from any UPI app",
//                                 onTap: () => _openQrScreen(c, qrValue, userName, userId),
//                               ),
//                               _infoDivider(c),
//                               _listRow(
//                                 c: c,
//                                 icon: Icons.badge_outlined,
//                                 title: "Account details",
//                                 subtitle: "Name, email, member since",
//                                 onTap: () => _showAccountInfoSheet(
//                                     c, userName, userEmail, userId, memberSince),
//                               ),
//                               _infoDivider(c),
//                               _listRow(
//                                 c: c,
//                                 icon: Icons.ios_share_rounded,
//                                 title: "Share QR code",
//                                 subtitle: "Send your code to someone",
//                                 onTap: _handleShare,
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // ── LOGOUT ─────────────────────────────────────
//                         Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: c.dangerBg,
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Material(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.circular(16),
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(16),
//                               onTap: _handleLogout,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(Icons.logout_rounded,
//                                         size: 18, color: c.dangerText),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       "Log out",
//                                       style: TextStyle(
//                                           color: c.dangerText,
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(height: 20),
//                         Text(
//                           "© 2025 Built by moinworksonlocalhost",
//                           style: TextStyle(fontSize: 11, color: c.textSecondary),
//                         ),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _pillCard({
//     required AppColors c,
//     required Color color,
//     required Color textColor,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     bool bordered = false,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(18),
//         border: bordered ? Border.all(color: c.border, width: 1) : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: textColor, size: 20),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             subtitle,
//             style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _listRow({
//     required AppColors c,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: c.purpleLight,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: c.purpleDark, size: 20),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(fontSize: 12, color: c.textSecondary),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _infoRow(AppColors c, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
//           Flexible(
//             child: Text(
//               value,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                   fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoDivider(AppColors c) {
//     return Container(
//         height: 1, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 18));
//   }
// }
//
// // ── Full-screen photo viewer ─────────────────────────────────────────────
//
// class _PhotoViewerScreen extends StatelessWidget {
//   final File image;
//   const _PhotoViewerScreen({required this.image});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Center(
//             child: InteractiveViewer(
//               minScale: 0.5,
//               maxScale: 4.0,
//               child: Image.file(image, fit: BoxFit.contain),
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 12,
//             left: 16,
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: MediaQuery.of(context).padding.bottom + 24,
//             left: 0,
//             right: 0,
//             child: const Text(
//               "Your photo",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.white54, fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Full-screen QR code view ─────────────────────────────────────────────
//
// class _QrCodeScreen extends StatelessWidget {
//   final ScreenshotController screenshotController;
//   final File? profileImage;
//   final String userName;
//   final String userId;
//   final String qrValue;
//   final VoidCallback onShare;
//
//   const _QrCodeScreen({
//     required this.screenshotController,
//     required this.profileImage,
//     required this.userName,
//     required this.userId,
//     required this.qrValue,
//     required this.onShare,
//   });
//
//   Future<void> _handleDownload(BuildContext context) async {
//     try {
//       final imageBytes = await screenshotController.capture();
//       if (imageBytes == null) return;
//       final dir = await getApplicationDocumentsDirectory();
//       final file = File('${dir.path}/nextpay_qr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await file.writeAsBytes(imageBytes);
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("QR code saved"), duration: Duration(seconds: 1)),
//       );
//     } catch (e) {
//       debugPrint("Download error: $e");
//     }
//   }
//
//   void _copyId(BuildContext context) {
//     Clipboard.setData(ClipboardData(text: userId));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("User ID copied"), duration: Duration(seconds: 1)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = context.watch<ThemeProvider>();
//     final c = AppColors(isDark: theme.isDark);
//     const qrFg = Color(0xFF1A1A1A);
//
//     final initials = userName
//         .split(" ")
//         .where((n) => n.isNotEmpty)
//         .map((n) => n[0])
//         .join("")
//         .toUpperCase();
//     final initialsShort = initials.length > 2 ? initials.substring(0, 2) : initials;
//
//     return Scaffold(
//       backgroundColor: c.bg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
//                   ),
//                   Row(
//                     children: [
//                       IconButton(
//                         onPressed: () => _handleDownload(context),
//                         icon: Icon(Icons.download_rounded, color: c.textPrimary),
//                       ),
//                       IconButton(
//                         onPressed: onShare,
//                         icon: Icon(Icons.ios_share_rounded, color: c.textPrimary),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
//                 child: Column(
//                   children: [
//                     // ── QR CARD ─────────────────────────────────────
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//                       decoration: BoxDecoration(
//                         color: c.surface,
//                         borderRadius: BorderRadius.circular(24),
//                         border: Border.all(color: c.border, width: 1),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 width: 44,
//                                 height: 44,
//                                 decoration: BoxDecoration(
//                                   color: c.purple,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 clipBehavior: Clip.antiAlias,
//                                 child: profileImage != null
//                                     ? Image.file(profileImage!, fit: BoxFit.cover)
//                                     : Center(
//                                   child: Text(
//                                     initialsShort,
//                                     style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 14),
//                               Expanded(
//                                 child: Text(
//                                   userName,
//                                   style: TextStyle(
//                                       color: c.textPrimary,
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.w600),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 24),
//                           Screenshot(
//                             controller: screenshotController,
//                             child: Container(
//                               padding: const EdgeInsets.all(16),
//                               color: Colors.white,
//                               child: Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   QrImageView(
//                                     data: qrValue.isNotEmpty ? qrValue : "empty",
//                                     size: 220,
//                                     backgroundColor: Colors.white,
//                                     eyeStyle: const QrEyeStyle(color: qrFg),
//                                     dataModuleStyle: const QrDataModuleStyle(color: qrFg),
//                                   ),
//                                   Container(
//                                     width: 46,
//                                     height: 46,
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       shape: BoxShape.circle,
//                                       border: Border.all(color: c.border, width: 1),
//                                     ),
//                                     child: Center(
//                                       child: Container(
//                                         width: 30,
//                                         height: 30,
//                                         decoration: BoxDecoration(
//                                           color: c.purple,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: const Icon(Icons.bolt_rounded,
//                                             color: Colors.white, size: 18),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           Text(
//                             "Scan to pay with NextPay app",
//                             style: TextStyle(fontSize: 13, color: c.textSecondary),
//                           ),
//                           const SizedBox(height: 20),
//                           Container(height: 1, color: c.border),
//                           const SizedBox(height: 16),
//                           GestureDetector(
//                             onTap: userId.isNotEmpty ? () => _copyId(context) : null,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Flexible(
//                                   child: Text(
//                                     "User ID: $userId",
//                                     style: TextStyle(
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.w600,
//                                         color: c.textPrimary),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                                 if (userId.isNotEmpty) ...[
//                                   const SizedBox(width: 8),
//                                   Icon(Icons.copy_rounded, size: 15, color: c.textSecondary),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 28),
//
//                     // ── SHARE BUTTON ───────────────────────────────────
//                     SizedBox(
//                       width: double.infinity,
//                       child: DecoratedBox(
//                         decoration: BoxDecoration(
//                           color: c.purpleLight,
//                           borderRadius: BorderRadius.circular(28),
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           borderRadius: BorderRadius.circular(28),
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(28),
//                             onTap: onShare,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.ios_share_rounded,
//                                       color: c.purpleDark, size: 18),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     "Share QR code",
//                                     style: TextStyle(
//                                         color: c.purpleDark,
//                                         fontWeight: FontWeight.w700,
//                                         fontSize: 15),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 12),
//
//                     // ── SCANNER BUTTON (hook up to your scan screen) ───
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(builder: (_) => const ScannerScreen()),
//                           );
//                         },
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           side: BorderSide(color: c.border),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(28),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.qr_code_scanner_rounded,
//                                 color: c.textPrimary, size: 18),
//                             const SizedBox(width: 8),
//                             Text(
//                               "Open scanner",
//                               style: TextStyle(
//                                   color: c.textPrimary,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 15),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 28),
//                     Text(
//                       "Powered by NextPay",
//                       style: TextStyle(fontSize: 11, color: c.textSecondary),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;

  static const _prefKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  // ── Persistence / image handling (unchanged logic) ─────────────────────

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

    final hasLockedBalance = (auth.user?.wallet?.lockedBalance ?? 0) > 0;

    final prefs = await SharedPreferences.getInstance();
    final key = "pending_transactions_${auth.user?.id}";
    final pending = prefs.getStringList(key) ?? [];
    final hasPendingTransactions = pending.isNotEmpty;

    if (hasLockedBalance || hasPendingTransactions) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sync all offline payments before logging out."),
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

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied"), duration: const Duration(seconds: 1)),
    );
  }

  // ── Bottom sheets ────────────────────────────────────────────────────

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
                    fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
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

  void _openQrScreen(AppColors c, String qrValue, String userName, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QrCodeScreen(
          screenshotController: _screenshotController,
          profileImage: _profileImage,
          userName: userName,
          userId: userId,
          qrValue: qrValue,
          onShare: _handleShare,
        ),
      ),
    );
  }

  void _showAccountInfoSheet(
      AppColors c, String userName, String userEmail, String userId, String memberSince) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  "Account details",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
              ),
              _infoRow(c, "User name", userName),
              _infoDivider(c),
              _infoRow(c, "Email", userEmail.isNotEmpty ? userEmail : "—"),
              _infoDivider(c),
              _infoRow(c, "User ID", userId.isNotEmpty ? userId : "—"),
              _infoDivider(c),
              _infoRow(c, "Member since", memberSince),
              const SizedBox(height: 8),
            ],
          ),
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
                  fontSize: 14, fontWeight: FontWeight.w500, color: effectiveColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

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
    final initialsShort = initials.length > 2 ? initials.substring(0, 2) : initials;

    final qrValue = jsonEncode({"userId": userId, "receiverName": userName});
    final walletBalance = user?.wallet?.balance ?? 0;
    final lockedBalance = user?.wallet?.lockedBalance ?? 0;

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

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // ── HERO BACKGROUND ─────────────────────────────────────────
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.purple.withOpacity(0.55),
                  c.purple.withOpacity(0.18),
                  c.bg,
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: -50,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FOREGROUND CONTENT ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Name + avatar row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "User ID",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6), fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: userId.isNotEmpty
                                  ? () => _copyToClipboard(userId, "User ID")
                                  : null,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userId.isNotEmpty ? userId : "—",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (userId.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.copy_rounded,
                                        size: 14, color: Colors.white.withOpacity(0.6)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: _profileImage != null
                                ? _openPhotoViewer
                                : () => _showImageSourceSheet(c),
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: c.purple,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _profileImage != null
                                  ? Image.file(_profileImage!,
                                  fit: BoxFit.cover, width: 76, height: 76)
                                  : Center(
                                child: Text(
                                  initialsShort,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: () => _showImageSourceSheet(c),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: c.purple,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.bg, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Scrollable content on solid background
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        // ── QUICK STAT PILLS ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _pillCard(
                                  c: c,
                                  color: c.purpleLight,
                                  textColor: c.purpleDark,
                                  icon: Icons.account_balance_wallet_rounded,
                                  title: "₹${walletBalance.toStringAsFixed(0)}",
                                  subtitle: "Wallet balance",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _pillCard(
                                  c: c,
                                  color: c.surface,
                                  textColor: c.textPrimary,
                                  icon: Icons.lock_clock_rounded,
                                  title: "₹${lockedBalance.toStringAsFixed(0)}",
                                  subtitle: "Locked balance",
                                  bordered: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── ACTION LIST ───────────────────────────────
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.border, width: 1),
                          ),
                          child: Column(
                            children: [
                              _listRow(
                                c: c,
                                icon: Icons.qr_code_2_rounded,
                                title: "Your QR code",
                                subtitle: "Use to receive money from any UPI app",
                                onTap: () => _openQrScreen(c, qrValue, userName, userId),
                              ),
                              _infoDivider(c),
                              _listRow(
                                c: c,
                                icon: Icons.badge_outlined,
                                title: "Account details",
                                subtitle: "Name, email, member since",
                                onTap: () => _showAccountInfoSheet(
                                    c, userName, userEmail, userId, memberSince),
                              ),
                              _infoDivider(c),
                              _listRow(
                                c: c,
                                icon: Icons.ios_share_rounded,
                                title: "Share QR code",
                                subtitle: "Send your code to someone",
                                onTap: _handleShare,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── LOGOUT ─────────────────────────────────────
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
                          style: TextStyle(fontSize: 11, color: c.textSecondary),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillCard({
    required AppColors c,
    required Color color,
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
    bool bordered = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: bordered ? Border.all(color: c.border, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _listRow({
    required AppColors c,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.purpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c.purpleDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 20),
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
          Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider(AppColors c) {
    return Container(
        height: 1, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 18));
  }
}

// ── Full-screen photo viewer ─────────────────────────────────────────────

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
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
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

// ── Full-screen QR code view ─────────────────────────────────────────────

class _QrCodeScreen extends StatelessWidget {
  final ScreenshotController screenshotController;
  final File? profileImage;
  final String userName;
  final String userId;
  final String qrValue;
  final VoidCallback onShare;

  const _QrCodeScreen({
    required this.screenshotController,
    required this.profileImage,
    required this.userName,
    required this.userId,
    required this.qrValue,
    required this.onShare,
  });

  Future<void> _handleDownload(BuildContext context) async {
    try {
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/nextpay_qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR code saved"), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  void _copyId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User ID copied"), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);
    const qrFg = Color(0xFF1A1A1A);

    final initials = userName
        .split(" ")
        .where((n) => n.isNotEmpty)
        .map((n) => n[0])
        .join("")
        .toUpperCase();
    final initialsShort = initials.length > 2 ? initials.substring(0, 2) : initials;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _handleDownload(context),
                        icon: Icon(Icons.download_rounded, color: c.textPrimary),
                      ),
                      IconButton(
                        onPressed: onShare,
                        icon: Icon(Icons.more_vert_rounded, color: c.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    // ── QR CARD ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: c.purple,
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: profileImage != null
                                    ? Image.file(profileImage!, fit: BoxFit.cover)
                                    : Center(
                                  child: Text(
                                    initialsShort,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  userName,
                                  style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Screenshot(
                            controller: screenshotController,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  QrImageView(
                                    data: qrValue.isNotEmpty ? qrValue : "empty",
                                    size: 220,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(color: qrFg),
                                    dataModuleStyle: const QrDataModuleStyle(color: qrFg),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      border: Border.all(color: c.border, width: 1),
                                    ),
                                    child: Center(
                                      child: ClipRect(
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          color: c.purple,
                                          child: Image.asset(
                                            'assets/icon/app_icon.png',
                                            fit: BoxFit.fitWidth,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.bolt_outlined,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Scan to pay with NextPay app",
                            style: TextStyle(fontSize: 13, color: c.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          Container(height: 1, color: c.border),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: userId.isNotEmpty ? () => _copyId(context) : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    "User ID: $userId",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (userId.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.copy_rounded, size: 15, color: c.textSecondary),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── SHARE BUTTON ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.purpleLight,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: onShare,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.ios_share_rounded,
                                      color: c.purpleDark, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Share QR code",
                                    style: TextStyle(
                                        color: c.purpleDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── SCANNER BUTTON (hook up to your scan screen) ───
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ScannerScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded,
                                color: c.textPrimary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Open scanner",
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Text(
                      "Powered by NextPay",
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}