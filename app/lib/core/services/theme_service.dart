import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  static ThemeNotifier? _instance;

  ThemeNotifier._(super.mode);

  static Future<ThemeNotifier> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    final mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
    _instance = ThemeNotifier._(mode);
    return _instance!;
  }

  static ThemeNotifier get instance => _instance!;

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    final label = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_key, label);
  }
}
