import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  final Box _box;

  SettingsRepository(this._box);

  static const _keySoundEnabled = 'soundEnabled';
  static const _keyActiveZikrId = 'activeZikrId';
  static const _keyVibrationEnabled = 'vibrationEnabled';
  static const _keyThemeMode = 'themeMode'; // 'system', 'light', 'dark'
  static const _keyGlobalTotal = 'globalTotal';
  static const _keyActiveMode = 'activeMode'; // 'single', 'chain'
  static const _keyCompletedCount = 'completedCount';

  bool get soundEnabled => _box.get(_keySoundEnabled, defaultValue: true);
  
  Future<void> setSoundEnabled(bool value) async {
    await _box.put(_keySoundEnabled, value);
  }

  bool get vibrationEnabled => _box.get(_keyVibrationEnabled, defaultValue: true);

  Future<void> setVibrationEnabled(bool value) async {
    await _box.put(_keyVibrationEnabled, value);
  }

  String get themeMode => _box.get(_keyThemeMode, defaultValue: 'system');

  Future<void> setThemeMode(String value) async {
    await _box.put(_keyThemeMode, value);
  }

  int get globalTotal => _box.get(_keyGlobalTotal, defaultValue: 0);

  Future<void> incrementGlobalTotal() async {
    final current = globalTotal;
    await _box.put(_keyGlobalTotal, current + 1);
  }

  Future<void> addToGlobalTotal(int amount) async {
    final current = globalTotal;
    await _box.put(_keyGlobalTotal, current + amount);
  }

  String? get activeZikrId => _box.get(_keyActiveZikrId);

  Future<void> setActiveZikrId(String id) async {
    await _box.put(_keyActiveZikrId, id);
  }

  String get activeMode => _box.get(_keyActiveMode, defaultValue: 'single');

  Future<void> setActiveMode(String mode) async {
    await _box.put(_keyActiveMode, mode);
  }

  int get completedCount => _box.get(_keyCompletedCount, defaultValue: 0);

  Future<void> incrementCompletedCount() async {
    final current = completedCount;
    await _box.put(_keyCompletedCount, current + 1);
  }

  Future<void> resetStats() async {
    await _box.put(_keyGlobalTotal, 0);
    await _box.put(_keyCompletedCount, 0);
  }
}
