import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;
  bool _isRTL = false;
  int _currentIndex = 0;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isRTL => _isRTL;
  int get currentIndex => _currentIndex;

  AppProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localeCode = prefs.getString('locale');
    final String? themeModeString = prefs.getString('themeMode');

    if (localeCode != null) {
      _locale = Locale(localeCode);
      _isRTL = localeCode == 'ar';
    }

    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.light,
      );
    }

    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    _isRTL = languageCode == 'ar';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);

    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString());

    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _isRTL ? 'صباح الخير' : 'Good Morning';
    } else if (hour < 17) {
      return _isRTL ? 'مساء الخير' : 'Good Afternoon';
    } else {
      return _isRTL ? 'مساء الخير' : 'Good Evening';
    }
  }
}