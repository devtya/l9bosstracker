import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ThemeProvider themeProvider = ThemeProvider();

class ThemeProvider extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeProvider() : super(ThemeMode.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') {
      value = ThemeMode.light;
    } else if (saved == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.dark;
    }
  }

  Future<void> toggle() async {
    final newMode = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
