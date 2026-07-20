// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../providers/theme_provider.dart';
// import '../app_colors.dart';
// import '../offline/transaction_engine.dart';
// import '../offline/wallet_engine.dart';
// import '../services/api_service.dart';
// import '../services/contact_cache_service.dart';
// import '../sms_payment/sms_payment_service.dart';
// import 'payment_pin_screen.dart';
// import '../widgets/payment_success_screen.dart';
//
// class PaymentSheetScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverPhone;
//
//   const PaymentSheetScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverPhone,
//   });
//
//   @override
//   State<PaymentSheetScreen> createState() => _PaymentSheetScreenState();
// }
//
// class _PaymentSheetScreenState extends State<PaymentSheetScreen> {
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _noteController = TextEditingController();
//   final FocusNode _amountFocus = FocusNode();
//   final FocusNode _noteFocus = FocusNode();
//   bool _isPaying = false;
//   bool _showNote = false;
//
//   @override
//   void dispose() {
//     _amountController.dispose();
//     _noteController.dispose();
//     _amountFocus.dispose();
//     _noteFocus.dispose();
//     super.dispose();
//   }
//
//   void _dismissKeyboard() => FocusScope.of(context).unfocus();
//
//   Future<bool> _isOnline() async {
//     final connectivity = await Connectivity().checkConnectivity();
//     return connectivity.any((r) => r != ConnectivityResult.none);
//   }
//
//   Future<void> _pay() async {
//     final amountText = _amountController.text.trim();
//
//     if (amountText.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter amount')),
//       );
//       return;
//     }
//
//     final amount = double.tryParse(amountText);
//     if (amount == null || amount <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid amount')),
//       );
//       return;
//     }
//
//     final auth = context.read<AuthProvider>();
//     final wallet = auth.user?.wallet;
//     final locked = (wallet?.lockedBalance ?? 0).toDouble();
//     final balance = (wallet?.balance ?? 0).toDouble();
//     if (amount > balance - locked) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Insufficient balance')),
//       );
//       return;
//     }
//
//     FocusScope.of(context).unfocus();
//
//     final pinOk = await PaymentPinScreen.confirm(context);
//     if (pinOk != true || !mounted) return;
//
//     setState(() => _isPaying = true);
//
//     final online = await _isOnline();
//     if (online) {
//       try {
//         final response = await ApiService.instance.post(
//           '/wallet/transfer',
//           data: {
//             'receiverId': widget.receiverId,
//             'amount': amount,
//             'note': _noteController.text.trim(),
//           },
//         );
//
//         if (!mounted) return;
//
//         await ContactCacheService.instance.save(
//           userId: widget.receiverId,
//           name: widget.receiverName,
//           phone: widget.receiverPhone,
//         );
//
//         final txnId = response.data['transactionId']?.toString() ??
//             response.data['id']?.toString() ??
//             'TXN${DateTime.now().millisecondsSinceEpoch}';
//
//         await _showSuccess(amountText, txnId, 'Online');
//         return;
//       } on DioException catch (e) {
//         debugPrint('ONLINE PAYMENT DioException (${e.type}): $e');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Connection lost. Saving as offline transaction...'),
//             ),
//           );
//         }
//       } catch (e) {
//         debugPrint('ONLINE PAYMENT ERROR: $e');
//         if (mounted) {
//           setState(() => _isPaying = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Payment failed')),
//           );
//         }
//         return;
//       }
//     }
//
//     await _doOfflinePay(auth, amount, amountText);
//   }
//
//   Future<void> _doOfflinePay(
//     AuthProvider auth,
//     double amount,
//     String amountText,
//   ) async {
//     try {
//       final walletEngine = WalletEngine(auth);
//       final txEngine = TransactionEngine(auth, walletEngine);
//       final senderId = auth.user?.wallet?.extra['user_id']?.toString() ??
//           auth.user?.id ??
//           '';
//
//       if (senderId.isEmpty) {
//         if (mounted) {
//           setState(() => _isPaying = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User not found. Please login again.')),
//           );
//         }
//         return;
//       }
//
//       final result = await txEngine.createOfflineTransaction(
//         senderId: senderId,
//         receiverId: widget.receiverId,
//         amount: amount,
//         senderName: auth.user?.name,
//       );
//
//       if (result['success'] != true) {
//         if (mounted) {
//           setState(() => _isPaying = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result['message']?.toString() ?? 'Offline payment failed'),
//             ),
//           );
//         }
//         return;
//       }
//
//       final smsResult = await SmsPaymentService.instance.sendPayment(
//         senderId: senderId,
//         receiverId: widget.receiverId,
//         amount: amount,
//       );
//       debugPrint(smsResult.success
//           ? 'SMS SENT: ${smsResult.payload}'
//           : 'SMS FAILED: ${smsResult.message}');
//
//       await ContactCacheService.instance.save(
//         userId: widget.receiverId,
//         name: widget.receiverName,
//         phone: widget.receiverPhone,
//       );
//
//       final tx = result['transaction'];
//       final txnId = tx?.txId?.toString() ??
//           result['transactionId']?.toString() ??
//           'OFF${DateTime.now().millisecondsSinceEpoch}';
//
//       if (!mounted) return;
//       await _showSuccess(amountText, txnId, 'Offline');
//     } catch (e) {
//       debugPrint('OFFLINE PAYMENT ERROR: $e');
//       if (mounted) {
//         setState(() => _isPaying = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Something went wrong')),
//         );
//       }
//     }
//   }
//
//   Future<void> _showSuccess(
//     String amountText,
//     String txnId,
//     String mode,
//   ) async {
//     await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => PaymentSuccessScreen(
//           amount: amountText,
//           receiverName: widget.receiverName,
//           transactionId: txnId,
//         ),
//       ),
//     );
//     if (mounted) Navigator.of(context).pop(true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = context.watch<ThemeProvider>();
//     final c = AppColors(isDark: theme.isDark);
//
//     return Scaffold(
//       backgroundColor: c.bg,
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: c.bg,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_rounded,
//               color: c.textPrimary, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: GestureDetector(
//         onTap: _dismissKeyboard,
//         behavior: HitTestBehavior.opaque,
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: IntrinsicHeight(
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 8),
//                         CircleAvatar(
//                           radius: 34,
//                           backgroundColor: c.purpleLight,
//                           child: Text(
//                             widget.receiverName.isNotEmpty
//                                 ? widget.receiverName[0].toUpperCase()
//                                 : '?',
//                             style: TextStyle(
//                               color: c.purple,
//                               fontSize: 22,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 14),
//                         Text(
//                           widget.receiverName,
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.w700,
//                             color: c.textPrimary,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           widget.receiverPhone,
//                           style: TextStyle(
//                             color: c.textSecondary,
//                             fontSize: 13,
//                           ),
//                         ),
//                         const Spacer(),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Text(
//                               '₹',
//                               style: TextStyle(
//                                 fontSize: 44,
//                                 fontWeight: FontWeight.w600,
//                                 color: c.textPrimary,
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             IntrinsicWidth(
//                               child: ConstrainedBox(
//                                 constraints: const BoxConstraints(minWidth: 40),
//                                 child: TextField(
//                                   controller: _amountController,
//                                   focusNode: _amountFocus,
//                                   autofocus: true,
//                                   keyboardType: const TextInputType.numberWithOptions(
//                                     decimal: true,
//                                   ),
//                                   textInputAction: TextInputAction.done,
//                                   onSubmitted: (_) => _dismissKeyboard(),
//                                   textAlign: TextAlign.left,
//                                   style: TextStyle(
//                                     fontSize: 44,
//                                     fontWeight: FontWeight.w600,
//                                     color: c.textPrimary,
//                                   ),
//                                   decoration: InputDecoration(
//                                     border: InputBorder.none,
//                                     hintText: '0',
//                                     hintStyle: TextStyle(
//                                       color: c.textSecondary.withOpacity(0.5),
//                                       fontSize: 44,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                     isDense: true,
//                                     contentPadding: EdgeInsets.zero,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         if (!_showNote)
//                           TextButton(
//                             onPressed: () => setState(() {
//                               _showNote = true;
//                             }),
//                             child: Text(
//                               'Add note',
//                               style: TextStyle(
//                                 color: c.purple,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           )
//                         else
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: c.surface,
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(color: c.border),
//                             ),
//                             child: TextField(
//                               controller: _noteController,
//                               focusNode: _noteFocus,
//                               maxLines: 2,
//                               textInputAction: TextInputAction.done,
//                               onSubmitted: (_) => _dismissKeyboard(),
//                               style: TextStyle(
//                                 color: c.textPrimary,
//                                 fontSize: 15,
//                               ),
//                               decoration: InputDecoration(
//                                 hintText: 'Add a note',
//                                 hintStyle: TextStyle(color: c.textSecondary),
//                                 border: InputBorder.none,
//                                 isDense: true,
//                               ),
//                             ),
//                           ),
//                         const Spacer(),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             color: c.amberLight,
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(color: c.border),
//                           ),
//                           child: Text(
//                             'Offline? Payment is saved locally and synced when internet returns.',
//                             style: TextStyle(
//                               color: c.textPrimary,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 56,
//                           child: ElevatedButton(
//                             onPressed: _isPaying ? null : _pay,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: c.purple,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: _isPaying
//                                 ? const SizedBox(
//                                     width: 22,
//                                     height: 22,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2.5,
//                                       color: Colors.white,
//                                     ),
//                                   )
//                                 : const Text(
//                                     'Send',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_colors.dart';
import '../offline/transaction_engine.dart';
import '../offline/wallet_engine.dart';
import '../services/api_service.dart';
import '../services/contact_cache_service.dart';
import '../sms_payment/sms_payment_service.dart';
import 'payment_pin_screen.dart';
import '../widgets/payment_success_screen.dart';

class PaymentSheetScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPhone;

  const PaymentSheetScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhone,
  });

  @override
  State<PaymentSheetScreen> createState() => _PaymentSheetScreenState();
}

class _PaymentSheetScreenState extends State<PaymentSheetScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();
  bool _isPaying = false;
  bool _showNote = false;

  // Minimum amount allowed for a transfer.
  static const double kMinTransferAmount = 1.0;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<bool> _isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _pay() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    if (amount < kMinTransferAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Minimum amount is ₹${kMinTransferAmount.toStringAsFixed(0)}'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = auth.user?.wallet;
    final locked = (wallet?.lockedBalance ?? 0).toDouble();
    final balance = (wallet?.balance ?? 0).toDouble();
    if (amount > balance - locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final pinOk = await PaymentPinScreen.confirm(context);
    if (pinOk != true || !mounted) return;

    setState(() => _isPaying = true);

    final online = await _isOnline();
    if (online) {
      try {
        final response = await ApiService.instance.post(
          '/wallet/transfer',
          data: {
            'receiverId': widget.receiverId,
            'amount': amount,
            'note': _noteController.text.trim(),
          },
        );

        if (!mounted) return;

        await ContactCacheService.instance.save(
          userId: widget.receiverId,
          name: widget.receiverName,
          phone: widget.receiverPhone,
        );

        final txnId = response.data['transactionId']?.toString() ??
            response.data['id']?.toString() ??
            'TXN${DateTime.now().millisecondsSinceEpoch}';

        await _showSuccess(amountText, txnId, 'Online');
        return;
      } on DioException catch (e) {
        debugPrint('ONLINE PAYMENT DioException (${e.type}): $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection lost. Saving as offline transaction...'),
            ),
          );
        }
      } catch (e) {
        debugPrint('ONLINE PAYMENT ERROR: $e');
        if (mounted) {
          setState(() => _isPaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed')),
          );
        }
        return;
      }
    }

    await _doOfflinePay(auth, amount, amountText);
  }

  Future<void> _doOfflinePay(
      AuthProvider auth,
      double amount,
      String amountText,
      ) async {
    try {
      final walletEngine = WalletEngine(auth);
      final txEngine = TransactionEngine(auth, walletEngine);
      final senderId = auth.user?.wallet?.extra['user_id']?.toString() ??
          auth.user?.id ??
          '';

      if (senderId.isEmpty) {
        if (mounted) {
          setState(() => _isPaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found. Please login again.')),
          );
        }
        return;
      }

      final result = await txEngine.createOfflineTransaction(
        senderId: senderId,
        receiverId: widget.receiverId,
        amount: amount,
        senderName: auth.user?.name,
      );

      if (result['success'] != true) {
        if (mounted) {
          setState(() => _isPaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Offline payment failed'),
            ),
          );
        }
        return;
      }

      final smsResult = await SmsPaymentService.instance.sendPayment(
        senderId: senderId,
        receiverId: widget.receiverId,
        amount: amount,
      );
      debugPrint(smsResult.success
          ? 'SMS SENT: ${smsResult.payload}'
          : 'SMS FAILED: ${smsResult.message}');

      await ContactCacheService.instance.save(
        userId: widget.receiverId,
        name: widget.receiverName,
        phone: widget.receiverPhone,
      );

      final tx = result['transaction'];
      final txnId = tx?.txId?.toString() ??
          result['transactionId']?.toString() ??
          'OFF${DateTime.now().millisecondsSinceEpoch}';

      if (!mounted) return;
      await _showSuccess(amountText, txnId, 'Offline');
    } catch (e) {
      debugPrint('OFFLINE PAYMENT ERROR: $e');
      if (mounted) {
        setState(() => _isPaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    }
  }

  Future<void> _showSuccess(
      String amountText,
      String txnId,
      String mode,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: amountText,
          receiverName: widget.receiverName,
          transactionId: txnId,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors(isDark: theme.isDark);

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: c.purpleLight,
                          child: Text(
                            widget.receiverName.isNotEmpty
                                ? widget.receiverName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: c.purple,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.receiverName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.receiverPhone,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 40),
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocus,
                                  autofocus: true,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _dismissKeyboard(),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: c.textSecondary.withOpacity(0.5),
                                      fontSize: 44,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!_showNote)
                          TextButton(
                            onPressed: () => setState(() {
                              _showNote = true;
                            }),
                            child: Text(
                              'Add note',
                              style: TextStyle(
                                color: c.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: TextField(
                              controller: _noteController,
                              focusNode: _noteFocus,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _dismissKeyboard(),
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a note',
                                hintStyle: TextStyle(color: c.textSecondary),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: c.amberLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            'Offline? Payment is saved locally and synced when internet returns.',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isPaying ? null : _pay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isPaying
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Send',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}