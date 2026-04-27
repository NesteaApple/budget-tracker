import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

// THE GLOBAL LIGHT SWITCH!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const VibeBudgetApp());
}

class VibeBudgetApp extends StatelessWidget {
  const VibeBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder "listens" to the switch. When flipped, it rebuilds the app!
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'Budget Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme, // Our Light CSS
          darkTheme: AppTheme.darkTheme, // Our Dark CSS
          themeMode: currentMode, // The current state of the switch
          home: const BudgetHomeScreen(),
        );
      },
    );
  }
}