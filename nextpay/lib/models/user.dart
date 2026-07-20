import 'wallet.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final Wallet? wallet;
  final Map<String, dynamic> extra;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.wallet,
    this.extra = const {},
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    final id = copy.remove('id') ?? copy.remove('_id') ?? '';
    final name = copy.remove('name') ?? '';
    final email = copy.remove('email') ?? '';
    final walletJson = copy.remove('wallet');

    return AppUser(
      id: id.toString(),
      name: name.toString(),
      email: email.toString(),
      wallet: walletJson != null
          ? Wallet.fromJson(Map<String, dynamic>.from(walletJson))
          : null,
      extra: copy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...extra,
      'id': id,
      'name': name,
      'email': email,
      if (wallet != null) 'wallet': wallet!.toJson(),
    };
  }

  AppUser copyWith({Wallet? wallet}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      wallet: wallet ?? this.wallet,
      extra: extra,
    );
  }
}