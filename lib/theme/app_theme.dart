import 'package:flutter/material.dart';

class AppTheme {
  // Gradients look amazing in both Light and Dark mode, so they stay constant!
  static const LinearGradient incomeGradient = LinearGradient(colors: [Color(0xFF81C784), Color(0xFF388E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient expenseGradient = LinearGradient(colors: [Color(0xFFFF8A80), Color(0xFFE53935)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient uiGradient = LinearGradient(colors: [Color(0xFF7986CB), Color(0xFF3F51B5)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static BoxDecoration asymmetricCard(LinearGradient gradient) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(24)),
      boxShadow: [BoxShadow(color: gradient.colors.last.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
    );
  }

  // ==========================================
  // ☀️ LIGHT THEME
  // ==========================================
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F6FB), // Soft blue-white
    cardColor: Colors.white,
    primaryColor: const Color(0xFF2D3142), // Dark Navy text
    hintColor: const Color(0xFF9C9EB9), // Soft gray text
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2D3142),
      secondary: Color(0xFF4CAF50), // Green
      error: Color(0xFFE53935), // Red
      tertiary: Color(0xFFFF9800), // Orange
      surface: Colors.white,
    ),
    useMaterial3: true,
  );

  // ==========================================
  // 🌙 DARK THEME
  // ==========================================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Deep Midnight Indigo
    cardColor: const Color(0xFF252542), // Slightly elevated dark card
    primaryColor: Colors.white, // White text
    hintColor: const Color(0xFF8E8EA8), // Muted dark text
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF252542), surfaceTintColor: Colors.transparent),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF252542), surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF252542), surfaceTintColor: Colors.transparent),
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF81C784), // Lighter neon green
      error: Color(0xFFFF8A80), // Lighter neon red
      tertiary: Color(0xFFFFB74D), // Lighter neon orange
      surface: Color(0xFF252542),
    ),
    useMaterial3: true,
  );
}