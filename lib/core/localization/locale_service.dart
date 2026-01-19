import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  late SharedPreferences _prefs;
  late Locale _currentLocale;

  LocaleService() {
    _currentLocale = const Locale('ar');
  }

  Locale get currentLocale => _currentLocale;

  String get languageCode => _currentLocale.languageCode;

  bool get isArabic => _currentLocale.languageCode == 'ar';

  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Initialize the service with saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLocale = _prefs.getString(_localeKey);

    if (savedLocale != null) {
      _currentLocale = Locale(savedLocale);
    } else {
      // Default to Arabic
      _currentLocale = const Locale('ar');
      await _saveLocale('ar');
    }

    notifyListeners();
  }

  /// Change the app locale
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    await _saveLocale(locale.languageCode);
    notifyListeners();
  }

  /// Toggle between Arabic and English
  Future<void> toggleLocale() async {
    final newLocale = isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(newLocale);
  }

  /// Save locale to preferences
  Future<void> _saveLocale(String languageCode) async {
    await _prefs.setString(_localeKey, languageCode);
  }
}
