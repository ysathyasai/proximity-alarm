import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../widgets/battery_guidance_sheet.dart';
import '../widgets/radius_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlarmService _alarmService = AlarmService();

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Theme Configuration
          _buildSectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (newSelection) {
                      settingsProvider.updateThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Monitoring & Alert Defaults
          _buildSectionHeader('Default Alert Triggering'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadiusSelector(
                    currentRadiusMeters: settings.defaultRadiusMeters,
                    onRadiusChanged: (val) {
                      settingsProvider.updateDefaultRadius(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Default Prep Window',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${settings.defaultPrepWindowMinutes} min',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.prepWindowPresets.map((preset) {
                      final isSelected =
                          settings.defaultPrepWindowMinutes == preset;
                      return ChoiceChip(
                        label: Text('$preset min'),
                        selected: isSelected,
                        onSelected: (_) =>
                            settingsProvider.updateDefaultPrepWindow(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Use ETA Timer Alert',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Trigger alarm on ETA buffer only when toggled on; otherwise triggers strictly by distance radius',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.useTimerAlert,
                    onChanged: (val) {
                      settingsProvider.updateUseTimerAlert(val);
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Battery Saver Mode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Relaxes GPS distance polling when far away to minimize CPU and battery usage',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.batterySaverMode,
                    onChanged: (val) {
                      settingsProvider.updateBatterySaverMode(val);
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Prefer Offline Google Maps',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Enables quick one-tap shortcuts to your downloaded Google Maps offline areas',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.preferOfflineGoogleMaps,
                    onChanged: (val) {
                      settingsProvider.updatePreferOfflineGoogleMaps(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Alarm & Sound
          _buildSectionHeader('Alarm Audio & Haptics'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alarm Sound Tone',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: settings.alarmSoundId,
                    onChanged: (val) {
                      if (val != null) {
                        settingsProvider.updateAlarmSound(val);
                      }
                    },
                    child: Column(
                      children: AppConstants.soundNames.entries.map((entry) {
                        final soundId = entry.key;
                        final soundName = entry.value;
                        final isSelected = settings.alarmSoundId == soundId;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Radio<String>(
                            value: soundId,
                          ),
                          title: Text(
                            soundName,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_outline_rounded,
                                size: 22),
                            tooltip: 'Preview sound',
                            onPressed: () {
                              _alarmService.previewSound(soundId);
                            },
                          ),
                          onTap: () {
                            settingsProvider.updateAlarmSound(soundId);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Continuous Vibration',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Pulsing haptic vibration pattern until dismissed',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.vibrationEnabled,
                    onChanged: (val) {
                      settingsProvider.updateVibration(val);
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto Repeat if Ignored',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Re-alarms every 2 minutes until user dismisses',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.repeatAlarm,
                    onChanged: (val) {
                      settingsProvider.updateRepeatAlarm(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Android Silent Mode & Background Guidance
          _buildSectionHeader('Android Reliability & Guidance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volume_up_rounded,
                            color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Silent Mode & Ringers',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proximity Alarm uses Android\'s native STREAM_ALARM audio channel. This ensures the alarm rings even if your phone ringer is set to Silent or Vibrate. Please verify your device\'s Alarm volume slider is turned up.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.battery_alert_rounded,
                        color: Color(0xFFF59E0B)),
                    title: const Text(
                      'Battery Optimization Guidance',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Review manufacturer background killer restrictions',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14),
                    onTap: () => BatteryGuidanceSheet.show(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Legal Attribution
          _buildSectionHeader('About & Attribution'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Location-based arrival waking system for bus, train, and transit commuters.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'Data Sources & Licenses:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Map Tiles: © OpenStreetMap contributors\n'
                    '• Geocoding: Nominatim OpenStreetMap API (Usage Policy Compliant)\n'
                    '• Road Routing: Project OSRM (Open Source Routing Machine)',
                    style: TextStyle(fontSize: 11, height: 1.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
