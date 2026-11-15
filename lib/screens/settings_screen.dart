import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section 1: Appearance & Theme
          _buildSectionHeader(context, 'Appearance & Theme', Icons.palette_outlined),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how Proximity Alarm looks on your device',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (newSelection) {
                        settings.setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Alarm Settings
          _buildSectionHeader(context, 'Alarm & Alerts', Icons.alarm_rounded),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Vibrate Toggle
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Vibrate', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Vibrate phone continuously when arrival alarm rings'),
                  value: settings.vibrate,
                  onChanged: (val) => settings.setVibrate(val),
                ),
                const Divider(height: 1),

                // Override Silent Mode
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Override Silent Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Play alarm through alarm stream even if device is set to silent/vibrate',
                  ),
                  value: settings.overrideSilentMode,
                  onChanged: (val) => settings.setOverrideSilentMode(val),
                ),
                const Divider(height: 1),

                // Alarm Sound Dropdown with Inline Audition / Preview Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alarm Sound',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: settings.alarmSound,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: SettingsService.availableSounds.keys.map((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setAlarmSound(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Audition / Test sound button
                      FilledButton.tonalIcon(
                        icon: Icon(
                          settings.isPlayingTest ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(settings.isPlayingTest ? 'Stop' : 'Test'),
                        onPressed: () => settings.testSound(settings.alarmSound),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: App Defaults
          _buildSectionHeader(context, 'Default Geofence Radius', Icons.radar_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Alert Radius',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New journeys will automatically trigger the alarm at this distance',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<double>(
                      segments: SettingsService.radiusOptions.map((r) {
                        return ButtonSegment<double>(
                          value: r,
                          label: Text(Destination.formatDistance(r)),
                        );
                      }).toList(),
                      selected: {settings.defaultRadiusMeters},
                      onSelectionChanged: (newSel) {
                        settings.setDefaultRadius(newSel.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: Battery & Permissions
          _buildSectionHeader(context, 'System & Battery Optimization', Icons.battery_charging_full_rounded),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.battery_alert_rounded),
                  title: const Text('Unrestricted Background Battery'),
                  subtitle: const Text(
                    'For uninterrupted background tracking during sleep or screen-off journeys',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    await openAppSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location Permissions'),
                  subtitle: const Text('Ensure Precise Location permission is enabled'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    await openAppSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 5: About
          Center(
            child: Column(
              children: [
                Text(
                  'Geofencing Transit Alarm v2.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data © OpenStreetMap contributors • Nominatim Geocoding',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
