import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;

  SettingsProvider() {
    _loadSettings();
  }

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  ThemeMode get themeMode => _themeMode;

  void _loadSettings() {
    final repo = StorageService.settingsRepository;
    _soundEnabled = repo.soundEnabled;
    _vibrationEnabled = repo.vibrationEnabled;
    
    final mode = repo.themeMode;
    if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await StorageService.settingsRepository.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await StorageService.settingsRepository.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    
    await StorageService.settingsRepository.setThemeMode(value);
    notifyListeners();
  }
}
