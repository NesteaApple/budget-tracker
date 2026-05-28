# Budget Tracker 💸 (Offline-First Architecture)

A beautiful, sleek, and feature-rich budget tracking application built with Flutter and Laravel. Designed with a robust **Offline-First Architecture**, it allows users to track expenses flawlessly in areas with no network coverage, automatically syncing to a cloud database when the connection is restored.

## ✨ Core Features
* **Offline-First Engine:** Built with `sqflite`. Transactions are saved locally first, ensuring zero data loss when offline.
* **Smart Background Syncing:** Uses `connectivity_plus` to detect network restoration and push pending data to the server seamlessly.
* **Auto-Create Budgets:** Send an expense to a new category (e.g., "General Budget") while offline, and the Laravel API will dynamically create that budget category upon syncing.
* **Modern UI/UX:** "Soft Neumorphism" design, Asymmetric gradient cards, Dark/Light mode, and real-time Toast notifications for network status.
* **Secure Authentication:** Token-based security using Laravel Sanctum, cached locally.

---

## 🛠️ System Architecture
* **Frontend:** Flutter (Dart)
* **Local Database:** SQLite (`sqflite`)
* **Backend API:** Laravel 11 (PHP)
* **Cloud Database:** MySQL (via Laragon)
* **State & Network:** `connectivity_plus`, `http`, `shared_preferences`

---

## 🚀 Local Development Setup

To test the offline-to-online sync features reliably (bypassing strict university Wi-Fi firewalls), we utilize a direct Mobile Hotspot testing environment.

### Part 1: The Backend (Laravel)
1. Clone the backend repository and run standard Laravel setup (`composer install`, `.env` configuration).

2. Connect your laptop to your mobile phone's Wi-Fi Hotspot.

3. Run `ipconfig` (Windows) on your laptop and copy the IPv4 address of your Wireless LAN adapter.

### Part 2: The Frontend (Flutter)
1. Clone this repository and run `flutter pub get`.

2. Open `lib/services/api_service.dart`.

3. Update the `baseUrl` with the IPv4 address you copied from your laptop:
   ```dart
   static const String baseUrl = 'http://YOUR_LAPTOP_IP:8000/api';
   ```

4. Connect your Android phone via USB (Debugging Enabled) and run:
   ```bash
   flutter run
   ```



---

## 🧪 Testing the Sync Engine (Defense Demo Guide)

Follow these exact steps to perform a "Clean Slate" test of the offline-to-online architecture.

### Step 1: The Clean Slate (Database Reset)

1. **Reset the Server:** In your Laravel terminal, wipe the database and seed the default user:
   ```bash
   php artisan migrate:fresh --seed
   ```

2. **Start the Server:** Ensure the backend is listening on the local network:
   ```bash
   php artisan serve --host 0.0.0.0 --port 8000
   ```

3. **Reset the App:** On your testing phone, clear the app's Storage & Cache (or reinstall the app) to wipe the local SQLite database and SharedPreferences.

### Step 2: Login & Initial Setup

1. Open the app and log in using the seeded credentials:
   * **Email:** juan@budgetapp.test
   * **Password:** password

2. Keep the phone connected to the Hotspot (Online Mode). The app will initialize.

### Step 3: The Full Data Sync Test (Budgets)

1. Create a new budget in the app (e.g., Name: "Defense Fund", Starting Amount: ₱5000).

2. Tap the **Force Sync (🔄)** button in the AppBar.

3. *Verification:* Check your MySQL `budgets` table. The new budget and its starting amount will appear immediately via the idempotent `updateOrCreate` backend logic.

### Step 4: The Offline-First Transaction Test

1. **Go Offline:** Turn OFF Mobile Data (and Wi-Fi) on the testing phone.

2. **Log an Expense:** Add a new transaction (e.g., ₱250 for "Snacks" under "Defense Fund").

   * *A Red SnackBar will appear confirming the app is offline and data is saved locally to SQLite.*

3. **Go Online:** Turn Mobile Data back ON.
   * *A Green SnackBar will appear confirming network restoration.*
   * *The background `SyncService` will automatically push the pending transaction.*

4. *Verification:* Check your MySQL `transactions` table. The ₱250 expense will be present, and the server will correctly calculate the remaining budget dynamically.

---

## 📦 Building a Release APK

To build the final optimized 60fps version of the app:
   ```bash
   flutter build apk --release
   ```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

