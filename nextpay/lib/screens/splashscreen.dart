import 'dart:async';
import 'package:flutter/material.dart';

// TODO: replace with your actual home/landing screen import.
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // TODO: swap this delay for real startup logic if needed
    // (e.g. checking auth/login state, loading cached data, etc.)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/splash_icon.png', // padded/small version, not the full-bleed app_icon.png
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/icon/splash_wordmark.png',
              width: 160, // constrain it — without this it renders at native pixel size and looks huge
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}