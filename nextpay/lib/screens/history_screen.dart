import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../models/wallet_transaction.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'transaction_detail_screen.dart';
import 'transaction_detail_screen.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  bool _loadStarted = false;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartLoad());
  }

  void _maybeStartLoad() {
    if (_loadStarted || !mounted) return;

    final auth = context.read<AuthProvider>();
    // Home does not wait for hydration; neither should History. Proceed once
    // auth is hydrated OR we already have a logged-in user in memory.
    if (auth.hydrated || auth.user != null) {
      _startLoad();
      return;
    }

    _authListener = () {
      final current = context.read<AuthProvider>();
      if (current.hydrated || current.user != null) {
        current.removeListener(_authListener!);
        _authListener = null;
        _startLoad();
      }
    };
    auth.addListener(_authListener!);
  }

  Future<void> _startLoad() async {
    if (_loadStarted) return;
    _loadStarted = true;
    if (mounted) setState(() => _loading = true);
    await _loadTransactions();
  }

  @override
  void dispose() {
    if (_authListener != null) {
      try {
        context.read<AuthProvider>().removeListener(_authListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _resolveUserId(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return null;
    final walletUserId = user.wallet?.extra['user_id'];
    if (walletUserId != null) return walletUserId.toString();
    final userIdExtra = user.extra['user_id'];
    if (userIdExtra != null) return userIdExtra.toString();
    return user.id;
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadTransactions() async {
    debugPrint("🔄 LOADING TRANSACTIONS...");
    try {
      final response = await ApiService.instance.get("/wallet/transactions");
      debugPrint("✅ GOT ${(response.data as List).length} transactions");
      final List<dynamic> data = response.data;
      final txs = data
          .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await StorageService.setItem("cached_transactions", jsonEncode(data));
      if (mounted) setState(() => _transactions = txs);
    } catch (error) {
      // ✅ On any network error (timeout, no connection, etc.) we fall through
      // to cache ONCE and stop. We never retry automatically.
      debugPrint("❌ HISTORY ERROR (trying cache): $error");
      try {
        final cached = await StorageService.getItem("cached_transactions");
        if (cached != null) {
          final List<dynamic> data = jsonDecode(cached);
          final txs = data
              .map((e) =>
              WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (mounted) setState(() => _transactions = txs);
        }
      } catch (e) {
        debugPrint("❌ CACHE LOAD ERROR: $e");
      }
    } finally {
      // Always clear the loading flag — success, cache hit, or total failure.
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(child: CircularProgressIndicator(color: c.purple)),
      );
    }

    final currentUserId = _resolveUserId(auth);

    final received =
    _transactions.where((tx) => tx.receiverId == currentUserId).toList();
    final sent =
    _transactions.where((tx) => tx.receiverId != currentUserId).toList();
    final totalReceived = received.fold<num>(0, (s, tx) => s + tx.amount);
    final totalSent = sent.fold<num>(0, (s, tx) => s + tx.amount);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
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
                        Text('History',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary)),
                        Text('All completed payments',
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Summary cards ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Received',
                    value: '+₹${totalReceived.toStringAsFixed(2)}',
                    bg: c.successBg,
                    fg: c.successText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Sent',
                    value: '-₹${totalSent.toStringAsFixed(2)}',
                    bg: c.dangerBg,
                    fg: c.dangerText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Total',
                    value: '${_transactions.length} txns',
                    bg: c.blueLight,
                    fg: c.blue,
                  ),
                ),
              ],
            ),
          ),

          // ── Refresh button (manual retry after offline) ───────────
          if (_transactions.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _loading = true);
                  _loadTransactions();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: c.purpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: c.purple),
                      const SizedBox(width: 8),
                      Text('Retry',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.purple)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Transaction list ──────────────────────────────────────
          Expanded(
            child: _transactions.isEmpty
                ? _EmptyState(c: c)
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final item = _transactions[index];
                return _TransactionCard(
                  item: item,
                  isReceived: item.receiverId == currentUserId,
                  c: c,
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© 2025 Built by moinworksonlocalhost',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

// ── Transaction card ──────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final WalletTransaction item;
  final bool isReceived;
  final AppColors c;

  const _TransactionCard({
    required this.item,
    required this.isReceived,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isReceived ? c.teal : c.dangerText;
    final amountFormatted = item.amount.toStringAsFixed(2);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              tx: item,
              isReceived: isReceived,
              personName:
              isReceived ? item.senderName : item.receiverName,
              personPhone: "",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
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
                      // Top Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${isReceived ? '+' : '-'}₹$amountFormatted',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 2),

                              Row(
                                children: [
                                  Icon(
                                    isReceived
                                        ? Icons.south_east_rounded
                                        : Icons.north_east_rounded,
                                    size: 12,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isReceived
                                        ? 'Received'
                                        : 'Sent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              _Badge(
                                label:
                                item.isOffline ? 'Offline' : 'Online',
                                bg: item.isOffline
                                    ? c.border.withOpacity(0.5)
                                    : c.tealLight,
                                fg: item.isOffline
                                    ? c.textSecondary
                                    : c.teal,
                              ),
                              const SizedBox(height: 6),
                              _Badge(
                                label: item.status,
                                bg: c.purpleLight,
                                fg: c.purple,
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(
                        height: 1,
                        color: c.border,
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),

                      // User Row
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: 6),

                          Text(
                            '${isReceived ? 'From' : 'To'}: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.textSecondary,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              isReceived
                                  ? (item.senderName.isNotEmpty &&
                                  item.senderName != "Unknown"
                                  ? item.senderName
                                  : item.senderId)
                                  : (item.receiverName.isNotEmpty &&
                                  item.receiverName != "Unknown"
                                  ? item.receiverName
                                  : item.receiverId),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

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
            decoration:
            BoxDecoration(color: c.blueLight, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 34, color: c.blue),
          ),
          const SizedBox(height: 16),
          Text('No transactions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('Your history will appear here',
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}