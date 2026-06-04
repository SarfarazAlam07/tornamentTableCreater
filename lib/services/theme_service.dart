import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Manages light/dark theme with a gaming look.
class ThemeService {
  final ValueNotifier<bool> isDarkMode = ValueNotifier(true);

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(AppConstants.themeKey) ?? true;
    isDarkMode.value = saved;
  }

  /// Toggle between light and dark mode.
  Future<void> toggleTheme() async {
    final newValue = !isDarkMode.value;
    isDarkMode.value = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeKey, newValue);
  }

  /// Returns the current ThemeData based on dark mode flag.
  ThemeData getTheme(bool isDark) => isDark ? _darkTheme() : _lightTheme();

  // ----- Dark Gaming Theme -----
  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.cyan.shade700,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF0A0A1A),
          background: Color(0xFF05050F),
        ),
        scaffoldBackgroundColor: const Color(0xFF05050F),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0F0F1F),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.cyan, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  // ----- Light Gaming Theme -----
  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.purpleAccent,
          surface: Colors.white,
          background: Color(0xFFF5F5FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5FF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}