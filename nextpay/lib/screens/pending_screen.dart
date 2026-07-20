// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../models/transaction.dart';
// import '../services/storage_service.dart';
// import 'home_screen.dart';
//
// const _bg = Color(0xFFF3EBDD);
// const _dark = Color(0xFF1A0A00);
// const _border = Color(0xFF111111);
// const _orange = Color(0xFFC85A1E);
// const _muted = Color(0xFF9A7A5A);
//
// class PendingScreen extends StatefulWidget {
//   const PendingScreen({super.key});
//
//   @override
//   State<PendingScreen> createState() => _PendingScreenState();
// }
//
// class _PendingScreenState extends State<PendingScreen> {
//   List<OfflineTransaction> _transactions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
//   }
//
//   Future<void> _loadTransactions() async {
//     try {
//       final auth = context.read<AuthProvider>();
//       final user = auth.user;
//       if (user == null) return;
//
//       // Use same ID resolution as TransactionEngine and SyncEngine
//       final senderId = user.wallet?.extra['user_id']?.toString() ?? user.id;
//       final storageKey = "pending_transactions_$senderId";
//       debugPrint("PENDING STORAGE KEY: $storageKey");
//
//       final data = await StorageService.getItem(storageKey);
//       final List<dynamic> raw = data != null ? jsonDecode(data) : [];
//
//       setState(() {
//         _transactions = raw
//             .map((e) => OfflineTransaction.fromJson(Map<String, dynamic>.from(e)))
//             .toList();
//       });
//     } catch (error) {
//       debugPrint("LOAD TX ERROR: $error");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalLocked = _transactions.fold<num>(0, (s, tx) => s + tx.amount);
//
//     return Scaffold(
//       backgroundColor: _bg,
//       body: Column(
//         children: [
//           // HEADER
//           Container(
//             color: _dark,
//             padding: EdgeInsets.fromLTRB(
//               20,
//               Theme.of(context).platform == TargetPlatform.iOS ? 54 : 40,
//               20,
//               20,
//             ),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (_) => const HomeScreen()),
//                   ),
//                   child: Container(
//                     width: 42,
//                     height: 42,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.08),
//                       border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     alignment: Alignment.center,
//                     child: const Text(
//                       "←",
//                       style: TextStyle(color: _bg, fontSize: 20, fontWeight: FontWeight.w900),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text(
//                       "OFFLINE QUEUE",
//                       style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
//                     ),
//                     Text(
//                       "Pending",
//                       style: TextStyle(color: _bg, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // SUMMARY STRIP — FIX: color moved inside BoxDecoration
//           if (_transactions.isNotEmpty)
//             Container(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
//               decoration: const BoxDecoration(
//                 color: _dark, // ← moved here from color: property
//                 border: Border(bottom: BorderSide(color: _orange, width: 3)),
//               ),
//               child: Row(
//                 children: [
//                   _summaryItem("QUEUED", "${_transactions.length}", _bg),
//                   _summaryDivider(),
//                   _summaryItem("TOTAL LOCKED", "₹${totalLocked.toStringAsFixed(2)}", const Color(0xFFFFB347)),
//                   _summaryDivider(),
//                   _summaryItem("STATUS", "OFFLINE", const Color(0xFFFF8A8A)),
//                 ],
//               ),
//             ),
//
//           // LIST
//           Expanded(
//             child: _transactions.isEmpty
//                 ? const _EmptyState()
//                 : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _transactions.length,
//               itemBuilder: (context, index) {
//                 return _PendingCard(item: _transactions[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryItem(String label, String value, Color valueColor) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.w900),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryDivider() {
//     return Container(
//       width: 1,
//       height: 32,
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       color: Colors.white.withOpacity(0.1),
//     );
//   }
// }
//
// class _PendingCard extends StatelessWidget {
//   final OfflineTransaction item;
//
//   const _PendingCard({required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEFE4D1),
//         border: Border.all(color: _border, width: 3),
//         boxShadow: const [
//           BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
//         ],
//       ),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Container(width: 5, color: _orange),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "₹${item.amount.toStringAsFixed(2)}",
//                               style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.w900,
//                                 color: _orange,
//                                 letterSpacing: -0.5,
//                               ),
//                             ),
//                             const SizedBox(height: 3),
//                             const Text(
//                               "↑ SENT",
//                               style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _orange, letterSpacing: 1),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                           decoration: BoxDecoration(
//                             color: _orange,
//                             border: Border.all(color: _border, width: 2),
//                           ),
//                           child: const Text(
//                             "PENDING",
//                             style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Container(
//                       height: 2,
//                       color: _border,
//                       margin: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     _metaRow("STATUS: ", item.status.toUpperCase(), bold: true),
//                     const SizedBox(height: 4),
//                     _metaRow("TX ID: ", item.txId),
//                     const SizedBox(height: 4),
//                     _metaRow("TO: ", item.receiver),
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
//   Widget _metaRow(String label, String value, {bool bold = false}) {
//     return RichText(
//       overflow: TextOverflow.ellipsis,
//       maxLines: 1,
//       text: TextSpan(
//         style: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF7A6A5A),
//           letterSpacing: 0.5,
//         ),
//         children: [
//           TextSpan(text: label),
//           TextSpan(
//             text: value,
//             style: TextStyle(
//               color: _border,
//               fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _EmptyState extends StatelessWidget {
//   const _EmptyState();
//
//   @override
//   Widget build(BuildContext context) {
//     return const Padding(
//       padding: EdgeInsets.only(top: 80),
//       child: Column(
//         children: [
//           Text("✅", style: TextStyle(fontSize: 48)),
//           SizedBox(height: 16),
//           Text(
//             "ALL CLEAR",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _border, letterSpacing: 2),
//           ),
//           SizedBox(height: 6),
//           Text(
//             "No pending transactions",
//             style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../models/transaction.dart';
// import '../services/storage_service.dart';
//
// // ── Design tokens (matches home_screen.dart) ───────────────────────────────
// const _bg = Color(0xFFF7F6F2);
// const _surface = Colors.white;
// const _textPrimary = Color(0xFF1A1A1A);
// const _textSecondary = Color(0xFF6B6B68);
// const _border = Color(0xFFE9E7E1);
//
// const _purple = Color(0xFF534AB7);
// const _purpleLight = Color(0xFFEEEDFE);
//
// const _amber = Color(0xFF854F0B);
// const _amberLight = Color(0xFFFAEEDA);
//
// const _dangerText = Color(0xFF791F1F);
// const _dangerBg = Color(0xFFFCEBEB);
//
// const _successText = Color(0xFF27500A);
// const _successBg = Color(0xFFEAF3DE);
//
// class PendingScreen extends StatefulWidget {
//   const PendingScreen({super.key});
//
//   @override
//   State<PendingScreen> createState() => _PendingScreenState();
// }
//
// class _PendingScreenState extends State<PendingScreen> {
//   List<OfflineTransaction> _transactions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
//   }
//
//   Future<void> _loadTransactions() async {
//     try {
//       final auth = context.read<AuthProvider>();
//       final user = auth.user;
//       if (user == null) return;
//
//       final senderId = user.wallet?.extra['user_id']?.toString() ?? user.id;
//       final storageKey = "pending_transactions_$senderId";
//       debugPrint("PENDING STORAGE KEY: $storageKey");
//
//       final data = await StorageService.getItem(storageKey);
//       final List<dynamic> raw = data != null ? jsonDecode(data) : [];
//
//       setState(() {
//         _transactions = raw
//             .map((e) =>
//             OfflineTransaction.fromJson(Map<String, dynamic>.from(e)))
//             .toList();
//       });
//     } catch (error) {
//       debugPrint("LOAD TX ERROR: $error");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalLocked =
//     _transactions.fold<num>(0, (s, tx) => s + tx.amount);
//
//     return Scaffold(
//       backgroundColor: _bg,
//       body: Column(
//         children: [
//           // ── Header ──────────────────────────────────────────────────
//           SafeArea(
//             bottom: false,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: _surface,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: _border, width: 1),
//                       ),
//                       child: const Icon(Icons.arrow_back_ios_new_rounded,
//                           size: 16, color: _textPrimary),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Pending',
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w700,
//                                 color: _textPrimary)),
//                         Text('Offline queue waiting to sync',
//                             style: TextStyle(
//                                 fontSize: 12, color: _textSecondary)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // ── Summary card ─────────────────────────────────────────────
//           if (_transactions.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//               child: Container(
//                 padding: const EdgeInsets.all(18),
//                 decoration: BoxDecoration(
//                   color: _amberLight,
//                   borderRadius: BorderRadius.circular(20),
//                   border:
//                   Border.all(color: _amber.withOpacity(0.3), width: 1),
//                 ),
//                 child: Row(
//                   children: [
//                     _summaryItem(
//                         'Queued',
//                         '${_transactions.length}',
//                         _amber),
//                     _summaryDivider(),
//                     _summaryItem(
//                         'Total locked',
//                         '₹${totalLocked.toStringAsFixed(2)}',
//                         _amber),
//                     _summaryDivider(),
//                     _summaryItem('Status', 'Offline', _dangerText),
//                   ],
//                 ),
//               ),
//             ),
//
//           // ── List ─────────────────────────────────────────────────────
//           Expanded(
//             child: _transactions.isEmpty
//                 ? const _EmptyState()
//                 : ListView.builder(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//               itemCount: _transactions.length,
//               itemBuilder: (context, index) =>
//                   _PendingCard(item: _transactions[index]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryItem(String label, String value, Color valueColor) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(label,
//               style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                   color: _textSecondary)),
//           const SizedBox(height: 4),
//           Text(value,
//               style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: valueColor)),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryDivider() {
//     return Container(
//       width: 1,
//       height: 32,
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       color: _amber.withOpacity(0.25),
//     );
//   }
// }
//
// class _PendingCard extends StatelessWidget {
//   final OfflineTransaction item;
//
//   const _PendingCard({required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _border, width: 1),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 2)),
//         ],
//       ),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Left accent bar
//             Container(
//               width: 4,
//               decoration: BoxDecoration(
//                 color: _amber,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   bottomLeft: Radius.circular(16),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '₹${item.amount.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                   fontSize: 26,
//                                   fontWeight: FontWeight.w700,
//                                   color: _textPrimary),
//                             ),
//                             const SizedBox(height: 2),
//                             Row(
//                               children: [
//                                 const Icon(Icons.north_east_rounded,
//                                     size: 12, color: _amber),
//                                 const SizedBox(width: 4),
//                                 const Text('Sent',
//                                     style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w500,
//                                         color: _amber)),
//                               ],
//                             ),
//                           ],
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 5),
//                           decoration: BoxDecoration(
//                             color: _amberLight,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Text(
//                             'Pending',
//                             style: TextStyle(
//                                 color: _amber,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     Container(
//                       height: 1,
//                       color: _border,
//                       margin: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//
//                     _metaRow(Icons.sync_rounded, 'Status',
//                         item.status.toUpperCase()),
//                     const SizedBox(height: 6),
//                     _metaRow(Icons.tag_rounded, 'TXN ID', item.txId),
//                     const SizedBox(height: 6),
//                     _metaRow(Icons.person_outline_rounded, 'To',
//                         item.receiver),
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
//   Widget _metaRow(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Icon(icon, size: 13, color: _textSecondary),
//         const SizedBox(width: 6),
//         Text('$label: ',
//             style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: _textSecondary)),
//         Expanded(
//           child: Text(
//             value,
//             overflow: TextOverflow.ellipsis,
//             maxLines: 1,
//             style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: _textPrimary),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _EmptyState extends StatelessWidget {
//   const _EmptyState();
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 72,
//             height: 72,
//             decoration: BoxDecoration(
//               color: _successBg,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.check_rounded,
//                 size: 36, color: _successText),
//           ),
//           const SizedBox(height: 16),
//           const Text('All clear',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                   color: _textPrimary)),
//           const SizedBox(height: 6),
//           const Text('No pending transactions',
//               style: TextStyle(fontSize: 13, color: _textSecondary)),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  List<OfflineTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user == null) return;
      final senderId =
          user.wallet?.extra['user_id']?.toString() ?? user.id;
      final storageKey = "pending_transactions_$senderId";
      debugPrint("PENDING STORAGE KEY: $storageKey");
      final data = await StorageService.getItem(storageKey);
      final List<dynamic> raw = data != null ? jsonDecode(data) : [];
      setState(() {
        _transactions = raw
            .map((e) =>
            OfflineTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (error) {
      debugPrint("LOAD TX ERROR: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);
    final totalLocked =
    _transactions.fold<num>(0, (s, tx) => s + tx.amount);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary)),
                        Text('Offline queue waiting to sync',
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Summary card ─────────────────────────────────────────────
          if (_transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.amberLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: c.amber.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    _summaryItem(
                        c, 'Queued', '${_transactions.length}', c.amber),
                    _summaryDivider(c),
                    _summaryItem(
                        c,
                        'Total locked',
                        '₹${totalLocked.toStringAsFixed(2)}',
                        c.amber),
                    _summaryDivider(c),
                    _summaryItem(
                        c, 'Status', 'Offline', c.dangerText),
                  ],
                ),
              ),
            ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: _transactions.isEmpty
                ? _EmptyState(c: c)
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _transactions.length,
              itemBuilder: (context, index) =>
                  _PendingCard(item: _transactions[index], c: c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
      AppColors c, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _summaryDivider(AppColors c) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: c.amber.withOpacity(0.25),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final OfflineTransaction item;
  final AppColors c;

  const _PendingCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: c.amber,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.north_east_rounded,
                                    size: 12, color: c.amber),
                                const SizedBox(width: 4),
                                Text('Sent',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: c.amber)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.amberLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Pending',
                              style: TextStyle(
                                  color: c.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Container(
                      height: 1,
                      color: c.border,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    _metaRow(c, Icons.sync_rounded, 'Status',
                        item.status.toUpperCase()),
                    const SizedBox(height: 6),
                    _metaRow(c, Icons.tag_rounded, 'TXN ID', item.txId),
                    const SizedBox(height: 6),
                    _metaRow(
                        c, Icons.person_outline_rounded, 'To', item.receiver),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(
      AppColors c, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: c.textSecondary),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.textSecondary)),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColors c;
  const _EmptyState({required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.successBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 36, color: c.successText),
          ),
          const SizedBox(height: 16),
          Text('All clear',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('No pending transactions',
              style:
              TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}