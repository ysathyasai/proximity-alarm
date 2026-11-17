import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class UseCaseGuideSheet extends StatelessWidget {
  const UseCaseGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UseCaseGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isPitchBlack = settings.isPitchBlack;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isPitchBlack
            ? const Color(0xFF0C0C0C)
            : (isDark ? const Color(0xFF0F172A) : Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isPitchBlack
              ? const Color(0xFF222222)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where & How It Is Used',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'The 4-step commuter peace-of-mind workflow',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: [
                // Highlight Banner: The 4-step flow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route_rounded,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'The Core Journey Flow',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You set the location ➔ You sleep (Optional) ➔ It runs efficiently in the bg ➔ It rings when you\'re nearby according to your set distance & arrival time.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Detailed Steps
                _buildStepTile(
                  context,
                  stepNumber: '1',
                  icon: Icons.pin_drop_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Set Your Destination',
                  description:
                      'Search your bus stop, train station, or landmark, or drop a pin on the interactive map. Choose your preferred alert radius (e.g. 1 km or 2 km).',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 12),

                _buildStepTile(
                  context,
                  stepNumber: '2',
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Sleep (Optional) or Relax',
                  description:
                      'Close your eyes, read a book, or listen to music. No need to constantly check Google Maps or jolt awake at every stop in fear of missing yours.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 12),

                _buildStepTile(
                  context,
                  stepNumber: '3',
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Runs Efficiently in the Background',
                  description:
                      'Our 4-tier adaptive GPS engine relaxes polling when far away (>10 km = 250m interval) and tightens precision near your stop. Consumes up to 75% less battery than navigation apps.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 12),

                _buildStepTile(
                  context,
                  stepNumber: '4',
                  icon: Icons.alarm_on_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Wakes You Right On Time',
                  description:
                      'When your vehicle enters the alert radius or your ETA prep window is reached, the alarm fires with exclusive audio focus lock—cutting through silent mode, DND, and headphones.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 24),

                // Where Is It Used? (Real-World Scenarios)
                const Text(
                  'Popular Everyday Scenarios',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),

                _buildScenarioCard(
                  icon: Icons.directions_bus_rounded,
                  title: 'Daily City Bus & Metro Commute',
                  subtitle:
                      'Never miss your interchange stop or depot even on packed, crowded morning/evening buses.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 10),

                _buildScenarioCard(
                  icon: Icons.train_rounded,
                  title: 'Long-Distance & Overnight Trains',
                  subtitle:
                      'Sleep soundly through the night on sleeper berths. The alarm rings 5–15 minutes before your junction station.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
                const SizedBox(height: 10),

                _buildScenarioCard(
                  icon: Icons.local_taxi_rounded,
                  title: 'Late Night Cabs & Shared Shuttles',
                  subtitle:
                      'Rest safely on late-night airport taxis or shared transit after a tiring flight or work shift.',
                  isDark: isDark,
                  isPitchBlack: isPitchBlack,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Got it button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('GOT IT, LET\'S GO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(
    BuildContext context, {
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
    required bool isPitchBlack,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPitchBlack
            ? const Color(0xFF121212)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPitchBlack
              ? const Color(0xFF222222)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP $stepNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
    );
  }

  Widget _buildScenarioCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isPitchBlack,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPitchBlack
            ? const Color(0xFF0D0D0D)
            : (isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPitchBlack
              ? const Color(0xFF1F1F1F)
              : (isDark ? const Color(0xFF2B394A) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
