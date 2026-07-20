import 'package:flutter/material.dart';
import 'package:nextpay/services/app_lock_service.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'offline/wallet_engine.dart';
import 'offline/sync_engine.dart';
import 'offline/network_monitor.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Offline Payment',
          debugShowCheckedModeBanner: false,
          theme: theme.themeData,
          home: const OnboardingGate(child: AppRoot()),
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  NetworkMonitor? _networkMonitor;
  bool _monitorStarted = false;
  bool _locked = true;
  bool _lockInitialized = false;   // ← new: avoids flashing wrong screen before lock state loads
  DateTime? _pausedAt;
  bool? _wasLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLockState();
  }

  Future<void> _initLockState() async {
    final pinSet = await AppLockService.instance.isPinSet();
    setState(() {
      _locked = pinSet;
      _lockInitialized = true;     // ← new
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final pinSet = await AppLockService.instance.isPinSet();
    if (!pinSet) return;

    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          DateTime.now().difference(_pausedAt!) > const Duration(seconds: 30)) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  void dispose() {
    _networkMonitor?.stop();
    super.dispose();
  }

  void _startMonitorIfNeeded() {
    if (_monitorStarted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.hydrated || auth.user == null) return;

    _monitorStarted = true;
    final walletEngine = WalletEngine(auth);
    final syncEngine = SyncEngine(auth, walletEngine);
    _networkMonitor = NetworkMonitor(syncEngine);
    _networkMonitor!.start(auth.fetchWallet);
    debugPrint("NETWORK MONITOR INITIALIZED");
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.user != null && auth.token != null) {
      _startMonitorIfNeeded();
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}