import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  static const _key = 'app_locale';
  static LocaleNotifier? _instance;

  LocaleNotifier._(super.locale);

  static const supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  static Future<LocaleNotifier> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    final locale = stored != null
        ? supportedLocales.firstWhere(
            (l) => l.languageCode == stored,
            orElse: () => _resolveSystemLocale(),
          )
        : _resolveSystemLocale();
    _instance = LocaleNotifier._(locale);
    return _instance!;
  }

  static Locale _resolveSystemLocale() {
    final system =
        WidgetsBinding.instance.platformDispatcher.locale;
    return supportedLocales.firstWhere(
      (l) => l.languageCode == system.languageCode,
      orElse: () => const Locale('en'),
    );
  }

  static LocaleNotifier get instance {
    if (_instance == null) {
      final system =
          WidgetsBinding.instance.platformDispatcher.locale;
      final locale = supportedLocales.firstWhere(
        (l) => l.languageCode == system.languageCode,
        orElse: () => const Locale('en'),
      );
      _instance = LocaleNotifier._(locale);
    }
    return _instance!;
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  String get displayName => localeName(value);

  static String localeName(Locale locale) {
    return switch (locale.languageCode) {
      'ru' => 'Русский',
      'en' => 'English',
      'de' => 'Deutsch',
      'es' => 'Español',
      'fr' => 'Français',
      'pt' => 'Português',
      _ => locale.languageCode,
    };
  }
}
