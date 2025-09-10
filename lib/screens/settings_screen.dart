import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    // List of available primary colors for the user to choose
    final List<MaterialColor> availablePrimaryColors = [
      Colors.teal, Colors.blue, Colors.red, Colors.green,
      Colors.purple, Colors.orange, Colors.pink, Colors.indigo,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text(
            'Theme Mode',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('System Default'),
            value: AppThemeMode.system,
            groupValue: themeService.themeMode.toAppThemeMode(),
            onChanged: (AppThemeMode? value) {
              if (value != null) themeService.setThemeMode(value);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light Mode'),
            value: AppThemeMode.light,
            groupValue: themeService.themeMode.toAppThemeMode(),
            onChanged: (AppThemeMode? value) {
              if (value != null) themeService.setThemeMode(value);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark Mode'),
            value: AppThemeMode.dark,
            groupValue: themeService.themeMode.toAppThemeMode(),
            onChanged: (AppThemeMode? value) {
              if (value != null) themeService.setThemeMode(value);
            },
          ),
          const Divider(height: 32),
          Text(
            'Primary Color',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: availablePrimaryColors.map((color) {
              bool isSelected = themeService.primaryColor.value == color.value;
              return InkWell(
                onTap: () => themeService.setPrimaryColor(color),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.onSurface.withOpacity(0.7), width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [ BoxShadow(color: color.withOpacity(0.5), blurRadius: 5, spreadRadius: 1) ]
                        : [],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
          // Add more settings here if needed (e.g., notifications, language)
        ],
      ),
    );
  }
}

// Extension to convert Material ThemeMode back to AppThemeMode for RadioListTile groupValue
extension MaterialThemeModeExtension on ThemeMode {
  AppThemeMode toAppThemeMode() {
    switch (this) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
      default:
        return AppThemeMode.system;
    }
  }
}
