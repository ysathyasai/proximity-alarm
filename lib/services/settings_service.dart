import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Manages and persists global app settings, themes, and alarm preferences.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String _keyThemeMode = 'app_theme_mode_v2';
  static const String _keyVibrate = 'alarm_vibrate_v2';
  static const String _keyOverrideSilent = 'alarm_override_silent_v2';
  static const String _keyAlarmSound = 'alarm_sound_v2';
  static const String _keyDefaultRadius = 'app_default_radius_v2';

  static const Map<String, String> availableSounds = {
    'Radar Pulse': 'sounds/radar.wav',
    'Transit Chime': 'sounds/chime.wav',
    'Digital Alarm': 'sounds/digital.wav',
    'Echo Bell': 'sounds/bell.wav',
    'Warning Siren': 'sounds/siren.wav',
  };

  static const List<double> radiusOptions = [500.0, 1000.0, 2000.0, 5000.0];

  ThemeMode _themeMode = ThemeMode.system;
  bool _vibrate = true;
  bool _overrideSilentMode = true;
  String _alarmSound = 'Radar Pulse';
  double _defaultRadiusMeters = 1000.0;
  bool _isLoaded = false;

  final AudioPlayer _testAudioPlayer = AudioPlayer();
  bool _isPlayingTest = false;
  String? _currentlyTestingSound;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get vibrate => _vibrate;
  bool get overrideSilentMode => _overrideSilentMode;
  String get alarmSound => _alarmSound;
  double get defaultRadiusMeters => _defaultRadiusMeters;
  bool get isLoaded => _isLoaded;
  bool get isPlayingTest => _isPlayingTest;
  String? get currentlyTestingSound => _currentlyTestingSound;

  Future<void> initialize() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_keyThemeMode);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _vibrate = prefs.getBool(_keyVibrate) ?? true;
    _overrideSilentMode = prefs.getBool(_keyOverrideSilent) ?? true;

    final savedSound = prefs.getString(_keyAlarmSound);
    if (savedSound != null && availableSounds.containsKey(savedSound)) {
      _alarmSound = savedSound;
    } else {
      _alarmSound = 'Radar Pulse';
    }

    _defaultRadiusMeters = prefs.getDouble(_keyDefaultRadius) ?? 1000.0;
    _isLoaded = true;
    notifyListeners();

    _testAudioPlayer.onPlayerComplete.listen((_) {
      _isPlayingTest = false;
      _currentlyTestingSound = null;
      notifyListeners();
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_keyThemeMode, str);
  }

  Future<void> setVibrate(bool value) async {
    if (_vibrate == value) return;
    _vibrate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrate, value);
    if (value) {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(duration: 150);
      }
    }
  }

  Future<void> setOverrideSilentMode(bool value) async {
    if (_overrideSilentMode == value) return;
    _overrideSilentMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOverrideSilent, value);
  }

  Future<void> setAlarmSound(String sound) async {
    if (!availableSounds.containsKey(sound)) return;
    _alarmSound = sound;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlarmSound, sound);
  }

  Future<void> setDefaultRadius(double meters) async {
    if (_defaultRadiusMeters == meters) return;
    _defaultRadiusMeters = meters;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultRadius, meters);
  }

  Future<void> testSound(String soundName) async {
    final assetPath = availableSounds[soundName];
    if (assetPath == null) return;

    if (_isPlayingTest && _currentlyTestingSound == soundName) {
      await stopTestSound();
      return;
    }

    try {
      await _testAudioPlayer.stop();
      _isPlayingTest = true;
      _currentlyTestingSound = soundName;
      notifyListeners();

      if (_vibrate) {
        final hasVib = await Vibration.hasVibrator();
        if (hasVib == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
        }
      }

      await _testAudioPlayer.play(AssetSource(assetPath), volume: 1.0);
    } catch (_) {
      _isPlayingTest = false;
      _currentlyTestingSound = null;
      notifyListeners();
    }
  }

  Future<void> stopTestSound() async {
    try {
      await _testAudioPlayer.stop();
    } finally {
      _isPlayingTest = false;
      _currentlyTestingSound = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _testAudioPlayer.dispose();
    super.dispose();
  }
}
