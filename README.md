
# Vibe Budget Tracker 💸

A beautiful, sleek, and feature-rich offline budget tracking app built with Flutter. It features a modern dark/light mode, multi-budget compartmentalization, and real-time expense visualization.

## ✨ Features
* **Multi-Budget System:** Create separate budgets for School, Shopee, Groceries, etc.
* **Modern UI:** "Soft Neumorphism" design with asymmetric gradient cards.
* **Dark Mode:** Deep Indigo midnight theme built-in.
* **Batch Operations:** Quickly select and delete multiple transactions at once.
* **Smart Visualization:** Dynamic circular progress rings that change color based on budget health.
* **100% Offline:** All data is saved securely on your device using `SharedPreferences`.

---

## 🛠️ How to Setup and Run on a New Computer

### Prerequisites
Before you begin, ensure you have the following installed on your machine:
1. **Flutter SDK:** [Download and Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Android Studio:** Required for the Android SDK and command-line tools.
3. **VS Code:** Recommended code editor with the Flutter extension installed.

### Installation Steps
1. **Clone the repository** (or download the ZIP and extract it):
   ```bash
   git clone 
    https://github.com/NesteaApple/budget-tracker.git
    https://github.com/NesteaApple/budget-tracker.git
   ```
2. **Navigate into the project folder:**
   ```bash
   cd vibe-budget-app
   ```
3. **Download the dependencies:**
   Flutter needs to grab the required packages (like `shared_preferences`).
   ```bash
   flutter pub get
   ```

### Running the App
1. Connect your Android phone via USB (ensure **USB Debugging** is turned ON in Developer Options).
2. Verify your device is connected by looking at the bottom right corner of VS Code, or by running:
   ```bash
   flutter devices
   ```
3. Run the app in Debug Mode:
   ```bash
   flutter run
   ```

---

## 🚀 Building a Release APK (For Your Phone)
If you want to build the final, optimized 60fps version of the app to install permanently:

1. Run the build command:
   ```bash
   flutter build apk --release
   ```
2. Once finished, you can find the `.apk` file located at:
   `[Project_Folder]/build/app/outputs/flutter-apk/app-release.apk`
3. Transfer this file to your phone and tap it to install!
