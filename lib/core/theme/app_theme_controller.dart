import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeController extends ChangeNotifier {
  static const _themeModeKey = 'app_theme_mode';
  static final AppThemeController instance = AppThemeController._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppThemeController._();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final value = await _storage.read(key: _themeModeKey);
    _themeMode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _themeModeKey, value: enabled ? 'dark' : 'light');
    notifyListeners();
  }
}
