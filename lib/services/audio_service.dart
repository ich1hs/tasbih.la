import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Pre-loaded sources for instant playback
  final _tapSource = AssetSource('sounds/tapSound.wav');
  final _milestoneSource = AssetSource('sounds/milestone.mp3');
  final _completionSource = AssetSource('sounds/complete.wav');

  // Pool of players for tap sounds
  final List<AudioPlayer> _tapPool = [];
  int _tapPoolIndex = 0;
  static const int _poolSize = 8;
  
  late AudioPlayer _milestonePlayer;
  late AudioPlayer _completionPlayer;
  
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // Initialize pool in parallel for faster startup
      final poolFutures = List.generate(_poolSize, (index) async {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(_tapSource);
        await player.setVolume(0.5);
        return player;
      });

      _tapPool.addAll(await Future.wait(poolFutures));
      
      // Initialize other players
      _milestonePlayer = AudioPlayer();
      await _milestonePlayer.setReleaseMode(ReleaseMode.stop);
      await _milestonePlayer.setSource(_milestoneSource);
      await _milestonePlayer.setVolume(0.15);
      
      _completionPlayer = AudioPlayer();
      await _completionPlayer.setReleaseMode(ReleaseMode.stop);
      await _completionPlayer.setSource(_completionSource);
      await _completionPlayer.setVolume(0.18);
      
      _initialized = true;
    } catch (e) {
      developer.log('Error initializing AudioService: $e', name: 'AudioService');
    }
  }

  void playTapSound() async {
    try {
      if (_tapPool.isEmpty) {
        // Fallback
        final p = AudioPlayer();
        p.play(_tapSource, volume: 0.5);
        return;
      }
      
      // Use round-robin
      final player = _tapPool[_tapPoolIndex];
      _tapPoolIndex = (_tapPoolIndex + 1) % _poolSize;
      
      // Force stop and play - safest way to ensure sound triggers
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.play(_tapSource, volume: 0.5);
    } catch (e) {
      developer.log('Error playing tap sound: $e', name: 'AudioService');
    }
  }

  void playMilestoneSound() async {
    if (!_initialized) return;
    try {
      await _milestonePlayer.stop();
      await _milestonePlayer.play(_milestoneSource, volume: 0.15);
    } catch (e) {
      developer.log('Error playing milestone sound: $e', name: 'AudioService');
    }
  }

  void playCompletionSound() async {
    if (!_initialized) return;
    try {
      await _completionPlayer.stop();
      await _completionPlayer.play(_completionSource, volume: 0.18);
    } catch (e) {
      developer.log('Error playing completion sound: $e', name: 'AudioService');
    }
  }

  void dispose() {
    for (final player in _tapPool) {
      player.dispose();
    }
    _tapPool.clear();
    if (_initialized) {
      _milestonePlayer.dispose();
      _completionPlayer.dispose();
    }
    _initialized = false;
  }
}
