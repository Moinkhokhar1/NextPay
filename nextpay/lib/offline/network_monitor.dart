import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sync_engine.dart';
import 'dart:async';
import 'dart:io';

/// Combines connectivity_plus listener + periodic real internet check
class NetworkMonitor {
  final SyncEngine syncEngine;
  bool _alreadySyncing = false;
  bool _isFirstEvent = true;
  bool _lastKnownOnline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollingTimer;
  Future<void> Function()? _fetchWallet;

  NetworkMonitor(this.syncEngine);

  void start(Future<void> Function() fetchWallet) async {
    _fetchWallet = fetchWallet;

    _lastKnownOnline = await _hasRealInternet();
    debugPrint("NETWORK MONITOR STARTED — initial: ${_lastKnownOnline ? 'ONLINE' : 'OFFLINE'}");

    // 1. connectivity_plus listener (catches most cases)
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      await _checkAndSync();
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkAndSync();
    });
  }

  Future<void> _checkAndSync() async {
    final isConnected = await _hasRealInternet();

    // Only act on state CHANGE — online→offline or offline→online
    if (isConnected == _lastKnownOnline) return;
    _lastKnownOnline = isConnected;

    debugPrint("Network changed: ${isConnected ? 'ONLINE' : 'OFFLINE'}");

    if (isConnected && !_alreadySyncing) {
      _alreadySyncing = true;
      debugPrint("Internet restored. Syncing...");

      final result = await syncEngine.syncPendingTransactions();
      debugPrint("AUTO SYNC: $result");

      if (result["success"] == true) {
        await _fetchWallet?.call();
      }

      _alreadySyncing = false;
    }
  }

  // Actually tries to connect to Google DNS — much more reliable than connectivity_plus
  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Call this from your UI to get current status instantly
  Future<bool> isOnline() => _hasRealInternet();

  void stop() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
  }
}