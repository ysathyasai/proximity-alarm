import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo_utils.dart';
import '../../data/models/journey.dart';
import '../../providers/journey_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/map_launcher_service.dart';
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
    final journey = context.read<JourneyProvider>();
    final settings = context.watch<SettingsProvider>();
    final unit = settings.distanceUnit;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<JourneyProvider>(
          builder: (context, jp, _) {
            final isApproaching = jp.status == JourneyStatus.approaching;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jp.destination?.name ?? 'Active Journey',
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
                      isApproaching
                          ? 'Approaching Alert Zone'
                          : (jp.batterySaverMode
                              ? 'Active (Eco Saver GPS)'
                              : 'Monitoring Active (Background)'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          // Open in Google Maps offline button
          IconButton(
            tooltip: 'Open in downloaded Google Maps',
            icon: const Icon(Icons.explore_rounded, color: Color(0xFF10B981)),
            onPressed: () {
              if (journey.destination != null) {
                MapLauncherService.openGoogleMaps(
                  latitude: journey.destination!.latitude,
                  longitude: journey.destination!.longitude,
                  label: journey.destination!.name,
                );
              }
            },
          ),
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
      body: Consumer<JourneyProvider>(
        builder: (context, jp, _) {
          // If alarm triggers, navigate to AlarmScreen
          if (jp.isAlarmActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AlarmScreen()),
              );
            });
          }

          final dest = jp.destination;
          final remainingDist = jp.remainingDistanceMeters;
          final etaMinutes = jp.estimatedArrivalMinutes;
          final speed = jp.currentSpeedMps;
          final isApproaching = jp.status == JourneyStatus.approaching;

          return Column(
            children: [
              // 1. Live Interactive Map View
              Expanded(
                flex: 6,
                child: ProximityMap(
                  userPosition: jp.currentPosition,
                  destinationPosition: dest?.latLng,
                  destinationName: dest?.name,
                  radiusMeters: jp.radiusMeters,
                  routePoints: jp.routePolyline,
                  isInteractive: true,
                  showRecenterButtons: true,
                  showGoogleMapsButton: true,
                  showRadiusCircle: settings.showRadiusCircle,
                  showConnectingLine: settings.showConnectingLine,
                  showRoutePolyline: settings.showRoutePolyline,
                  distanceUnit: unit,
                  userHeading: jp.currentHeading,
                  userSpeed: jp.currentSpeedMps,
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
                                      ? 'Within approach zone! Alarm will trigger soon.'
                                      : jp.useTimerAlert
                                          ? 'Alarms when < ${Formatters.formatDistance(jp.radiusMeters, unit)} OR < ${jp.prepWindowMinutes}m ETA.'
                                          : 'Alarms strictly when entering the ${Formatters.formatDistance(jp.radiusMeters, unit)} radius.',
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
                        const SizedBox(height: 12),

                        // Animated Journey Progress
                        if (jp.journeyProgressPercent > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress: ${(jp.journeyProgressPercent * 100).round()}%',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              Text(
                                'Direction: ${GeoUtils.getCardinalDirection(jp.destinationBearing)} (${jp.destinationBearing.round()}°)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: jp.journeyProgressPercent,
                              minHeight: 6,
                              backgroundColor: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isApproaching ? const Color(0xFFF59E0B) : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: MetricBadge(
                                icon: Icons.straighten_rounded,
                                label: 'DISTANCE LEFT',
                                value: Formatters.formatDistance(remainingDist, unit),
                                iconColor: const Color(0xFF2563EB),
                              ),
                            ),
                            if (settings.showEtaMetric) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: MetricBadge(
                                  icon: Icons.access_time_rounded,
                                  label: jp.useTimerAlert ? 'ESTIMATED ARRIVAL' : 'ETA (TIMER OFF)',
                                  value: Formatters.formatDurationMinutes(etaMinutes),
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (settings.showSpeedMetric) ...[
                              Expanded(
                                child: MetricBadge(
                                  icon: Icons.speed_rounded,
                                  label: 'TRANSIT SPEED',
                                  value: Formatters.formatSpeed(speed, unit),
                                  iconColor: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: MetricBadge(
                                icon: Icons.alarm_rounded,
                                label: 'ALERT ZONE',
                                value: '< ${Formatters.formatDistance(jp.radiusMeters, unit)}',
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Toggles for Timer & Google Maps
                        Row(
                          children: [
                            // Timer Alert toggle chip
                            FilterChip(
                              avatar: Icon(
                                jp.useTimerAlert ? Icons.timer_rounded : Icons.timer_off_rounded,
                                size: 16,
                                color: jp.useTimerAlert ? theme.colorScheme.primary : Colors.grey,
                              ),
                              label: Text(jp.useTimerAlert ? 'ETA Timer: ON' : 'ETA Timer: OFF'),
                              selected: jp.useTimerAlert,
                              onSelected: (val) => jp.setUseTimerAlert(val),
                            ),
                            const SizedBox(width: 8),
                            // Battery saver chip
                            FilterChip(
                              avatar: Icon(
                                jp.batterySaverMode ? Icons.bolt_rounded : Icons.battery_std_rounded,
                                size: 16,
                                color: jp.batterySaverMode ? const Color(0xFF10B981) : Colors.grey,
                              ),
                              label: Text(jp.batterySaverMode ? 'Eco GPS' : 'Standard GPS'),
                              selected: jp.batterySaverMode,
                              onSelected: (val) => jp.setBatterySaverMode(val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

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
                                onPressed: () => _confirmStopJourney(context, jp),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              tooltip: 'Open in downloaded Google Maps',
                              icon: const Icon(Icons.explore_rounded, color: Color(0xFF10B981)),
                              onPressed: () {
                                if (dest != null) {
                                  MapLauncherService.openGoogleMaps(
                                    latitude: dest.latitude,
                                    longitude: dest.longitude,
                                    label: dest.name,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              tooltip: 'Test alarm trigger immediately',
                              icon: const Icon(Icons.notifications_active_rounded),
                              onPressed: () {
                                jp.testAlarmImmediately();
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
          );
        },
      ),
    );
  }
}
