import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/journey.dart';
import '../../providers/journey_provider.dart';
import '../widgets/metric_badge.dart';
import '../widgets/proximity_map.dart';
import 'alarm_screen.dart';

class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key});

  void _confirmStopJourney(BuildContext context, JourneyProvider journey) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Monitoring?'),
        content: const Text(
          'Are you sure you want to stop journey monitoring? The alarm will not trigger for this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CONTINUE TRACKING'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              journey.stopJourney(outcome: JourneyOutcome.cancelledByUser);
              Navigator.of(context).pop();
            },
            child: const Text('STOP JOURNEY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final journey = context.watch<JourneyProvider>();

    // If alarm is active, automatically push the Alarm screen
    if (journey.isAlarmActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AlarmScreen()),
        );
      });
    }

    final dest = journey.destination;
    final remainingDist = journey.remainingDistanceMeters;
    final etaMinutes = journey.estimatedArrivalMinutes;
    final speed = journey.currentSpeedMps;
    final isApproaching = journey.status == JourneyStatus.approaching;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dest?.name ?? 'Active Journey',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isApproaching
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isApproaching ? 'Approaching Stop Zone' : 'Monitoring Active (Background)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Simulate Approach Button for instant testing
          IconButton(
            tooltip: 'Simulate getting closer (Demo)',
            icon: const Icon(Icons.fast_forward_rounded),
            onPressed: () {
              journey.simulateApproachStep();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulated movement closer to destination!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Interactive Map View
          Expanded(
            flex: 6,
            child: ProximityMap(
              userPosition: journey.currentPosition,
              destinationPosition: dest?.latLng,
              radiusMeters: journey.radiusMeters,
              routePoints: journey.routePolyline,
              isInteractive: true,
              showRecenterButtons: true,
            ),
          ),

          // 2. Metrics & Status Panel
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isApproaching
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF2563EB))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApproaching
                                ? Icons.warning_amber_rounded
                                : Icons.security_rounded,
                            size: 18,
                            color: isApproaching
                                ? const Color(0xFFD97706)
                                : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isApproaching
                                  ? 'Within preparation window! Alarm will trigger soon.'
                                  : 'Sleep peacefully. We will wake you at ${Formatters.formatDistance(journey.radiusMeters)}.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isApproaching
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Metrics 2x2 Grid
                    Row(
                      children: [
                        Expanded(
                          child: MetricBadge(
                            icon: Icons.straighten_rounded,
                            label: 'DISTANCE LEFT',
                            value: Formatters.formatDistance(remainingDist),
                            iconColor: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricBadge(
                            icon: Icons.access_time_rounded,
                            label: 'ESTIMATED ARRIVAL',
                            value: Formatters.formatDurationMinutes(etaMinutes),
                            iconColor: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MetricBadge(
                            icon: Icons.speed_rounded,
                            label: 'TRANSIT SPEED',
                            value: Formatters.formatSpeed(speed),
                            iconColor: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricBadge(
                            icon: Icons.alarm_rounded,
                            label: 'ALERT ZONE',
                            value: '< ${Formatters.formatDistance(journey.radiusMeters)}',
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.stop_circle_outlined, size: 20),
                            label: const Text(
                              'STOP JOURNEY',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _confirmStopJourney(context, journey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: 'Test alarm trigger immediately',
                          icon: const Icon(Icons.notifications_active_rounded),
                          onPressed: () {
                            journey.testAlarmImmediately();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
