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
