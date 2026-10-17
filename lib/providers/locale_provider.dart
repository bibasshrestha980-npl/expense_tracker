import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const preferenceKey = 'app_locale';

  Locale? _locale;

  /// Active locale or null if following system locale.
  Locale? get locale => _locale;

  /// String code: 'system', 'en', or 'ne'.
  String get languageCode => _locale?.languageCode ?? 'system';

  bool get isNepali => _locale?.languageCode == 'ne';
  bool get isEnglish => _locale?.languageCode == 'en';

  Future<void> load() async {
    try {
      final saved = await _preferences.getString(preferenceKey);
      if (saved == 'en') {
        _locale = const Locale('en');
      } else if (saved == 'ne') {
        _locale = const Locale('ne');
      } else {
        _locale = null;
      }
    } catch (_) {
      _locale = null;
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _preferences.remove(preferenceKey);
      _locale = null;
    } else {
      await _preferences.setString(preferenceKey, locale.languageCode);
      _locale = locale;
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code == 'en') {
      await setLocale(const Locale('en'));
    } else if (code == 'ne') {
      await setLocale(const Locale('ne'));
    } else {
      await setLocale(null);
    }
  }

  Future<void> toggleLocale() async {
    if (isNepali) {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ne'));
    }
  }
}
