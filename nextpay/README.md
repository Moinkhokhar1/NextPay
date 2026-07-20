cat > /mnt/user-data/outputs/README_flutter.md << 'EOF'
# 📱 NextPay — Flutter

> **Offline-first payment app built with Flutter. Send money without internet, sync when connected.**

NextPay is the Flutter mobile client for the OfflinePay ecosystem. It works completely offline using local storage and cryptographic signatures, syncing transactions to the backend when internet is restored.

---

## ✨ Features

### 💳 Wallet
- Real-time balance with locked/available split
- Balance visibility toggle (show/hide)
- Auto-refresh after every transaction

### 💸 Send Money
- Send to any wallet via User ID
- Quick amount chips (₹50, ₹100, ₹200, ₹500)
- QR scanner for instant receiver fill
- Animated success modal with haptic feedback
- Works online and offline

### 📴 Offline Mode
- Transactions signed with SHA256 and saved locally
- Balance locked during offline — prevents overspending
- Pending queue shows all offline transactions
- Auto-sync when internet is restored
- Manual sync via "Sync Transactions" button

### 🔊 SoundBox Integration
- Paired soundbox app announces payments in Hindi & English
- Works via backend polling

### 📜 History
- Full transaction history (sent + received)
- Online/Offline badge per transaction
- Summary strip with totals

### 👤 Profile
- QR code for receiving payments
- Share QR as image
- Member since, email, user ID

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider |
| HTTP Client | Dio |
| Local Storage | SharedPreferences |
| Cryptography | SHA256 (crypto package) |
| QR Code | qr_flutter, mobile_scanner |
| TTS | flutter_tts |
| Connectivity | connectivity_plus |
| UUID | uuid |
| Haptics | vibration |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry + NetworkMonitor init
├── models/
│   ├── user.dart
│   ├── wallet.dart
│   ├── transaction.dart       # OfflineTransaction model
│   └── wallet_transaction.dart
├── providers/
│   └── auth_provider.dart     # Auth + wallet state
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart       # Dashboard + sync trigger
│   ├── send_screen.dart       # Send money (online + offline)
│   ├── scanner_screen.dart    # QR scanner
│   ├── pending_screen.dart    # Offline queue
│   ├── history_screen.dart    # Transaction history
│   ├── profile_screen.dart    # QR code + user info
│   └── receive_screen.dart
├── services/
│   ├── api_service.dart       # Dio HTTP client
│   ├── auth_service.dart
│   ├── storage_service.dart   # SharedPreferences wrapper
│   ├── sync_service.dart
│   └── wallet_service.dart
└── offline/
    ├── transaction_engine.dart # Create + sign offline txs
    ├── wallet_engine.dart      # Lock/unlock balance locally
    ├── sync_engine.dart        # Sync pending to backend
    └── network_monitor.dart    # Auto-sync on reconnect
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio or Xcode
- Backend server running (see server README)

### 1. Clone the repo
```bash
git clone https://github.com/Moinkhokhar1/NextPay.git
cd NextPay/nextpay
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure API URL

Edit `lib/services/api_service.dart`:
```dart
// For Android emulator
static const String baseUrl = "http://10.0.2.2:8000/api";

// For physical device (use your machine's IP)
static const String baseUrl = "http://192.168.x.x:8000/api";
```

### 4. Run the app
```bash
flutter run
```

---

## 🔄 How Offline Works

```
User sends payment (no internet)
        ↓
Balance locked locally (SharedPreferences)
        ↓
Transaction signed with SHA256
        ↓
Saved to pending_transactions_{userId}
        ↓
Internet restored → NetworkMonitor detects change
        ↓
Auto-sync POST /sync/transactions
        ↓
Server validates SHA256 signature
        ↓
Balance updated — receiver gets funds
        ↓
Local storage cleared
```

---

## 🔐 Offline Security

Every offline transaction is signed before saving:

```dart
final payload = {
  'txId': uuid,
  'sender': senderId,
  'receiver': receiverId,
  'amount': amount,
  'timestamp': timestamp,
  'nonce': nonce,
  'status': 'pending',
  'synced': false,
};
final signature = sha256(jsonEncode(payload) + SECRET_KEY);
```

The backend verifies this signature before processing — tampered transactions are rejected.

---

## 📱 Screenshots

| Home | Send Money | Pending | History |
|------|------------|---------|---------|
| ![Home](screenshots/home.png) | ![Send](screenshots/sendmoney.png) | ![Pending](screenshots/pending.png) | ![History](screenshots/history.png) |

| Login | Profile | QR Scanner | Sign Up |
|-------|---------|------------|---------|
| ![Login](screenshots/login.png) | ![Profile](screenshots/profile.png) | ![QR](screenshots/qrscan.png) | ![Register](screenshots/signup.png) |

---

## ⚙️ Dependencies

```yaml
dependencies:
  provider: ^6.x
  dio: ^5.x
  shared_preferences: ^2.x
  crypto: ^3.x
  uuid: ^4.x
  connectivity_plus: ^6.x
  qr_flutter: ^4.x
  mobile_scanner: ^5.x
  flutter_tts: ^4.x
  vibration: ^2.x
  share_plus: ^10.x
  screenshot: ^3.x
  path_provider: ^2.x
  device_info_plus: ^10.x
```

---

## 🔧 Known Limitations

- iOS 26 simulator not supported (plugin arm64 issue) — use physical device
- Bluetooth offline announcement requires custom build (expo-dev-client)
- QR offline confirmation modal (coming soon)

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

---

## 📄 License

© 2026 moinworksonlocalhost. All rights reserved.

This project is **not open source**. No part of this codebase may be copied, modified, distributed, or used without explicit written permission from the author.

---

<div align="center">

**Built with ❤️ by Moinworksonlocalhost**

*Making payments accessible everywhere, even without internet*

</div>
