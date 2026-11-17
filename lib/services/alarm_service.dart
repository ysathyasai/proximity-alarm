import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_constants.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  bool _hasVibrator = false;
  Timer? _previewTimer;
  Timer? _escalationTimer;
  Timer? _autoDismissTimer;
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

      // Configure Android audio context for STREAM_ALARM (bypasses silent mode & pauses media)
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
    String? customSoundPath,
    required bool vibrationEnabled,
    VibrationPatternType vibrationPattern = VibrationPatternType.continuous,
    bool volumeEscalation = true,
    int volumeRampSeconds = 10,
    double targetVolume = 1.0,
    int maxDurationMinutes = 5,
    VoidCallback? onAutoDismiss,
  }) async {
    if (_isAlarmPlaying) return; // Prevent duplicate playback
    _isAlarmPlaying = true;

    // Stop any preview
    _stopPreview();

    final boundedTargetVolume = targetVolume.clamp(0.1, 1.0);

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      Source audioSource;
      if (soundId == AppConstants.soundCustom &&
          customSoundPath != null &&
          File(customSoundPath).existsSync()) {
        audioSource = DeviceFileSource(customSoundPath);
      } else {
        final assetPath = AppConstants.soundAssetPaths[soundId] ??
            AppConstants.soundAssetPaths[AppConstants.soundRadar]!;
        final cleanPath = assetPath.startsWith('assets/')
            ? assetPath.substring(7)
            : assetPath;
        audioSource = AssetSource(cleanPath);
      }

      if (volumeEscalation && volumeRampSeconds > 0) {
        // Start gently at 25% of target volume and escalate to target over volumeRampSeconds
        double currentVol = boundedTargetVolume * 0.25;
        await _audioPlayer.setVolume(currentVol);
        await _audioPlayer.play(audioSource);

        final totalSteps = (volumeRampSeconds / 2.0).ceil().clamp(2, 20);
        final volStep = (boundedTargetVolume - currentVol) / totalSteps;
        final stepIntervalMs = (volumeRampSeconds * 1000 ~/ totalSteps);

        _escalationTimer?.cancel();
        _escalationTimer = Timer.periodic(
          Duration(milliseconds: stepIntervalMs),
          (timer) {
            if (!_isAlarmPlaying) {
              timer.cancel();
              return;
            }
            currentVol += volStep;
            if (currentVol >= boundedTargetVolume) {
              currentVol = boundedTargetVolume;
              _audioPlayer.setVolume(boundedTargetVolume);
              timer.cancel();
            } else {
              _audioPlayer.setVolume(currentVol);
            }
          },
        );
      } else {
        await _audioPlayer.setVolume(boundedTargetVolume);
        await _audioPlayer.play(audioSource);
      }
    } catch (_) {
      // Primary playback failed (e.g. invalid custom audio codec or missing file)
      // Fail-safe fallback: immediately trigger built-in synthesized radar tone
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(boundedTargetVolume);
        await _audioPlayer.play(AssetSource('sounds/radar.wav'));
      } catch (_) {
        // Audio device unrecoverable
      }
    }

    // Auto-dismiss timeout (prevents battery drain if device is left unattended)
    if (maxDurationMinutes > 0) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(Duration(minutes: maxDurationMinutes), () {
        if (_isAlarmPlaying) {
          stopAlarm();
          onAutoDismiss?.call();
        }
      });
    }

    // 2. Start vibration according to selected pattern with hardware compatibility check
    if (vibrationEnabled &&
        vibrationPattern != VibrationPatternType.none &&
        _hasVibrator) {
      try {
        final (pattern, intensities) = _getVibrationPatternData(vibrationPattern);
        final bool hasCustom = await Vibration.hasCustomVibrationsSupport();
        if (hasCustom && intensities.isNotEmpty) {
          await Vibration.vibrate(
            pattern: pattern,
            intensities: intensities,
            repeat: 0, // loop from start
          );
        } else if (pattern.isNotEmpty) {
          await Vibration.vibrate(
            pattern: pattern,
            repeat: 0,
          );
        } else {
          await Vibration.vibrate(duration: 1000, repeat: 0);
        }
      } catch (_) {
        try {
          await Vibration.vibrate(duration: 1000, repeat: 0);
        } catch (_) {}
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
    _autoDismissTimer?.cancel();

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

  /// Plays or stops a 4-second preview of a selected alarm sound for settings screen.
  Future<void> previewSound(String soundId, {String? customSoundPath}) async {
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
      Source audioSource;
      if (soundId == AppConstants.soundCustom &&
          customSoundPath != null &&
          File(customSoundPath).existsSync()) {
        audioSource = DeviceFileSource(customSoundPath);
      } else {
        final assetPath = AppConstants.soundAssetPaths[soundId] ??
            AppConstants.soundAssetPaths[AppConstants.soundRadar]!;
        final cleanPath = assetPath.startsWith('assets/')
            ? assetPath.substring(7)
            : assetPath;
        audioSource = AssetSource(cleanPath);
      }

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.85);
      await _audioPlayer.play(audioSource);

      _previewTimer = Timer(const Duration(milliseconds: 4000), () {
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
