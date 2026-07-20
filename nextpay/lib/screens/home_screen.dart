// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';
// import '../providers/auth_provider.dart';
// import '../providers/theme_provider.dart';
// import '../app_colors.dart';
// import '../offline/wallet_engine.dart';
// import '../offline/sync_engine.dart';
// import '../services/storage_service.dart';
// import 'profile_screen.dart';
// import 'send_screen.dart';
// import 'scanner_screen.dart';
// import 'pending_screen.dart';
// import 'history_screen.dart';
// import 'login_screen.dart';
// import 'dart:convert';
// import '../widgets/people_row.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   bool _isOnline = true;
//   bool _balanceVisible = false;
//   File? _profileImage;
//   static const _prefKey = 'profile_image_path';
//   StreamSubscription<List<ConnectivityResult>>? _connSub;
//   final _peopleRowKey = GlobalKey<PeopleRowState>();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProfileImage();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<AuthProvider>().fetchWallet();
//     });
//     _connSub = Connectivity().onConnectivityChanged.listen((results) {
//       final online = results.any((r) => r != ConnectivityResult.none);
//       if (mounted) setState(() => _isOnline = online);
//     });
//     Connectivity().checkConnectivity().then((results) {
//       final online = results.any((r) => r != ConnectivityResult.none);
//       if (mounted) setState(() => _isOnline = online);
//     });
//   }
//
//   String? _resolveUserId(AuthProvider auth) {
//     final user = auth.user;
//     if (user == null) return null;
//     final walletUserId = user.wallet?.extra['user_id'];
//     if (walletUserId != null) return walletUserId.toString();
//     final userIdExtra = user.extra['user_id'];
//     if (userIdExtra != null) return userIdExtra.toString();
//     return user.id;
//   }
//
//   Future<bool> _hasBlockingState(AuthProvider auth) async {
//     final lockedBalance = (auth.user?.wallet?.lockedBalance ?? 0).toDouble();
//     if (lockedBalance > 0) return true;
//     final userId = _resolveUserId(auth);
//     if (userId == null || userId.isEmpty) return false;
//     final pendingRaw =
//     await StorageService.getItem("pending_transactions_$userId");
//     if (pendingRaw != null) {
//       try {
//         final List<dynamic> pending = jsonDecode(pendingRaw);
//         if (pending.isNotEmpty) return true;
//       } catch (e) {
//         debugPrint("PENDING TX PARSE ERROR (logout check): $e");
//       }
//     }
//     return false;
//   }
//
//   Future<void> _loadProfileImage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final path = prefs.getString(_prefKey);
//     if (path != null) {
//       final file = File(path);
//       if (await file.exists()) {
//         if (mounted) setState(() => _profileImage = file);
//       } else {
//         await prefs.remove(_prefKey);
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _connSub?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _handleRefresh() async {
//     final auth = context.read<AuthProvider>();
//     final results = await Connectivity().checkConnectivity();
//     final online = results.any((r) => r != ConnectivityResult.none);
//
//     await Future.wait([
//       auth.fetchWallet(),
//       _loadProfileImage(),
//     ]);
//
//     _peopleRowKey.currentState?.refresh();
//
//     if (mounted) setState(() => _isOnline = online);
//   }
//
//   Future<void> _handleSync() async {
//     final auth = context.read<AuthProvider>();
//     final walletEngine = WalletEngine(auth);
//     final syncEngine = SyncEngine(auth, walletEngine);
//     try {
//       final result = await syncEngine.syncPendingTransactions();
//       if (result["success"] == true) {
//         await StorageService.removeItem("local_wallet");
//         await Future.delayed(const Duration(milliseconds: 500));
//         await auth.fetchWallet();
//         if (mounted) _showAlert("Synced", "All transactions completed.");
//       } else {
//         if (mounted) {
//           _showAlert("Nothing to sync",
//               result["message"] ?? "No pending transactions.");
//         }
//       }
//     } catch (error) {
//       if (mounted) _showAlert("Error", "Sync failed");
//     }
//   }
//
//   Future<void> _handleLogout() async {
//     final auth = context.read<AuthProvider>();
//     final blocked = await _hasBlockingState(auth);
//     if (blocked) {
//       if (mounted) {
//         _showAlert(
//           "Cannot log out",
//           "You have a locked balance or pending offline transactions that "
//               "need to sync first. Please connect to the internet, sync, "
//               "and try again.",
//         );
//       }
//       return;
//     }
//     await auth.logout();
//     if (!mounted) return;
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   }
//
//   void _showAlert(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _navigate(Widget screen) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => screen),
//     );
//
//     await _loadProfileImage();
//
//     // Always refresh wallet after returning
//     await context.read<AuthProvider>().fetchWallet();
//
//     if (mounted) {
//       setState(() {});
//       _peopleRowKey.currentState?.refresh();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final theme = context.watch<ThemeProvider>();
//     final c = AppColors(isDark: theme.isDark);
//     final user = auth.user;
//
//     final balance = (user?.wallet?.balance ?? 0).toDouble();
//     final lockedBalance = (user?.wallet?.lockedBalance ?? 0).toDouble();
//     final availableBalance = (balance - lockedBalance).toStringAsFixed(2);
//     final lockedBalanceDisplay = lockedBalance.toStringAsFixed(2);
//     final totalBalance = balance.toStringAsFixed(2);
//     final userName =
//     user?.name.isNotEmpty == true ? user!.name : "User";
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
//     const mask = "•••••";
//
//     return Scaffold(
//       backgroundColor: c.bg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ── HEADER ──────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => _navigate(const ProfileScreen()),
//                         child: Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(
//                             color: c.purple,
//                             shape: BoxShape.circle,
//                           ),
//                           clipBehavior: Clip.antiAlias,
//                           child: _profileImage != null
//                               ? Image.file(_profileImage!,
//                               fit: BoxFit.cover, width: 44, height: 44)
//                               : Center(
//                             child: Text(
//                               initialsShort,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Good day",
//                               style: TextStyle(
//                                   color: c.textSecondary, fontSize: 12)),
//                           Text(userName,
//                               style: TextStyle(
//                                   color: c.textPrimary,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600)),
//                         ],
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       // Online / offline badge
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 5),
//                         decoration: BoxDecoration(
//                           color: _isOnline ? c.successBg : c.dangerBg,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 6,
//                               height: 6,
//                               decoration: BoxDecoration(
//                                 color: _isOnline
//                                     ? c.successText
//                                     : c.dangerText,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               _isOnline ? "Online" : "Offline",
//                               style: TextStyle(
//                                 color: _isOnline
//                                     ? c.successText
//                                     : c.dangerText,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       // Dark mode toggle
//                       GestureDetector(
//                         onTap: () =>
//                             context.read<ThemeProvider>().toggle(),
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: c.surface,
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: c.border, width: 1),
//                           ),
//                           child: Icon(
//                             theme.isDark
//                                 ? Icons.light_mode_rounded
//                                 : Icons.dark_mode_rounded,
//                             size: 18,
//                             color: c.textSecondary,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child: RefreshIndicator(
//                 color: c.purple,
//                 onRefresh: _handleRefresh,
//                 child: SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.only(bottom: 24),
//                   child: Column(
//                   children: [
//                     // ── BALANCE CARD ───────────────────────────────────
//                     Container(
//                       margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//                       padding: const EdgeInsets.all(22),
//                       decoration: BoxDecoration(
//                         color: c.purpleLight,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text("Available balance",
//                                   style: TextStyle(
//                                       color: c.purple, fontSize: 13)),
//                               GestureDetector(
//                                 onTap: () => setState(() =>
//                                 _balanceVisible = !_balanceVisible),
//                                 child: Icon(
//                                   _balanceVisible
//                                       ? Icons.visibility_outlined
//                                       : Icons.visibility_off_outlined,
//                                   size: 18,
//                                   color: c.purple,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             _balanceVisible
//                                 ? "₹$availableBalance"
//                                 : "₹$mask",
//                             style: TextStyle(
//                                 color: c.purpleDark,
//                                 fontSize: 38,
//                                 fontWeight: FontWeight.w600),
//                           ),
//                           Container(
//                             height: 1,
//                             margin:
//                             const EdgeInsets.symmetric(vertical: 16),
//                             color: c.purple.withOpacity(0.15),
//                           ),
//                           Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.spaceBetween,
//                             children: [
//                               Column(
//                                 crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                                 children: [
//                                   Text("Total",
//                                       style: TextStyle(
//                                           color:
//                                           c.purple.withOpacity(0.7),
//                                           fontSize: 12)),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     _balanceVisible
//                                         ? "₹$totalBalance"
//                                         : "₹$mask",
//                                     style: TextStyle(
//                                         color: c.purpleDark,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ],
//                               ),
//                               if (lockedBalance > 0)
//                                 Column(
//                                   crossAxisAlignment:
//                                   CrossAxisAlignment.end,
//                                   children: [
//                                     Text("Locked",
//                                         style: TextStyle(
//                                             color: c.amber.withOpacity(
//                                                 0.85),
//                                             fontSize: 12)),
//                                     const SizedBox(height: 2),
//                                     Text(
//                                       _balanceVisible
//                                           ? "₹$lockedBalanceDisplay"
//                                           : "₹$mask",
//                                       style: TextStyle(
//                                           color: c.amber,
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600),
//                                     ),
//                                   ],
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // ── QUICK ACTIONS ──────────────────────────────────
//                     Padding(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 20),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "Quick actions",
//                           style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: c.textSecondary),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     Padding(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 16),
//                       child: Row(
//                         children: [
//                           Expanded(
//                               child: _quickAction(
//                                   c,
//                                   "Send",
//                                   Icons.north_east_rounded,
//                                   c.purpleLight,
//                                   c.purple,
//                                       () => _navigate(const SendScreen()))),
//                           const SizedBox(width: 10),
//                           Expanded(
//                               child: _quickAction(
//                                   c,
//                                   "Scan",
//                                   Icons.qr_code_scanner_rounded,
//                                   c.tealLight,
//                                   c.teal,
//                                       () =>
//                                       _navigate(const ScannerScreen()))),
//                           const SizedBox(width: 10),
//                           Expanded(
//                               child: _quickAction(
//                                   c,
//                                   "Pending",
//                                   Icons.schedule_rounded,
//                                   c.amberLight,
//                                   c.amber,
//                                       () =>
//                                       _navigate(const PendingScreen()))),
//                           const SizedBox(width: 10),
//                           Expanded(
//                               child: _quickAction(
//                                   c,
//                                   "History",
//                                   Icons.receipt_long_rounded,
//                                   c.blueLight,
//                                   c.blue,
//                                       () =>
//                                       _navigate(const HistoryScreen()))),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//                     PeopleRow(key: _peopleRowKey),
//
//                     // ── MENU LIST ──────────────────────────────────────
//                     Padding(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 20),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "More",
//                           style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: c.textSecondary),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Container(
//                       margin:
//                       const EdgeInsets.symmetric(horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: c.surface,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: c.border, width: 1),
//                       ),
//                       child: Column(
//                         children: [
//                           _menuItem(
//                               c,
//                               Icons.send_rounded,
//                               c.purpleLight,
//                               c.purple,
//                               "Send money",
//                               "Transfer to any wallet",
//                                   () => _navigate(const SendScreen())),
//                           _menuDivider(c),
//                           _menuItem(
//                               c,
//                               Icons.schedule_rounded,
//                               c.amberLight,
//                               c.amber,
//                               "Pending transactions",
//                               "Offline queue waiting to sync",
//                                   () => _navigate(const PendingScreen())),
//                           _menuDivider(c),
//                           _menuItem(
//                               c,
//                               Icons.receipt_long_rounded,
//                               c.blueLight,
//                               c.blue,
//                               "Transaction history",
//                               "All completed payments",
//                                   () => _navigate(const HistoryScreen())),
//                           _menuDivider(c),
//                           _menuItem(
//                               c,
//                               Icons.sync_rounded,
//                               c.tealLight,
//                               c.teal,
//                               "Sync transactions",
//                               "Push offline payments online",
//                               _handleSync),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const SizedBox(height: 20),
//                     Text(
//                       "© 2025 Built by moinworksonlocalhost",
//                       style: TextStyle(
//                           fontSize: 11, color: c.textSecondary),
//                     ),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _quickAction(AppColors c, String label, IconData icon, Color bg,
//       Color iconColor, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             alignment: Alignment.center,
//             child: Icon(icon, color: iconColor, size: 22),
//           ),
//           const SizedBox(height: 8),
//           Text(label,
//               style: TextStyle(fontSize: 12, color: c.textSecondary)),
//         ],
//       ),
//     );
//   }
//
//   Widget _menuItem(AppColors c, IconData icon, Color bg, Color iconColor,
//       String title, String sub, VoidCallback onTap) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding:
//           const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: bg,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 alignment: Alignment.center,
//                 child: Icon(icon, color: iconColor, size: 18),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: c.textPrimary)),
//                     const SizedBox(height: 2),
//                     Text(sub,
//                         style: TextStyle(
//                             fontSize: 12, color: c.textSecondary)),
//                   ],
//                 ),
//               ),
//               Icon(Icons.chevron_right_rounded,
//                   color: c.textSecondary.withOpacity(0.6), size: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _menuDivider(AppColors c) {
//     return Container(
//       height: 1,
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       color: c.border,
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../offline/wallet_engine.dart';
import '../offline/sync_engine.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/wallet_transaction.dart';
import 'profile_screen.dart';
import 'send_screen.dart';
import 'scanner_screen.dart';
import 'pending_screen.dart';
import 'history_screen.dart';
import 'transaction_detail_screen.dart';
import 'login_screen.dart';
import 'dart:convert';
import '../widgets/people_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = true;
  bool _balanceVisible = false;
  File? _profileImage;
  static const _prefKey = 'profile_image_path';
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final _peopleRowKey = GlobalKey<PeopleRowState>();

  // Recent transactions (same underlying data/cache as HistoryScreen).
  List<WalletTransaction> _recentTx = [];
  bool _txLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadRecentTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchWallet();
    });
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
    Connectivity().checkConnectivity().then((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
  }

  String? _resolveUserId(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return null;
    final walletUserId = user.wallet?.extra['user_id'];
    if (walletUserId != null) return walletUserId.toString();
    final userIdExtra = user.extra['user_id'];
    if (userIdExtra != null) return userIdExtra.toString();
    return user.id;
  }

  // Loads the same data HistoryScreen shows (and shares its cache key),
  // then keeps just the most recent 5 for the home screen preview.
  Future<void> _loadRecentTransactions() async {
    try {
      final response = await ApiService.instance.get("/wallet/transactions");
      final List<dynamic> data = response.data;
      final txs = data
          .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await StorageService.setItem("cached_transactions", jsonEncode(data));
      if (mounted) {
        setState(() {
          _recentTx = txs.take(5).toList();
          _txLoading = false;
        });
      }
    } catch (error) {
      debugPrint("❌ HOME RECENT TX ERROR (trying cache): $error");
      try {
        final cached = await StorageService.getItem("cached_transactions");
        if (cached != null) {
          final List<dynamic> data = jsonDecode(cached);
          final txs = data
              .map((e) =>
              WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (mounted) setState(() => _recentTx = txs.take(5).toList());
        }
      } catch (e) {
        debugPrint("❌ HOME RECENT TX CACHE ERROR: $e");
      }
      if (mounted) setState(() => _txLoading = false);
    }
  }

  Future<bool> _hasBlockingState(AuthProvider auth) async {
    final lockedBalance = (auth.user?.wallet?.lockedBalance ?? 0).toDouble();
    if (lockedBalance > 0) return true;
    final userId = _resolveUserId(auth);
    if (userId == null || userId.isEmpty) return false;
    final pendingRaw =
    await StorageService.getItem("pending_transactions_$userId");
    if (pendingRaw != null) {
      try {
        final List<dynamic> pending = jsonDecode(pendingRaw);
        if (pending.isNotEmpty) return true;
      } catch (e) {
        debugPrint("PENDING TX PARSE ERROR (logout check): $e");
      }
    }
    return false;
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        if (mounted) setState(() => _profileImage = file);
      } else {
        await prefs.remove(_prefKey);
      }
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final auth = context.read<AuthProvider>();
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);

    await Future.wait([
      auth.fetchWallet(),
      _loadProfileImage(),
      _loadRecentTransactions(),
    ]);

    _peopleRowKey.currentState?.refresh();

    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _handleSync() async {
    final auth = context.read<AuthProvider>();
    final walletEngine = WalletEngine(auth);
    final syncEngine = SyncEngine(auth, walletEngine);
    try {
      final result = await syncEngine.syncPendingTransactions();
      if (result["success"] == true) {
        await StorageService.removeItem("local_wallet");
        await Future.delayed(const Duration(milliseconds: 500));
        await auth.fetchWallet();
        if (mounted) _showAlert("Synced", "All transactions completed.");
      } else {
        if (mounted) {
          _showAlert("Nothing to sync",
              result["message"] ?? "No pending transactions.");
        }
      }
    } catch (error) {
      if (mounted) _showAlert("Error", "Sync failed");
    }
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    final blocked = await _hasBlockingState(auth);
    if (blocked) {
      if (mounted) {
        _showAlert(
          "Cannot log out",
          "You have a locked balance or pending offline transactions that "
              "need to sync first. Please connect to the internet, sync, "
              "and try again.",
        );
      }
      return;
    }
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  Future<void> _navigate(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    await _loadProfileImage();

    // Always refresh wallet after returning
    await context.read<AuthProvider>().fetchWallet();

    if (mounted) {
      setState(() {});
      _peopleRowKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);
    final user = auth.user;

    final balance = (user?.wallet?.balance ?? 0).toDouble();
    final lockedBalance = (user?.wallet?.lockedBalance ?? 0).toDouble();
    final availableBalance = (balance - lockedBalance).toStringAsFixed(2);
    final lockedBalanceDisplay = lockedBalance.toStringAsFixed(2);
    final totalBalance = balance.toStringAsFixed(2);
    final userName =
    user?.name.isNotEmpty == true ? user!.name : "User";

    final initials = userName
        .split(" ")
        .where((n) => n.isNotEmpty)
        .map((n) => n[0])
        .join("")
        .toUpperCase();
    final initialsShort =
    initials.length > 2 ? initials.substring(0, 2) : initials;

    const mask = "•••••";

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigate(const ProfileScreen()),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.purple,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _profileImage != null
                              ? Image.file(_profileImage!,
                              fit: BoxFit.cover, width: 44, height: 44)
                              : Center(
                            child: Text(
                              initialsShort,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Good day",
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 12)),
                          Text(userName,
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Online / offline badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isOnline ? c.successBg : c.dangerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? c.successText
                                    : c.dangerText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOnline ? "Online" : "Offline",
                              style: TextStyle(
                                color: _isOnline
                                    ? c.successText
                                    : c.dangerText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dark mode toggle
                      GestureDetector(
                        onTap: () =>
                            context.read<ThemeProvider>().toggle(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border, width: 1),
                          ),
                          child: Icon(
                            theme.isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 18,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: c.purple,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      // ── BALANCE CARD ───────────────────────────────────
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: c.purpleLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Available balance",
                                    style: TextStyle(
                                        color: c.purple, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                  _balanceVisible = !_balanceVisible),
                                  child: Icon(
                                    _balanceVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: c.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _balanceVisible
                                  ? "₹$availableBalance"
                                  : "₹$mask",
                              style: TextStyle(
                                  color: c.purpleDark,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w600),
                            ),
                            Container(
                              height: 1,
                              margin:
                              const EdgeInsets.symmetric(vertical: 16),
                              color: c.purple.withOpacity(0.15),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text("Total",
                                        style: TextStyle(
                                            color:
                                            c.purple.withOpacity(0.7),
                                            fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _balanceVisible
                                          ? "₹$totalBalance"
                                          : "₹$mask",
                                      style: TextStyle(
                                          color: c.purpleDark,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                if (lockedBalance > 0)
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text("Locked",
                                          style: TextStyle(
                                              color: c.amber.withOpacity(
                                                  0.85),
                                              fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _balanceVisible
                                            ? "₹$lockedBalanceDisplay"
                                            : "₹$mask",
                                        style: TextStyle(
                                            color: c.amber,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── QUICK ACTIONS ──────────────────────────────────
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Quick actions",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                                child: _quickAction(
                                    c,
                                    "Send",
                                    Icons.north_east_rounded,
                                    c.purpleLight,
                                    c.purple,
                                        () => _navigate(const SendScreen()))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _quickAction(
                                    c,
                                    "Scan",
                                    Icons.qr_code_scanner_rounded,
                                    c.tealLight,
                                    c.teal,
                                        () =>
                                        _navigate(const ScannerScreen()))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _quickAction(
                                    c,
                                    "Pending",
                                    Icons.schedule_rounded,
                                    c.amberLight,
                                    c.amber,
                                        () =>
                                        _navigate(const PendingScreen()))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _quickAction(
                                    c,
                                    "History",
                                    Icons.receipt_long_rounded,
                                    c.blueLight,
                                    c.blue,
                                        () =>
                                        _navigate(const HistoryScreen()))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      PeopleRow(key: _peopleRowKey),

                      // ── RECENT TRANSACTIONS ─────────────────────────────
                      const SizedBox(height: 8),
                      _recentTransactionsSection(c, _resolveUserId(auth)),

                      const SizedBox(height: 24),
                      const SizedBox(height: 20),
                      Text(
                        "© 2025 Built by moinworksonlocalhost",
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Recent transactions card: header ("Recent Transactions" +
  // "View All" + a small sync affordance so the old menu's sync
  // action isn't lost), a list of up to 5 rows, and an empty state.
  // ─────────────────────────────────────────────────────────
  Widget _recentTransactionsSection(AppColors c, String? currentUserId) {
    final items = _recentTx;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  "Recent transactions",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _handleSync,
                    child: Icon(Icons.sync_rounded,
                        size: 16, color: c.textSecondary.withOpacity(0.7)),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => _navigate(const HistoryScreen()),
                    child: Text(
                      "View All",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.purple),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: _txLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
                : items.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 28, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 26,
                        color: c.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      "No transactions yet",
                      style: TextStyle(
                          fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            )
                : Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _txRow(
                    c,
                    items[i],
                    isReceived: items[i].receiverId == currentUserId,
                  ),
                  if (i != items.length - 1) _menuDivider(c),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _txRow(AppColors c, WalletTransaction tx, {required bool isReceived}) {
    final iconBg = isReceived ? c.successBg : c.dangerBg;
    final iconColor = isReceived ? c.successText : c.dangerText;
    final amountColor = isReceived ? c.successText : c.dangerText;
    final sign = isReceived ? "+" : "-";
    final amountText = "$sign₹${tx.amount.toStringAsFixed(2)}";

    // Same name-fallback pattern HistoryScreen uses.
    final personName = isReceived
        ? (tx.senderName.isNotEmpty && tx.senderName != "Unknown"
        ? tx.senderName
        : tx.senderId)
        : (tx.receiverName.isNotEmpty && tx.receiverName != "Unknown"
        ? tx.receiverName
        : tx.receiverId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              tx: tx,
              isReceived: isReceived,
              personName: personName,
              personPhone: "",
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                isReceived
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(personName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    tx.isOffline ? "Offline" : "Online",
                    style:
                    TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: amountColor)),
                const SizedBox(height: 2),
                Text(tx.status,
                    style:
                    TextStyle(fontSize: 11, color: c.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(AppColors c, String label, IconData icon, Color bg,
      Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuDivider(AppColors c) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: c.border,
    );
  }
}