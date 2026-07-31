import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../models/wallet_transaction.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'transaction_detail_screen.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _TxFilter { all, received, sent, online, offline }

class _HistoryScreenState extends State<HistoryScreen> {
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  bool _loadStarted = false;
  VoidCallback? _authListener;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _TxFilter _filter = _TxFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartLoad());
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
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
    _searchController.dispose();
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

  String _counterpartyName(WalletTransaction tx, bool isReceived) {
    return isReceived
        ? (tx.senderName.isNotEmpty && tx.senderName != "Unknown"
        ? tx.senderName
        : tx.senderId)
        : (tx.receiverName.isNotEmpty && tx.receiverName != "Unknown"
        ? tx.receiverName
        : tx.receiverId);
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

  // ── Grouping / filtering ─────────────────────────────────────────────────
  // Builds a flat list alternating month headers ("JULY, 2026") and
  // transaction rows, in the same order the API returns them (newest first).

  List<Object> _buildListItems(String? currentUserId) {
    var filtered = _transactions.where((tx) {
      final isReceived = tx.receiverId == currentUserId;

      switch (_filter) {
        case _TxFilter.received:
          if (!isReceived) return false;
          break;
        case _TxFilter.sent:
          if (isReceived) return false;
          break;
        case _TxFilter.online:
          if (tx.isOffline) return false;
          break;
        case _TxFilter.offline:
          if (!tx.isOffline) return false;
          break;
        case _TxFilter.all:
          break;
      }

      if (_query.isEmpty) return true;
      final name = _counterpartyName(tx, isReceived).toLowerCase();
      final amountStr = tx.amount.toString();
      return name.contains(_query) || amountStr.contains(_query);
    }).toList();

    final items = <Object>[];
    String? lastMonthKey;
    for (final tx in filtered) {
      final monthKey = DateFormat('MMMM, yyyy').format(tx.createdAt).toUpperCase();
      if (monthKey != lastMonthKey) {
        items.add(monthKey);
        lastMonthKey = monthKey;
      }
      items.add(tx);
    }
    return items;
  }

  // ── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet(AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget option(String label, _TxFilter value) {
          final selected = _filter == value;
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.purple : c.textPrimary,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_rounded, color: c.purple, size: 20)
                : null,
            onTap: () {
              setState(() => _filter = value);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter transactions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary),
                  ),
                ),
              ),
              option('All', _TxFilter.all),
              option('Received', _TxFilter.received),
              option('Sent', _TxFilter.sent),
              option('Online', _TxFilter.online),
              option('Offline', _TxFilter.offline),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    final currentUserId = _resolveUserId(auth);
    final listItems = _buildListItems(currentUserId);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: c.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Transactions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showFilterSheet(c),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: _filter == _TxFilter.all
                          ? c.textSecondary
                          : c.purple,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: c.border, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _query = value.trim().toLowerCase());
                  },
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search for name or amount',
                    hintStyle:
                    TextStyle(fontSize: 14, color: c.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: c.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: c.textSecondary),
                    )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            if (_filter != _TxFilter.all)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = _TxFilter.all),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.purpleLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filter.name[0].toUpperCase() +
                                _filter.name.substring(1),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.purple),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.close_rounded,
                              size: 14, color: c.purple),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? _TransactionListSkeleton(c: c)
                  : listItems.isEmpty
                  ? _EmptyState(
                  c: c,
                  searching: _query.isNotEmpty || _filter != _TxFilter.all)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  final item = listItems[index];
                  if (item is String) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: index == 0 ? 4 : 20, bottom: 8),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: c.textSecondary,
                        ),
                      ),
                    );
                  }
                  final tx = item as WalletTransaction;
                  final isReceived = tx.receiverId == currentUserId;
                  final isLastInGroup = index == listItems.length - 1 ||
                      listItems[index + 1] is String;
                  return Column(
                    children: [
                      _TxRow(
                        c: c,
                        tx: tx,
                        isReceived: isReceived,
                        personName: _counterpartyName(tx, isReceived),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                tx: tx,
                                isReceived: isReceived,
                                personName: _counterpartyName(tx, isReceived),
                                personPhone: "",
                              ),
                            ),
                          );
                        },
                      ),
                      if (!isLastInGroup)
                        Container(height: 1, color: c.border),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                '© 2025 Built by moinworksonlocalhost',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction row ───────────────────────────────────────────────────────
// Matches the reference design: circular icon, name + "mode • date time"
// subtitle, amount colored green (received) or red (sent) on the right.

class _TxRow extends StatelessWidget {
  final AppColors c;
  final WalletTransaction tx;
  final bool isReceived;
  final String personName;
  final VoidCallback onTap;

  const _TxRow({
    required this.c,
    required this.tx,
    required this.isReceived,
    required this.personName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isReceived ? c.successText : c.dangerText;
    final sign = isReceived ? '+' : '-';
    final amountText = '$sign₹${tx.amount.toStringAsFixed(2)}';
    final subtitle =
        '${tx.isOffline ? "Offline" : "Online"} • ${DateFormat("d MMM yyyy, hh:mm a").format(tx.createdAt)}';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isReceived ? c.successBg : c.dangerBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isReceived
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 20,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amountText,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction list skeleton ────────────────────────────────────────────────

class _TransactionListSkeleton extends StatelessWidget {
  final AppColors c;
  const _TransactionListSkeleton({required this.c});

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _skeletonBox(width: 44, height: 44, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(width: 130, height: 14),
                const SizedBox(height: 6),
                _skeletonBox(width: 150, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _skeletonBox(width: 56, height: 15),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      c: c,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _skeletonBox(width: 90, height: 12),
          const SizedBox(height: 12),
          for (int i = 0; i < 7; i++) _row(),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppColors c;
  final bool searching;
  const _EmptyState({required this.c, this.searching = false});

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
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.receipt_long_rounded,
              size: 34,
              color: c.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No matching transactions' : 'No transactions',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different name or amount'
                : 'Your history will appear here',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton primitives ──────────────────────────────────────────────────────

Widget _skeletonBox({required double width, required double height, double radius = 4}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _ShimmerWrapper extends StatefulWidget {
  final AppColors c;
  final Widget child;
  const _ShimmerWrapper({required this.c, required this.child});

  @override
  State<_ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<_ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.c.border.withOpacity(0.55);
    final highlightColor = widget.c.border.withOpacity(0.15);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 - t * 2, 0),
              end: Alignment(1.0 - t * 2, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}