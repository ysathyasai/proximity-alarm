import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/journey.dart';
import '../../providers/journey_history_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';

class JourneyHistoryScreen extends StatelessWidget {
  const JourneyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyProvider = context.watch<JourneyHistoryProvider>();
    final history = historyProvider.history;
    final settings = context.watch<SettingsProvider>();
    final isPitchBlack = settings.isPitchBlack;
    final unit = settings.distanceUnit;

    // Analytics summary
    final totalTrips = history.length;
    final totalAlarmsWoken = history.where((j) => j.alarmTriggered).length;
    final totalMeters = history.fold<double>(0.0, (acc, j) => acc + j.initialDistanceMeters);
    final onTimeRate = totalTrips > 0 ? ((totalAlarmsWoken / totalTrips) * 100).round() : 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear History?'),
                    content: const Text(
                      'Are you sure you want to erase all past journey logs?',
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
                          historyProvider.clearHistory();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('CLEAR ALL'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No journeys completed yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your transit trips and alarm wake-up records\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length + 1, // +1 for the top analytics dashboard card
              itemBuilder: (context, index) {
                // Item 0: Analytics Dashboard Card
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? (isPitchBlack
                                ? [const Color(0xFF0C0C0C), const Color(0xFF000000)]
                                : [const Color(0xFF1E293B), const Color(0xFF0F172A)])
                            : [Colors.white, const Color(0xFFF8FAFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? (isPitchBlack ? const Color(0xFF222222) : const Color(0xFF334155))
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.analytics_rounded,
                                  color: theme.colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Commuter Performance',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              title: 'Total Trips',
                              value: totalTrips.toString(),
                              color: theme.colorScheme.primary,
                            ),
                            _buildSummaryItem(
                              title: 'Monitored',
                              value: Formatters.formatDistance(totalMeters, unit),
                              color: const Color(0xFF10B981),
                            ),
                            _buildSummaryItem(
                              title: 'Woke Up',
                              value: totalAlarmsWoken.toString(),
                              color: const Color(0xFFF59E0B),
                            ),
                            _buildSummaryItem(
                              title: 'Wake Rate',
                              value: '$onTimeRate%',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final journey = history[index - 1];

                Color outcomeColor = const Color(0xFF10B981);
                String outcomeLabel = 'Alarm Triggered & Dismissed';
                IconData outcomeIcon = Icons.alarm_on_rounded;

                if (journey.outcome == JourneyOutcome.cancelledByUser) {
                  outcomeColor = const Color(0xFF64748B);
                  outcomeLabel = 'Cancelled by User';
                  outcomeIcon = Icons.cancel_outlined;
                } else if (journey.outcome == JourneyOutcome.completedNormally) {
                  outcomeColor = const Color(0xFF2563EB);
                  outcomeLabel = 'Completed';
                  outcomeIcon = Icons.check_circle_outline_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(journey.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      HapticFeedback.mediumImpact();
                      historyProvider.deleteJourney(journey.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed trip to ${journey.destination.name}'),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              historyProvider.recordJourney(journey);
                            },
                          ),
                        ),
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showJourneyDetails(context, journey, unit),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: outcomeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(outcomeIcon,
                                        color: outcomeColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          journey.destination.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          Formatters.formatDateTime(journey.startTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: Color(0xFF94A3B8), size: 20),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Duration: ${Formatters.formatDurationMinutes(journey.durationMinutes)} • ${Formatters.formatDistance(journey.initialDistanceMeters, unit)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: outcomeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      outcomeLabel,
                                      style: TextStyle(
                                        color: outcomeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _showJourneyDetails(
      BuildContext context, Journey journey, DistanceUnit unit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: theme.colorScheme.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.destination.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (journey.destination.address.isNotEmpty)
                        Text(
                          journey.destination.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildMetricRow(
                    'Trip Started',
                    Formatters.formatDateTime(journey.startTime),
                    isDark,
                  ),
                  if (journey.endTime != null) ...[
                    const Divider(height: 16),
                    _buildMetricRow(
                      'Trip Ended',
                      Formatters.formatDateTime(journey.endTime!),
                      isDark,
                    ),
                  ],
                  const Divider(height: 16),
                  _buildMetricRow(
                    'Total Duration',
                    Formatters.formatDurationMinutes(journey.durationMinutes),
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    'Trip Distance',
                    Formatters.formatDistance(journey.initialDistanceMeters, unit),
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    'Alert Radius',
                    Formatters.formatDistance(journey.alertRadiusMeters, unit),
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildMetricRow(
                    'Prep Window',
                    '${journey.prepWindowMinutes} minutes before stop',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                    label: const Text('Save Place'),
                    onPressed: () {
                      context
                          .read<SavedDestinationsProvider>()
                          .addDestination(journey.destination);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Saved "${journey.destination.name}" to favorites!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 20),
                    label: const Text('Use for Trip'),
                    onPressed: () {
                      context
                          .read<JourneyProvider>()
                          .selectDestination(journey.destination);
                      context
                          .read<SavedDestinationsProvider>()
                          .addRecentSearch(journey.destination);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Selected "${journey.destination.name}" as destination!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
