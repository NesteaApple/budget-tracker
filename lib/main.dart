import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

// THE GLOBAL LIGHT SWITCH!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const VibeBudgetApp());
}

class VibeBudgetApp extends StatelessWidget {
  const VibeBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'Budget Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          // Auth gate: determine first route asynchronously before rendering.
          home: const _AuthGate(),
        );
      },
    );
  }
}

/// Checks for a stored Sanctum token on startup and routes accordingly.
/// Renders a branded splash while the async check is in progress.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Load the saved dark-mode preference first (mirrors the old loadData logic).
    // This keeps the theme consistent during the splash.
    final token = await ApiService.getToken();

    if (!mounted) return;

    final Widget destination =
        token != null ? const BudgetHomeScreen() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Branded splash screen shown while the token check is in flight.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppTheme.uiGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'Budget Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark
                    ? const Color(0xFF42A5F5)
                    : const Color(0xFF3F51B5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
