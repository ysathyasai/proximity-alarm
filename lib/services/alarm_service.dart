import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_constants.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  bool _hasVibrator = false;
  Timer? _previewTimer;
  Timer? _escalationTimer;
  String? _currentlyPreviewingSoundId;
  void Function(String?)? onPreviewStateChanged;

  bool get isAlarmPlaying => _isAlarmPlaying;
  String? get currentlyPreviewingSoundId => _currentlyPreviewingSoundId;

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
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
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
    VibrationPatternType vibrationPattern = VibrationPatternType.continuous,
    bool volumeEscalation = true,
  }) async {
    if (_isAlarmPlaying) return; // Prevent duplicate playback
    _isAlarmPlaying = true;

    // Stop any preview
    _stopPreview();

    try {
      // 1. Play Alarm Audio in loop mode
      final assetPath = AppConstants.soundAssetPaths[soundId] ??
          AppConstants.soundAssetPaths[AppConstants.soundRadar]!;

      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      if (volumeEscalation) {
        // Start gently at 20% volume and escalate to 100% over 12 seconds
        double currentVolume = 0.25;
        await _audioPlayer.setVolume(currentVolume);
        await _audioPlayer.play(AssetSource(cleanPath));

        _escalationTimer?.cancel();
        _escalationTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
          if (!_isAlarmPlaying) {
            timer.cancel();
            return;
          }
          currentVolume += 0.25;
          if (currentVolume >= 1.0) {
            currentVolume = 1.0;
            _audioPlayer.setVolume(1.0);
            timer.cancel();
          } else {
            _audioPlayer.setVolume(currentVolume);
          }
        });
      } else {
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(AssetSource(cleanPath));
      }
    } catch (_) {
      // Fallback
    }

    // 2. Start vibration according to selected pattern
    if (vibrationEnabled && vibrationPattern != VibrationPatternType.none && _hasVibrator) {
      try {
        final (pattern, intensities) = _getVibrationPatternData(vibrationPattern);
        await Vibration.vibrate(
          pattern: pattern,
          intensities: intensities,
          repeat: 0, // loop from start
        );
      } catch (_) {
        // Fallback
      }
    }
  }

  (List<int>, List<int>) _getVibrationPatternData(VibrationPatternType type) {
    switch (type) {
      case VibrationPatternType.continuous:
        return ([500, 1000, 400, 1000], [0, 255, 0, 255]);
      case VibrationPatternType.pulse:
        return ([300, 300, 300, 300], [0, 255, 0, 255]);
      case VibrationPatternType.heartbeat:
        return ([200, 200, 100, 600], [0, 255, 0, 255]);
      case VibrationPatternType.urgent:
        return ([150, 150, 150, 150, 150, 500], [0, 255, 0, 255, 0, 255]);
      case VibrationPatternType.none:
        return ([], []);
    }
  }

  /// Stops audio and vibration immediately.
  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    _stopPreview();
    _escalationTimer?.cancel();

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      if (_hasVibrator) {
        await Vibration.cancel();
      }
    } catch (_) {}
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    _currentlyPreviewingSoundId = null;
    onPreviewStateChanged?.call(null);
  }

  /// Plays or stops a 3.5-second preview of a selected alarm sound for settings screen.
  Future<void> previewSound(String soundId) async {
    if (_isAlarmPlaying) return;

    if (_currentlyPreviewingSoundId == soundId) {
      // Toggle off if already previewing
      await _audioPlayer.stop();
      _stopPreview();
      return;
    }

    _stopPreview();
    _currentlyPreviewingSoundId = soundId;
    onPreviewStateChanged?.call(soundId);

    try {
      final assetPath = AppConstants.soundAssetPaths[soundId] ??
          AppConstants.soundAssetPaths[AppConstants.soundRadar]!;
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.85);
      await _audioPlayer.play(AssetSource(cleanPath));

      _previewTimer = Timer(const Duration(milliseconds: 3500), () {
        _audioPlayer.stop();
        _currentlyPreviewingSoundId = null;
        onPreviewStateChanged?.call(null);
      });
    } catch (_) {
      _stopPreview();
    }
  }

  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
  }
}
