// lib/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;

  const AppColors({required this.isDark});

  // ── Backgrounds ───────────────────────────────────────────────────
  Color get bg         => isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F5F7);
  Color get surface    => isDark ? const Color(0xFF1C1C22) : const Color(0xFFFFFFFF);
  Color get surfaceAlt => isDark ? const Color(0xFF26262F) : const Color(0xFFF0F0F5);

  // ── Border ────────────────────────────────────────────────────────
  Color get border => isDark ? const Color(0xFF2E2E3A) : const Color(0xFFE8E8EE);

  // ── Text ──────────────────────────────────────────────────────────
  Color get textPrimary   => isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A2E);
  Color get textSecondary => isDark ? const Color(0xFF8E8EA0) : const Color(0xFF6B6B80);

  // ── Purple (primary) ──────────────────────────────────────────────
  Color get purple      => isDark ? const Color(0xFF9D7BFF) : const Color(0xFF6C47FF);
  Color get purpleDark  => isDark ? const Color(0xFFBBA4FF) : const Color(0xFF4A2FCC);
  Color get purpleLight => isDark ? const Color(0xFF9D7BFF).withOpacity(0.15)
      : const Color(0xFF6C47FF).withOpacity(0.08);

  // ── Teal ──────────────────────────────────────────────────────────
  Color get teal      => isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
  Color get tealLight => isDark ? const Color(0xFF2DD4BF).withOpacity(0.15)
      : const Color(0xFF0D9488).withOpacity(0.08);

  // ── Amber ─────────────────────────────────────────────────────────
  Color get amber      => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get amberLight => isDark ? const Color(0xFFFBBF24).withOpacity(0.15)
      : const Color(0xFFD97706).withOpacity(0.08);

  // ── Blue ──────────────────────────────────────────────────────────
  Color get blue      => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  Color get blueLight => isDark ? const Color(0xFF60A5FA).withOpacity(0.15)
      : const Color(0xFF2563EB).withOpacity(0.08);

  // ── Success ───────────────────────────────────────────────────────
  Color get successText => isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
  Color get successBg   => isDark ? const Color(0xFF4ADE80).withOpacity(0.15)
      : const Color(0xFF16A34A).withOpacity(0.08);

  // ── Danger ────────────────────────────────────────────────────────
  Color get dangerText => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  Color get dangerBg   => isDark ? const Color(0xFFF87171).withOpacity(0.15)
      : const Color(0xFFDC2626).withOpacity(0.08);
}