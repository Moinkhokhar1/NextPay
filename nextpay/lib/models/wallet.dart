class Wallet {
  final num balance;
  final num lockedBalance;
  final num offlineBalance;
  final Map<String, dynamic> extra;

  Wallet({
    required this.balance,
    this.lockedBalance = 0,
    this.offlineBalance = 0,
    this.extra = const {},
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    final balance = copy.remove('balance') ?? 0;
    final locked = copy.remove('locked_balance') ?? 0;
    final offline = copy.remove('offline_balance') ?? 0;
    return Wallet(
      balance: _toNum(balance),
      lockedBalance: _toNum(locked),
      offlineBalance: _toNum(offline),
      extra: copy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...extra,
      'balance': balance,
      'locked_balance': lockedBalance,
      'offline_balance': offlineBalance,
    };
  }

  Wallet copyWith({num? balance, num? lockedBalance, num? offlineBalance}) {
    return Wallet(
      balance: balance ?? this.balance,
      lockedBalance: lockedBalance ?? this.lockedBalance,
      offlineBalance: offlineBalance ?? this.offlineBalance,
      extra: extra,
    );
  }
}
num _toNum(dynamic v) =>
    v is num ? v : num.tryParse(v.toString()) ?? 0;