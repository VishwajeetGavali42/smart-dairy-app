import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static ThemeMode get currentThemeMode => themeModeNotifier.value;
  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF8FAFA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF087F73),
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF14213D),
        elevation: 0,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF0B132B),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        brightness: Brightness.dark,
        surface: const Color(0xFF1C2541),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1C2541),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C2541),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
