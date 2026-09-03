class WalletEngine {
  final AuthProvider authProvider;

  WalletEngine(this.authProvider);

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<Map<String, dynamic>> lockBalance(num amount) async {
    try {
      final user = authProvider.user;

      if (user?.wallet == null) {
        return {"success": false, "message": "Wallet not found"};
      }

      final wallet = user!.wallet!;
      final currentOfflineBalance = wallet.offlineBalance;
      final currentLocked = wallet.lockedBalance;

      if (amount > currentOfflineBalance - currentLocked) {
        return {
          "success": false,
          "message": "Insufficient offline wallet balance. Recharge your "
              "offline wallet to make offline payments.",
        };
      }

      final updatedWallet = wallet.copyWith(
        lockedBalance: currentLocked + amount,
      );

      if (kDebugMode) {
        debugPrint(
            "LOCK: amount=$amount before=$currentLocked after=${updatedWallet.lockedBalance}");
      }

      authProvider.setUserWallet(updatedWallet);

      await _secureStorage.write(
        key: "local_wallet",
        value: jsonEncode(updatedWallet.toJson()),
      );

      final userData = await _secureStorage.read(key: "user");
      if (userData != null) {
        final parsedUser =
        AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(userData)));
        final updatedUser = parsedUser.copyWith(wallet: updatedWallet);
        await _secureStorage.write(
          key: "user",
          value: jsonEncode(updatedUser.toJson()),
        );
      }

      return {"success": true};
    } catch (error) {
      if (kDebugMode) debugPrint("LOCK BALANCE ERROR: $error");
      return {"success": false};
    }
  }

  Future<Map<String, dynamic>> unlockBalance(num amount) async {
    try {
      final user = authProvider.user;
      if (user?.wallet == null) {
        return {"success": false};
      }

      final wallet = user!.wallet!;
      final updatedLocked =
      (wallet.lockedBalance - amount) < 0 ? 0 : wallet.lockedBalance - amount;

      final updatedWallet = wallet.copyWith(lockedBalance: updatedLocked);

      if (kDebugMode) {
        debugPrint("UNLOCK: amount=$amount after=$updatedLocked");
      }

      authProvider.setUserWallet(updatedWallet);

      if (updatedLocked == 0) {
        await _secureStorage.delete(key: "local_wallet");
      } else {
        await _secureStorage.write(
          key: "local_wallet",
          value: jsonEncode(updatedWallet.toJson()),
        );
      }

      final userData = await _secureStorage.read(key: "user");
      if (userData != null) {
        final parsedUser =
        AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(userData)));
        final updatedUser = parsedUser.copyWith(wallet: updatedWallet);
        await _secureStorage.write(
          key: "user",
          value: jsonEncode(updatedUser.toJson()),
        );
      }

      return {"success": true};
    } catch (error) {
      if (kDebugMode) debugPrint("UNLOCK BALANCE ERROR: $error");
      return {"success": false};
    }
  }
}