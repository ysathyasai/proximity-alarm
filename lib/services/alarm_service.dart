import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_constants.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  bool _hasVibrator = false;
  Timer? _previewTimer;

  bool get isAlarmPlaying => _isAlarmPlaying;

  AlarmService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();

      // Configure Android audio context for STREAM_ALARM (bypasses silent mode)
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );
    } catch (_) {
      // Audio/vibration init fallback
    }
  }

  /// Starts the loud, continuous alarm.
  /// Loops audio and vibration until explicitly stopped.
  Future<void> startAlarm({
    required String soundId,
    required bool vibrationEnabled,
  }) async {
    if (_isAlarmPlaying) return; // Prevent duplicate playback
    _isAlarmPlaying = true;

    // Stop any preview
    _previewTimer?.cancel();

    try {
      // 1. Play Alarm Audio in loop mode
      final assetPath = AppConstants.soundAssetPaths[soundId] ??
          AppConstants.soundAssetPaths[AppConstants.soundRadar]!;

      // Remove leading assets/ because AssetSource already assumes assets/
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(cleanPath));
    } catch (_) {
      // Fallback
    }

    // 2. Start continuous vibration pattern: [delay, vibrate, pause, vibrate...]
    if (vibrationEnabled && _hasVibrator) {
      try {
        await Vibration.vibrate(
          pattern: [500, 1000, 400, 1000],
          intensities: [0, 255, 0, 255],
          repeat: 0, // 0 = loop from start of pattern
        );
      } catch (_) {
        // Fallback
      }
    }
  }

  /// Stops audio and vibration immediately.
  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    _previewTimer?.cancel();

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      if (_hasVibrator) {
        await Vibration.cancel();
      }
    } catch (_) {}
  }

  /// Plays a short 3-second preview of a selected alarm sound for settings screen.
  Future<void> previewSound(String soundId) async {
    _previewTimer?.cancel();
    if (_isAlarmPlaying) return;

    try {
      final assetPath = AppConstants.soundAssetPaths[soundId] ??
          AppConstants.soundAssetPaths[AppConstants.soundRadar]!;
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.8);
      await _audioPlayer.play(AssetSource(cleanPath));

      _previewTimer = Timer(const Duration(milliseconds: 3200), () {
        _audioPlayer.stop();
      });
    } catch (_) {}
  }

  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
  }
}
