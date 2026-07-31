import 'package:flutter/material.dart';

// ── Design tokens (matches home_screen.dart / login_screen.dart) ──
const _bg = Color(0xFFF7F6F2);
const _surface = Colors.white;
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B68);
const _border = Color(0xFFE9E7E1);

const _purple = Color(0xFF534AB7);
const _purpleDark = Color(0xFF26215C);
const _purpleLight = Color(0xFFEEEDFE);

const _success = Color(0xFF1E9E6F);
const _successLight = Color(0xFFE6F6EF);
const _error = Color(0xFFD64545);
const _errorLight = Color(0xFFFCEAEA);

enum AppSnackType { success, error, info }

/// Drop-in replacement for ScaffoldMessenger snackbars.
///
/// Usage:
///   AppSnack.show(context, "OTP sent successfully");
///   AppSnack.show(context, "Failed to send OTP", type: AppSnackType.error);
class AppSnack {
  static void show(
      BuildContext context,
      String message, {
        AppSnackType type = AppSnackType.info,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _SnackWidget(
        message: message,
        type: type,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  static Color _accent(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return _success;
      case AppSnackType.error:
        return _error;
      case AppSnackType.info:
        return _purple;
    }
  }

  static Color _accentBg(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return _successLight;
      case AppSnackType.error:
        return _errorLight;
      case AppSnackType.info:
        return _purpleLight;
    }
  }

  static IconData _icon(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return Icons.check_rounded;
      case AppSnackType.error:
        return Icons.close_rounded;
      case AppSnackType.info:
        return Icons.info_outline_rounded;
    }
  }
}

class _SnackWidget extends StatefulWidget {
  final String message;
  final AppSnackType type;
  final VoidCallback onDismissed;
  final Duration duration;

  const _SnackWidget({
    required this.message,
    required this.type,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_SnackWidget> createState() => _SnackWidgetState();
}

class _SnackWidgetState extends State<_SnackWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offset = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppSnack._accent(widget.type);
    final accentBg = AppSnack._accentBg(widget.type);
    final icon = AppSnack._icon(widget.type);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _offset,
            child: GestureDetector(
              onTap: () async {
                await _controller.reverse();
                widget.onDismissed();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppDialogType { success, error, info }

/// Drop-in replacement for showDialog(AlertDialog).
///
/// Usage:
///   AppDialog.show(context, title: "Error", message: "Enter a valid number");
///   AppDialog.show(
///     context,
///     title: "Delete account?",
///     message: "This can't be undone.",
///     type: AppDialogType.error,
///     confirmText: "Delete",
///     cancelText: "Cancel",
///     onConfirm: () { ... },
///   );
class AppDialog {
  static Future<void> show(
      BuildContext context, {
        required String title,
        required String message,
        AppDialogType type = AppDialogType.info,
        String confirmText = "OK",
        String? cancelText,
        VoidCallback? onConfirm,
      }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * anim.value),
          child: Opacity(
            opacity: anim.value,
            child: _DialogCard(
              title: title,
              message: message,
              type: type,
              confirmText: confirmText,
              cancelText: cancelText,
              onConfirm: onConfirm,
            ),
          ),
        );
      },
    );
  }
}

class _DialogCard extends StatelessWidget {
  final String title;
  final String message;
  final AppDialogType type;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;

  const _DialogCard({
    required this.title,
    required this.message,
    required this.type,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
  });

  Color get _accent {
    switch (type) {
      case AppDialogType.success:
        return _success;
      case AppDialogType.error:
        return _error;
      case AppDialogType.info:
        return _purple;
    }
  }

  Color get _accentBg {
    switch (type) {
      case AppDialogType.success:
        return _successLight;
      case AppDialogType.error:
        return _errorLight;
      case AppDialogType.info:
        return _purpleLight;
    }
  }

  IconData get _icon {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_rounded;
      case AppDialogType.error:
        return Icons.priority_high_rounded;
      case AppDialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: _accentBg, shape: BoxShape.circle),
                child: Icon(_icon, size: 26, color: _accent),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: _dialogButton(
                        label: cancelText!,
                        filled: false,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _dialogButton(
                      label: confirmText,
                      filled: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        onConfirm?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: filled ? _purple : _purpleLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : _purpleDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}