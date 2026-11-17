import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/journey_history_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/battery_guidance_sheet.dart';
import '../widgets/radius_selector.dart';
import '../widgets/use_case_guide_sheet.dart';
import 'alarm_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlarmService _alarmService = AlarmService();
  bool _isPickingFile = false;

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

  Future<void> _pickCustomAudioFile(BuildContext context, SettingsProvider provider) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        if (file.path != null) {
          final fileName = file.name;
          await provider.setCustomSound(file.path!, fileName);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Custom alarm sound set: $fileName'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load audio file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _confirmResetDefaults(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings to Defaults?'),
        content: const Text(
          'All preferences (theme, alarm sound, alert radius, monitoring profile) will be restored to factory defaults.\n\nYour saved destinations and journey history will NOT be deleted.',
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
    final isPitchBlack = settingsProvider.isPitchBlack;

    return Scaffold(
      backgroundColor: isPitchBlack
          ? const Color(0xFF000000)
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () => _confirmResetDefaults(context, settingsProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Ambient One UI Header Card with App Logo
          _buildAppBrandCard(context, isDark, isPitchBlack),
          const SizedBox(height: 20),

          // 1. APPEARANCE & THEME (With Pitch Black OLED)
          _buildSectionHeader('Appearance & Display'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Style',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose appearance or save maximum battery on OLED displays with Pitch Black.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppThemeStyle>(
                      segments: const [
                        ButtonSegment(
                          value: AppThemeStyle.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: AppThemeStyle.light,
                          label: Text('Light'),
                          icon: Icon(Icons.wb_sunny_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: AppThemeStyle.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.nightlight_round, size: 18),
                        ),
                        ButtonSegment(
                          value: AppThemeStyle.pitchBlack,
                          label: Text('Pitch Black'),
                          icon: Icon(Icons.contrast_rounded, size: 18),
                        ),
                      ],
                      selected: {settings.appThemeStyle},
                      onSelectionChanged: (newSelection) {
                        settingsProvider.updateThemeStyle(newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Accent Color Picker
                  const Text(
                    'Accent Color',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: AppConstants.accentColors.entries.map((entry) {
                      final key = entry.key;
                      final color = entry.value;
                      final isSelected = settings.accentColorKey == key;

                      return InkWell(
                        onTap: () => settingsProvider.updateAccentColor(key),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : (isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppConstants.accentColorNames[key] ?? key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? color
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. SAMSUNG CLOCK STYLE ALARM AUDIO & CUSTOM SOUND
          _buildSectionHeader('Alarm Sound & Ringtone'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ringtone',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      // Add Custom Sound Button (Samsung Clock + style)
                      FilledButton.tonalIcon(
                        icon: _isPickingFile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add from phone'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _isPickingFile
                            ? null
                            : () => _pickCustomAudioFile(context, settingsProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plays at full volume through Android STREAM_ALARM, bypassing silent and Do Not Disturb mode.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  RadioGroup<String>(
                    groupValue: settings.alarmSoundId,
                    onChanged: (val) {
                      if (val != null) settingsProvider.updateAlarmSound(val);
                    },
                    child: Column(
                      children: [
                        // Custom Sound Tile (If Selected or Available)
                        if (settings.customSoundPath != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: settings.alarmSoundId == AppConstants.soundCustom
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: settings.alarmSoundId == AppConstants.soundCustom
                                      ? theme.colorScheme.primary
                                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                  width: settings.alarmSoundId == AppConstants.soundCustom ? 1.8 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Radio<String>(
                                      value: AppConstants.soundCustom,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.music_note_rounded, size: 16, color: Color(0xFF10B981)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Custom Audio',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            settings.customSoundTitle ?? 'My Custom Audio',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _alarmService.currentlyPreviewingSoundId == AppConstants.soundCustom
                                            ? Icons.stop_circle_rounded
                                            : Icons.play_circle_outline_rounded,
                                        color: _alarmService.currentlyPreviewingSoundId == AppConstants.soundCustom
                                            ? const Color(0xFFEF4444)
                                            : theme.colorScheme.primary,
                                      ),
                                      onPressed: () async {
                                        await _alarmService.previewSound(
                                          AppConstants.soundCustom,
                                          customSoundPath: settings.customSoundPath,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                                      tooltip: 'Remove Custom Sound',
                                      onPressed: () => settingsProvider.clearCustomSound(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Built-in Tones List (One UI Style)
                        ...[
                          AppConstants.soundRadar,
                          AppConstants.soundTransit,
                          AppConstants.soundSiren,
                          AppConstants.soundBell,
                        ].map((soundId) {
                          final soundName = AppConstants.soundNames[soundId] ?? soundId;
                          final isSelected = settings.alarmSoundId == soundId;
                          final isPlayingThis =
                              _alarmService.currentlyPreviewingSoundId == soundId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: Radio<String>(
                                  value: soundId,
                                ),
                                title: Text(
                                  soundName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                                    size: 26,
                                  ),
                                  tooltip: isPlayingThis ? 'Stop' : 'Preview',
                                  onPressed: () async {
                                    await _alarmService.previewSound(soundId);
                                    setState(() {});
                                  },
                                ),
                                onTap: () => settingsProvider.updateAlarmSound(soundId),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Alarm Volume Slider (Samsung Clock Slider)
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, size: 22, color: Color(0xFF94A3B8)),
                      Expanded(
                        child: Slider(
                          value: settings.alarmVolume,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(settings.alarmVolume * 100).round()}%',
                          onChanged: (val) => settingsProvider.updateAlarmVolume(val),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, size: 22, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        '${(settings.alarmVolume * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),

                  // Gradual Volume Ramp-Up (Escalation)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Gradually Increase Volume',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      settings.volumeEscalation
                          ? 'Starts softly and reaches 100% over ${settings.volumeRampSeconds} seconds'
                          : 'Plays immediately at target volume',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: settings.volumeEscalation,
                    onChanged: (val) => settingsProvider.updateVolumeEscalation(val),
                  ),
                  if (settings.volumeEscalation) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.volumeRampPresets.map((sec) {
                        final isSelected = settings.volumeRampSeconds == sec;
                        return ChoiceChip(
                          label: Text(sec == 0 ? 'Instant' : '${sec}s ramp'),
                          selected: isSelected,
                          onSelected: (_) => settingsProvider.updateVolumeRampSeconds(sec),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),

                  // Vibration Pattern Selection with Live Haptic Feedback
                  const Text(
                    'Vibration Pattern',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<VibrationPatternType>(
                    initialValue: settings.vibrationPattern,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        HapticFeedback.mediumImpact();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. TIME, SNOOZE & ARRIVAL CUSTOMIZATION
          _buildSectionHeader('Arrival Timing & Snooze Customization'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert Mode Segmented Button
                  const Text('Arrival Trigger Policy',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how the alarm wakes you up as you approach your destination.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AlertMode>(
                      segments: const [
                        ButtonSegment(
                          value: AlertMode.combined,
                          label: Text('Radius + ETA'),
                          icon: Icon(Icons.merge_type_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: AlertMode.fixedRadius,
                          label: Text('Radius Only'),
                          icon: Icon(Icons.radar_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: AlertMode.adaptiveEta,
                          label: Text('ETA Only'),
                          icon: Icon(Icons.timer_outlined, size: 16),
                        ),
                      ],
                      selected: {settings.alertMode},
                      onSelectionChanged: (newSelection) {
                        settingsProvider.updateAlertMode(newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Default Prep Window Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Preparation Buffer Window',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    runSpacing: 8,
                    children: AppConstants.prepWindowPresets.map((preset) {
                      final isSelected = settings.defaultPrepWindowMinutes == preset;
                      return ChoiceChip(
                        label: Text('$preset min'),
                        selected: isSelected,
                        onSelected: (_) => settingsProvider.updateDefaultPrepWindow(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Snooze Duration (Samsung Clock style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Snooze Duration',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${settings.snoozeDurationMinutes} min',
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
                    runSpacing: 8,
                    children: AppConstants.snoozePresets.map((preset) {
                      final isSelected = settings.snoozeDurationMinutes == preset;
                      return ChoiceChip(
                        label: Text('$preset min'),
                        selected: isSelected,
                        onSelected: (_) => settingsProvider.updateSnoozeDuration(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 16),

                  // Max Alarm Duration (Auto-Snooze Timeout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Alarm Ringing Timeout',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.maxAlarmDurationMinutes == 0
                            ? 'Continuous'
                            : '${settings.maxAlarmDurationMinutes} min',
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
                    runSpacing: 8,
                    children: AppConstants.maxAlarmDurationPresets.map((preset) {
                      final isSelected = settings.maxAlarmDurationMinutes == preset;
                      return ChoiceChip(
                        label: Text(preset == 0 ? 'Continuous' : '$preset min'),
                        selected: isSelected,
                        onSelected: (_) => settingsProvider.updateMaxAlarmDuration(preset),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. MAP & GPS MONITORING PREFERENCES
          _buildSectionHeader('Map & Geofence Defaults'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance Units
                  const Text('Units of Measurement',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 14),

                  // Default Alert Radius Slider
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
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),

                  // Offline Google Maps Intent
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Launch Offline Google Maps',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Provides one-tap button in active journeys to view your downloaded offline Google Maps area',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.preferOfflineGoogleMaps,
                    onChanged: (val) => settingsProvider.updatePreferOfflineGoogleMaps(val),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),

                  // Early Warning Notice
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Advance Proximity Notice',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Sends a gentle notification at 2x radius before the full waking alarm sounds',
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

          // 5. BATTERY GUIDANCE & SIMULATION TEST
          _buildSectionHeader('System & Diagnostics'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.explore_rounded, color: Color(0xFF2563EB)),
                  title: const Text('Where & How It Works',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text(
                    'The 4-step commuter flow & real-world transit scenarios',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => UseCaseGuideSheet.show(context),
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                ),
                ListTile(
                  leading: const Icon(Icons.battery_saver_rounded, color: Color(0xFF10B981)),
                  title: const Text('Android OEM Battery Guidance',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text(
                    'Steps for Samsung, Xiaomi, and OnePlus background reliability',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => const BatteryGuidanceSheet(),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_on_rounded, color: Color(0xFFF59E0B)),
                  title: const Text('Test Alarm Screen UI',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text(
                    'Preview the full waking alarm screen, sound, and dismiss gestures',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF59E0B)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlarmScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. DANGER ZONE (Reset and Delete)
          _buildSectionHeader('Data Management'),
          Card(
            color: isPitchBlack ? const Color(0xFF0D0D0D) : null,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_remove_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Clear All Saved Destinations',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () => _confirmClearDestinations(context),
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Clear All Journey History',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () => _confirmClearHistory(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
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
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildAppBrandCard(BuildContext context, bool isDark, bool isPitchBlack) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPitchBlack ? const Color(0xFF0C0C0C) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPitchBlack ? const Color(0xFF222222) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          const AppLogo(size: 56, withGlow: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'v${AppConstants.appVersion}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Intelligent GPS arrival detection for trains, metros & buses.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
