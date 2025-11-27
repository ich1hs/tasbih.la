import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:vibration/vibration.dart';
import '../models/zikr_model.dart';
import '../models/zikr_chain_model.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

enum ActiveMode { single, chain }

class CounterProvider extends ChangeNotifier {
  ZikrModel? _activeZikr;
  ZikrChainModel? _activeChain;
  ActiveMode _mode = ActiveMode.single;
  
  final AudioService _audioService = AudioService();
  SettingsProvider _settings;

  CounterProvider(this._settings) {
    _loadActiveItem();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
  }

  // Getters
  ActiveMode get mode => _mode;
  ZikrModel? get activeZikr => _activeZikr;
  ZikrChainModel? get activeChain => _activeChain;
  
  int get count {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.currentStep.currentCount;
    }
    return _activeZikr?.currentCount ?? 0;
  }
  
  int get target {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.currentStep.targetCount;
    }
    return _activeZikr?.targetCount ?? 0;
  }
  
  double get progress {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.currentStep.progress;
    }
    return _activeZikr?.progress ?? 0.0;
  }
  
  double get overallProgress {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.overallProgress;
    }
    return progress;
  }
  
  String get zikrName {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.currentStep.name;
    }
    return _activeZikr?.name ?? 'No Zikr Selected';
  }
  
  String? get chainName {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.name;
    }
    return null;
  }
  
  String? get ayahText {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      return _activeChain!.currentStep.ayahText;
    }
    return _activeZikr?.ayahText;
  }
  
  bool get soundEnabled => _settings.soundEnabled;
  
  // Chain specific
  int get currentStepIndex => _activeChain?.currentStepIndex ?? 0;
  int get totalSteps => _activeChain?.steps.length ?? 1;
  bool get isChainCompleted => _activeChain?.isCompleted ?? false;

  Future<void> _loadActiveItem() async {
    final activeId = StorageService.settingsRepository.activeZikrId;
    final activeMode = StorageService.settingsRepository.activeMode;
    
    if (activeMode == 'chain') {
      _mode = ActiveMode.chain;
      if (activeId != null) {
        _activeChain = StorageService.chainRepository.getById(activeId);
      }
      _activeChain ??= StorageService.chainRepository.getAll().firstOrNull;
    } else {
      _mode = ActiveMode.single;
      if (activeId != null) {
        _activeZikr = StorageService.zikrRepository.getById(activeId);
      }
      if (_activeZikr == null) {
        final allZikr = StorageService.zikrRepository.getAll();
        if (allZikr.isNotEmpty) {
          _activeZikr = allZikr.first;
          await StorageService.settingsRepository.setActiveZikrId(_activeZikr!.id);
        }
      }
    }
    notifyListeners();
  }

  Future<void> setActiveZikr(ZikrModel zikr) async {
    _activeZikr = zikr;
    _mode = ActiveMode.single;
    await StorageService.settingsRepository.setActiveZikrId(zikr.id);
    await StorageService.settingsRepository.setActiveMode('single');
    notifyListeners();
  }

  Future<void> setActiveChain(ZikrChainModel chain) async {
    _activeChain = chain;
    _mode = ActiveMode.chain;
    await StorageService.settingsRepository.setActiveZikrId(chain.id);
    await StorageService.settingsRepository.setActiveMode('chain');
    notifyListeners();
  }

  Future<void> increment() async {
    if (_mode == ActiveMode.chain) {
      await _incrementChain();
    } else {
      await _incrementSingle();
    }
  }

  Timer? _debounceTimer;
  int _pendingIncrements = 0;

  Future<void> _incrementSingle() async {
    if (_activeZikr == null) return;

    // Auto-reset if already at or past target
    if (_activeZikr!.currentCount >= _activeZikr!.targetCount && _activeZikr!.targetCount > 0) {
      _activeZikr!.reset();
      if (_settings.vibrationEnabled) HapticFeedback.heavyImpact();
      
      // Flush any pending increments before reset
      if (_pendingIncrements > 0) {
        await StorageService.settingsRepository.addToGlobalTotal(_pendingIncrements);
        _pendingIncrements = 0;
      }
      
      await StorageService.zikrRepository.update(_activeZikr!);
      notifyListeners();
      _updateWidget(); // Immediate update on reset
      return;
    }

    // IMMEDIATE feedback - no await before this!
    if (_settings.vibrationEnabled) HapticFeedback.mediumImpact();
    if (_settings.soundEnabled) _audioService.playTapSound();

    _activeZikr!.increment();
    _pendingIncrements++; // Track locally
    
    final count = _activeZikr!.currentCount;
    final target = _activeZikr!.targetCount;
    
    // Check completion (sound plays sync, no delay)
    if (target > 0 && count == target) {
      _playCompletionFeedback();
      StorageService.settingsRepository.incrementCompletedCount(); // fire-and-forget
      
      // Immediate save on completion - flush pending
      if (_pendingIncrements > 0) {
        await StorageService.settingsRepository.addToGlobalTotal(_pendingIncrements);
        _pendingIncrements = 0;
      }
      
      StorageService.zikrRepository.update(_activeZikr!);
      _updateWidget();
    } else {
      // Debounce storage and widget updates for normal taps
      _scheduleDebouncedUpdate();
    }

    notifyListeners();
  }

  Future<void> _incrementChain() async {
    if (_activeChain == null) return;

    // If chain is fully completed, reset the whole chain
    if (_activeChain!.isCompleted) {
      _activeChain!.reset();
      if (_settings.vibrationEnabled) HapticFeedback.heavyImpact();
      
      // Flush pending
      if (_pendingIncrements > 0) {
        await StorageService.settingsRepository.addToGlobalTotal(_pendingIncrements);
        _pendingIncrements = 0;
      }
      
      await StorageService.chainRepository.update(_activeChain!);
      notifyListeners();
      _updateWidget();
      return;
    }

    final previousStep = _activeChain!.currentStepIndex;
    final stepped = _activeChain!.increment();
    _pendingIncrements++; // Track locally
    
    // IMMEDIATE feedback - no await before this!
    if (stepped) {
      // Step transition - STRONG vibration feedback
      if (_settings.vibrationEnabled) {
        Vibration.hasVibrator().then((has) {
          if (has) Vibration.vibrate(pattern: [0, 100, 50, 100]);
        });
      }
      if (_settings.soundEnabled) _audioService.playMilestoneSound();
    } else {
      // Normal tap
      if (_settings.vibrationEnabled) HapticFeedback.mediumImpact();
      if (_settings.soundEnabled) _audioService.playTapSound();
    }
    
    // Chain completed check
    if (_activeChain!.isCompleted && previousStep == _activeChain!.currentStepIndex) {
      _playCompletionFeedback();
      StorageService.settingsRepository.incrementCompletedCount(); // fire-and-forget
      
      // Immediate save on completion - flush pending
      if (_pendingIncrements > 0) {
        await StorageService.settingsRepository.addToGlobalTotal(_pendingIncrements);
        _pendingIncrements = 0;
      }
      
      StorageService.chainRepository.update(_activeChain!);
      _updateWidget();
    } else {
      // Debounce storage and widget updates
      _scheduleDebouncedUpdate();
    }
    
    notifyListeners();
  }

  void _scheduleDebouncedUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (_mode == ActiveMode.chain && _activeChain != null) {
        StorageService.chainRepository.update(_activeChain!);
      } else if (_activeZikr != null) {
        StorageService.zikrRepository.update(_activeZikr!);
      }
      
      // Flush pending increments
      if (_pendingIncrements > 0) {
        StorageService.settingsRepository.addToGlobalTotal(_pendingIncrements);
        _pendingIncrements = 0;
      }
      
      _updateWidget();
    });
  }

  Future<void> reset() async {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      _activeChain!.reset();
      await StorageService.chainRepository.update(_activeChain!);
    } else if (_activeZikr != null) {
      _activeZikr!.reset();
      await StorageService.zikrRepository.update(_activeZikr!);
    }
    
    if (_settings.vibrationEnabled) {
      HapticFeedback.vibrate();
    }
    notifyListeners();
  }

  Future<void> toggleSound() async {
    await _settings.setSoundEnabled(!_settings.soundEnabled);
    notifyListeners();
  }

  void _playCompletionFeedback() {
    if (_settings.vibrationEnabled) {
      Vibration.hasVibrator().then((has) {
        if (has) Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 400]);
      });
    }
    if (_settings.soundEnabled) {
      _audioService.playCompletionSound();
    }
  }

  Future<void> refreshZikr() async {
    if (_mode == ActiveMode.chain && _activeChain != null) {
      _activeChain = StorageService.chainRepository.getById(_activeChain!.id);
    } else if (_activeZikr != null) {
      _activeZikr = StorageService.zikrRepository.getById(_activeZikr!.id);
    }
    notifyListeners();
  }

  Future<void> _updateWidget() async {
    try {
      final total = StorageService.settingsRepository.globalTotal;
      await HomeWidget.saveWidgetData('globalTotal', total.toString());
      await HomeWidget.updateWidget(
        androidName: 'TasbihWidgetProvider',
      );
    } catch (e) {
      // Widget update failed, ignore
    }
  }
}
