import 'package:flutter/material.dart';
import '../../core/utils/permission_utils.dart';

class BatteryGuidanceSheet extends StatefulWidget {
  const BatteryGuidanceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BatteryGuidanceSheet(),
    );
  }

  @override
  State<BatteryGuidanceSheet> createState() => _BatteryGuidanceSheetState();
}

class _BatteryGuidanceSheetState extends State<BatteryGuidanceSheet> {
  bool _isOptimizationIgnored = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await PermissionUtils.checkAllPermissions();
    if (mounted) {
      setState(() {
        _isOptimizationIgnored = status.isBatteryOptimizationIgnored;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestExemption() async {
    await PermissionUtils.requestIgnoreBatteryOptimization();
    await Future.delayed(const Duration(milliseconds: 600));
    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.battery_charging_full_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background Reliability',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Ensure the alarm rings while your phone is asleep',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isLoading
                  ? Colors.grey.withValues(alpha: 0.12)
                  : _isOptimizationIgnored
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isLoading
                    ? Colors.grey
                    : _isOptimizationIgnored
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isOptimizationIgnored
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: _isOptimizationIgnored
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Checking battery optimization status...'
                        : _isOptimizationIgnored
                            ? 'Battery optimization is disabled. Background monitoring is protected.'
                            : 'Battery optimization is active. Android may kill background tracking while asleep.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isOptimizationIgnored
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Why is this required?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Modern Android devices aggressively freeze applications when the screen is locked to save battery. While Proximity Alarm runs an official Foreground Service with a notification, aggressive OEM killers (Samsung, Xiaomi, OnePlus) can still throttle GPS location updates.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Manufacturer tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Manufacturer Quick Tips:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text('• Samsung: Exclude from "Sleeping apps" in Device Care.',
                    style: TextStyle(fontSize: 12, height: 1.4)),
                Text('• Xiaomi / MIUI: Set Battery Saver to "No restrictions" and enable Autostart.',
                    style: TextStyle(fontSize: 12, height: 1.4)),
                Text('• OnePlus / Pixel: Select "Unrestricted" in App Battery Usage.',
                    style: TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isOptimizationIgnored ? null : _requestExemption,
              icon: Icon(_isOptimizationIgnored ? Icons.check : Icons.bolt),
              label: Text(_isOptimizationIgnored
                  ? 'Protection Configured'
                  : 'Disable Battery Optimization'),
            ),
          ),
        ],
      ),
    );
  }
}
