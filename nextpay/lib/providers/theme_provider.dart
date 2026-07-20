// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDark = false;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await StorageService.getItem('theme_mode');
    isDark = saved == 'dark';
    notifyListeners();
  }

  Future<void> toggle() async {
    isDark = !isDark;
    await StorageService.setItem('theme_mode', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  ThemeData get themeData => isDark ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    fontFamily: 'SF Pro Display',
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F13),
    fontFamily: 'SF Pro Display',
  );
}