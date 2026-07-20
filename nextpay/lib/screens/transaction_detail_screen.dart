import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../models/wallet_transaction.dart';

class TransactionDetailScreen extends StatelessWidget {
  final WalletTransaction tx;
  final bool isReceived;
  final String personName;
  final String personPhone;

  const TransactionDetailScreen({
    super.key,
    required this.tx,
    required this.isReceived,
    required this.personName,
    required this.personPhone,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'pm' : 'am';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute$ampm';
  }

  String _displayPhone() {
    if (personPhone.isNotEmpty) return personPhone;
    final fromExtra = isReceived
        ? (tx.extra['sender_phone'] ?? tx.extra['senderPhone'])
        : (tx.extra['receiver_phone'] ?? tx.extra['receiverPhone']);
    return fromExtra?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);
    final phone = _displayPhone();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: BackButton(color: c.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: c.purpleLight,
              child: Text(
                personName.isNotEmpty
                    ? personName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 28,
                  color: c.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isReceived ? "From $personName" : "To $personName",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                phone,
                style: TextStyle(
                  fontSize: 16,
                  color: c.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 30),
            Text(
              "${isReceived ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: c.teal),
                const SizedBox(width: 8),
                Text(
                  tx.status.isNotEmpty ? tx.status : 'Completed',
                  style: TextStyle(
                    color: c.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: c.border),
            const SizedBox(height: 16),
            Text(
              _formatDate(tx.createdAt),
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaction ID",
                      style: TextStyle(color: c.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    tx.id,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text("Mode",
                      style: TextStyle(color: c.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    tx.isOffline ? "Offline Wallet" : "Online Wallet",
                    style: TextStyle(color: c.textPrimary),
                  ),
                  if ((tx.extra['note'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text("Note",
                        style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      tx.extra['note'].toString(),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  if ((tx.extra['nonce']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text("Nonce",
                        style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      tx.extra['nonce'].toString(),
                      style: TextStyle(color: c.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Payments may take up to 3 working days to reflect.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
