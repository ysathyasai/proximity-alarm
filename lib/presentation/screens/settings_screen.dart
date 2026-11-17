import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/journey_history_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../widgets/battery_guidance_sheet.dart';
import '../widgets/radius_selector.dart';
import 'alarm_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlarmService _alarmService = AlarmService();

  @override
  void initState() {
    super.initState();
    _alarmService.onPreviewStateChanged = (_) {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _alarmService.onPreviewStateChanged = null;
    _alarmService.dispose();
    super.dispose();
  }

  void _confirmResetDefaults(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings to Defaults?'),
        content: const Text(
          'All preferences (theme, alarm sound, alert radius, monitoring profile) will be restored to their factory defaults.\n\nYour saved destinations and journey history will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              provider.resetToDefaults();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings restored to factory defaults'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('RESET DEFAULTS'),
          ),
        ],
      ),
    );
  }

  void _confirmClearDestinations(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Saved Destinations?'),
        content: const Text(
          'Are you sure you want to remove all saved places? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              context.read<SavedDestinationsProvider>().clearAllDestinations();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved destinations cleared')),
              );
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Journey History?'),
        content: const Text(
          'Are you sure you want to delete all recorded journey logs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              context.read<JourneyHistoryProvider>().clearHistory();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Journey history cleared')),
              );
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Customization'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 1. APPEARANCE
          _buildSectionHeader('Appearance & Theme'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (newSelection) {
                      HapticFeedback.selectionClick();
                      settingsProvider.updateThemeMode(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 14),

                  // Accent Color Picker
                  const Text('Accent Brand Color',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    'Personalize the app color palette across maps, buttons, and badges',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: AppConstants.accentColors.entries.map((entry) {
                      final key = entry.key;
                      final color = entry.value;
                      final isSelected = settings.accentColorKey == key;
                      final name = AppConstants.accentColorNames[key] ?? key;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          settingsProvider.updateAccentColor(key);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Metrics Display density
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Transit Speed',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Display real-time km/h or mph on active journey screen',
                        style: TextStyle(fontSize: 12)),
                    value: settings.showSpeedMetric,
                    onChanged: (val) =>
                        settingsProvider.updateMetricVisibility(showSpeedMetric: val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Estimated Arrival (ETA)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Display estimated arrival time and minutes remaining',
                        style: TextStyle(fontSize: 12)),
                    value: settings.showEtaMetric,
                    onChanged: (val) =>
                        settingsProvider.updateMetricVisibility(showEtaMetric: val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. JOURNEY AND ARRIVAL SETTINGS
          _buildSectionHeader('Journey and Arrival Detection'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Arrival Alert Mode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how the application determines when to sound the arrival alarm',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AlertMode>(
                    segments: const [
                      ButtonSegment(
                        value: AlertMode.combined,
                        label: Text('Combined'),
                        icon: Icon(Icons.all_inclusive_rounded),
                      ),
                      ButtonSegment(
                        value: AlertMode.fixedRadius,
                        label: Text('Radius Only'),
                        icon: Icon(Icons.adjust_rounded),
                      ),
                      ButtonSegment(
                        value: AlertMode.adaptiveEta,
                        label: Text('ETA Time'),
                        icon: Icon(Icons.timer_rounded),
                      ),
                    ],
                    selected: {settings.alertMode},
                    onSelectionChanged: (newSelection) {
                      settingsProvider.updateAlertMode(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      settings.alertMode == AlertMode.combined
                          ? '• Combined (Recommended): Alarms when either entering destination radius OR reaching the ETA preparation window.'
                          : settings.alertMode == AlertMode.fixedRadius
                              ? '• Radius Only: Alarms strictly when your physical location crosses into the destination geofence radius.'
                              : '• ETA Time: Alarms dynamically based on transit speed and minutes before arrival (with safety radius fallback).',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 14),

                  // Distance Units (Metric vs Imperial)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distance Units',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<DistanceUnit>(
                          segments: const [
                            ButtonSegment(
                              value: DistanceUnit.metric,
                              label: Text('Metric (km / m)'),
                              icon: Icon(Icons.straighten_rounded),
                            ),
                            ButtonSegment(
                              value: DistanceUnit.imperial,
                              label: Text('Imperial (mi / ft)'),
                              icon: Icon(Icons.square_foot_rounded),
                            ),
                          ],
                          selected: {settings.distanceUnit},
                          onSelectionChanged: (newSelection) {
                            settingsProvider.updateDistanceUnit(newSelection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 14),

                  // Default Radius Selector
                  RadiusSelector(
                    currentRadiusMeters: settings.defaultRadiusMeters,
                    distanceUnit: settings.distanceUnit,
                    onRadiusChanged: (val) {
                      settingsProvider.updateDefaultRadius(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Default Prep Window
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Default Prep Window',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Early Proximity Warning Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Early Proximity Notice',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Provides a gentle advance notification at 2x radius so you can collect belongings peacefully',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.earlyWarningEnabled,
                    onChanged: (val) => settingsProvider.updateEarlyWarning(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. ALARM AUDIO & HAPTICS
          _buildSectionHeader('Alarm Audio, Haptics & Dismissal'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alarm Sound Tone',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Preview sounds before choosing. Plays through Android STREAM_ALARM.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
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
                        final isPlayingThis =
                            _alarmService.currentlyPreviewingSoundId == soundId;

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
                            icon: Icon(
                              isPlayingThis
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_outline_rounded,
                              color: isPlayingThis
                                  ? const Color(0xFFEF4444)
                                  : theme.colorScheme.primary,
                              size: 24,
                            ),
                            tooltip: isPlayingThis ? 'Stop preview' : 'Preview sound',
                            onPressed: () async {
                              await _alarmService.previewSound(soundId);
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            settingsProvider.updateAlarmSound(soundId);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),

                  // Vibration Pattern
                  const Text('Vibration Pattern',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<VibrationPatternType>(
                    initialValue: settings.vibrationPattern,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: VibrationPatternType.continuous,
                        child: Text('Continuous Pulse (Strong)'),
                      ),
                      DropdownMenuItem(
                        value: VibrationPatternType.pulse,
                        child: Text('Even Pulses (Standard)'),
                      ),
                      DropdownMenuItem(
                        value: VibrationPatternType.heartbeat,
                        child: Text('Heartbeat Rhythm'),
                      ),
                      DropdownMenuItem(
                        value: VibrationPatternType.urgent,
                        child: Text('Urgent SOS Pattern'),
                      ),
                      DropdownMenuItem(
                        value: VibrationPatternType.none,
                        child: Text('No Vibration (Silent)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        settingsProvider.updateVibrationPattern(val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Volume Escalation
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Gradual Volume Escalation',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Ramps up volume smoothly over 15 seconds to wake you without panic',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.volumeEscalation,
                    onChanged: (val) =>
                        settingsProvider.updateVolumeEscalation(val),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Auto Repeat
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto Repeat if Ignored',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Repeats the alarm if dismissed accidentally or slept through',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.repeatAlarm,
                    onChanged: (val) => settingsProvider.updateRepeatAlarm(val),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Snooze Duration
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Snooze Duration',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${settings.snoozeDurationMinutes} minutes',
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
                    children: AppConstants.snoozePresets.map((preset) {
                      final isSelected =
                          settings.snoozeDurationMinutes == preset;
                      return ChoiceChip(
                        label: Text('$preset min'),
                        selected: isSelected,
                        onSelected: (_) =>
                            settingsProvider.updateSnoozeDuration(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),

                  // Require Slide to Dismiss
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Require Slide to Dismiss',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Replaces simple button with a deliberate slide gesture to prevent sleepy mis-taps',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.requireSlideToDismiss,
                    onChanged: (val) =>
                        settingsProvider.updateRequireSlideToDismiss(val),
                  ),
                  const SizedBox(height: 14),

                  // TEST ALARM BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text(
                        'TEST ALARM NOW (AUDIO & SCREEN)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () {
                        final journeyProvider = context.read<JourneyProvider>();
                        journeyProvider.testAlarmImmediately();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AlarmScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. MAPS & NAVIGATION
          _buildSectionHeader('Maps & Navigation Preferences'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Prefer Downloaded Google Maps',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Enables quick one-tap shortcuts to your downloaded Google Maps offline areas',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.preferOfflineGoogleMaps,
                    onChanged: (val) =>
                        settingsProvider.updatePreferOfflineGoogleMaps(val),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Geofence Radius Circle',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Renders destination proximity boundary ring on map',
                        style: TextStyle(fontSize: 12)),
                    value: settings.showRadiusCircle,
                    onChanged: (val) =>
                        settingsProvider.updateMapOverlays(showRadiusCircle: val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Direct Connecting Line',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Renders straight-line indicator from location to stop',
                        style: TextStyle(fontSize: 12)),
                    value: settings.showConnectingLine,
                    onChanged: (val) => settingsProvider.updateMapOverlays(
                        showConnectingLine: val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Road Route Polyline',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Renders routing path along roads when available',
                        style: TextStyle(fontSize: 12)),
                    value: settings.showRoutePolyline,
                    onChanged: (val) =>
                        settingsProvider.updateMapOverlays(showRoutePolyline: val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. BATTERY & BACKGROUND MONITORING
          _buildSectionHeader('Battery & Background Monitoring'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monitoring Profile',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    'Balance GPS accuracy with battery consumption according to your transit type',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<MonitoringProfile>(
                    segments: const [
                      ButtonSegment(
                        value: MonitoringProfile.balanced,
                        label: Text('Balanced'),
                        icon: Icon(Icons.speed_rounded),
                      ),
                      ButtonSegment(
                        value: MonitoringProfile.responsive,
                        label: Text('Responsive'),
                        icon: Icon(Icons.flash_on_rounded),
                      ),
                      ButtonSegment(
                        value: MonitoringProfile.batterySaver,
                        label: Text('Eco / Saver'),
                        icon: Icon(Icons.battery_saver_rounded),
                      ),
                    ],
                    selected: {settings.monitoringProfile},
                    onSelectionChanged: (newSelection) {
                      settingsProvider
                          .updateMonitoringProfile(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (settings.monitoringProfile ==
                                  MonitoringProfile.batterySaver
                              ? const Color(0xFF10B981)
                              : settings.monitoringProfile ==
                                      MonitoringProfile.responsive
                                  ? const Color(0xFFF59E0B)
                                  : theme.colorScheme.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      settings.monitoringProfile == MonitoringProfile.balanced
                          ? '• Balanced (Default): Smart adaptive GPS (100m far &rarr; 15m close &rarr; 5m stop). Recommended for city buses, suburban trains, and subways.'
                          : settings.monitoringProfile ==
                                  MonitoringProfile.responsive
                              ? '• Responsive (High Speed): High-frequency GPS (50m far &rarr; 10m close &rarr; 3m stop). Ideal for high-speed express trains and highway intercity buses.'
                              : '• Battery Saver / Eco: Minimalist GPS polling (250m far &rarr; 35m close &rarr; 10m stop). Maximizes battery life on long overnight trips.',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.battery_alert_rounded,
                        color: Color(0xFFF59E0B)),
                    title: const Text(
                      'Manufacturer Battery Killer Guidance',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Crucial steps for Samsung, Xiaomi, OnePlus, Huawei and Pixel devices',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => BatteryGuidanceSheet.show(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 6. ANDROID NOTIFICATIONS & AUDIO CHANNEL
          _buildSectionHeader('Android System & Audio Channel'),
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
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volume_up_rounded,
                            color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Native Alarm Audio Stream (STREAM_ALARM)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proximity Alarm plays through Android\'s dedicated Alarm audio stream. This ensures the alarm sounds even if your ringer is set to Silent or Vibrate. Please ensure your device\'s system "Alarm" volume slider is turned up.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 7. PRIVACY & DATA
          _buildSectionHeader('Privacy, Data & Storage'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '100% On-Device & Private',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your destinations, routes, and journeys are stored entirely on your local device. We do not operate user accounts, track personal telemetry, or share your whereabouts.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626)),
                    title: const Text('Clear Journey History Logs',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Erase all past trip timestamps and records',
                        style: TextStyle(fontSize: 12)),
                    onTap: () => _confirmClearHistory(context),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_remove_rounded,
                        color: Color(0xFFDC2626)),
                    title: const Text('Clear Saved Places',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Remove all stored home, work, and custom destinations',
                        style: TextStyle(fontSize: 12)),
                    onTap: () => _confirmClearDestinations(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 8. RESET SETTINGS
          _buildSectionHeader('Reset Preferences'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore_rounded,
                        color: Color(0xFFD97706)),
                    title: const Text(
                      'Reset All Settings to Defaults',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Restore default alert radius, sound, and theme without deleting your destinations',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () =>
                        _confirmResetDefaults(context, settingsProvider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 9. About & Attribution
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Map Tiles © OpenStreetMap • Routing by OSRM • Geocoding by Nominatim',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
