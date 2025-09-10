import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for Theme Modes
enum AppThemeMode { system, light, dark }

class ThemeService with ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _primaryColorKey = 'app_primary_color';

  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  MaterialColor _primaryColor = Colors.teal; // Default primary color

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;

  ThemeService() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    final String? savedThemeMode = prefs.getString(_themeModeKey);
    if (savedThemeMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
            (e) => e.toString() == savedThemeMode,
        orElse: () => AppThemeMode.system,
      ).toMaterialThemeMode();
    } else {
      _themeMode = ThemeMode.system; // Default if nothing saved
    }

    // Load Primary Color
    final int? savedColorValue = prefs.getInt(_primaryColorKey);
    if (savedColorValue != null) {
      _primaryColor = _findMaterialColor(Color(savedColorValue)) ?? Colors.teal;
    } else {
      _primaryColor = Colors.teal; // Default
    }

    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode.toMaterialThemeMode();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
  }

  Future<void> setPrimaryColor(MaterialColor color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value); // Store the primary color's int value
  }

  // Helper to find MaterialColor from a Color (since MaterialColor has shades)
  // This is a simplification; for a full solution, you might need a predefined map.
  MaterialColor? _findMaterialColor(Color color) {
    List<MaterialColor> materialColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey,
    ];
    for (var mc in materialColors) {
      if (mc.value == color.value) { // Check the primary shade
        return mc;
      }
    }
    return null; // Fallback or handle more gracefully
  }

  // Define your app's light theme data
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: _primaryColor,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: _primaryColor,
      accentColor: _primaryColor == Colors.teal ? Colors.amber : _primaryColor[300], // Adjust accent
      brightness: Brightness.light,
    ).copyWith(
      // primary: _primaryColor[700], // Example: if you need specific shades
      // secondary: _primaryColor[500], // Example
      // error: Colors.redAccent[400],
    ),
    useMaterial3: true,
    // ... copy other theme configurations from your main.dart light theme
    inputDecorationTheme: InputDecorationTheme( /* ... */ ),
    elevatedButtonTheme: ElevatedButtonThemeData( /* ... */ ),
    textButtonTheme: TextButtonThemeData( /* ... */ ),
    appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor, foregroundColor: Colors.white),
    cardTheme: CardThemeData( /* ... */ ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
  );

  // Define your app's dark theme data
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: _primaryColor, // Or a different primary color for dark theme
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: _primaryColor,
      accentColor: _primaryColor == Colors.teal ? Colors.amberAccent : _primaryColor[200], // Adjust accent
      brightness: Brightness.dark,
    ).copyWith(
      // primary: _primaryColor[300], // Example for dark
      // secondary: _primaryColor[100], // Example for dark
      // error: Colors.red[300],
      surface: Colors.grey[850], // Example for dark card/dialog backgrounds
      background: Colors.grey[900], // Example for dark scaffold background
    ),
    useMaterial3: true,
    // ... configure other elements for dark theme as needed
    appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor[700], foregroundColor: Colors.white), // Darker AppBar
    cardTheme: CardThemeData(
      // color: Colors.grey[800], // Example dark card color
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor[400],
      foregroundColor: Colors.black,
    ),
  );
}

// Extension to convert AppThemeMode to Material ThemeMode
extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toMaterialThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }
}
