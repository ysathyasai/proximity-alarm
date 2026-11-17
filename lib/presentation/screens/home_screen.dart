import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/journey_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/battery_guidance_sheet.dart';
import '../widgets/destination_search_bar.dart';
import '../widgets/proximity_map.dart';
import '../widgets/radius_selector.dart';
import 'active_journey_screen.dart';
import 'alarm_screen.dart';
import 'destination_picker_screen.dart';
import 'journey_history_screen.dart';
import 'saved_destinations_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();

    // If alarm is currently active, pop or present AlarmScreen immediately
    if (journeyProvider.isAlarmActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlarmScreen()),
        );
      });
    }

    final pages = [
      const HomeMainView(),
      const SavedDestinationsScreen(),
      const JourneyHistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentNavIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.navigation_outlined),
            selectedIcon: Icon(Icons.navigation_rounded),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeMainView extends StatelessWidget {
  const HomeMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final journey = context.watch<JourneyProvider>();
    final saved = context.watch<SavedDestinationsProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Battery guidance',
            icon: const Icon(Icons.battery_saver_rounded),
            onPressed: () => BatteryGuidanceSheet.show(context),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // 1. Active Journey Banner (if ongoing)
          if (journey.isJourneyActive) ...[
            InkWell(
              onTap: () {
                if (journey.isAlarmActive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlarmScreen()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: journey.isAlarmActive
                        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (journey.isAlarmActive
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        journey.isAlarmActive
                            ? Icons.alarm_on_rounded
                            : Icons.directions_bus_filled_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey.isAlarmActive
                                ? '🚨 WAKE UP! STOP ARRIVING'
                                : 'Active Journey Monitoring',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'To: ${journey.destination?.name ?? "Selected Destination"} • ${Formatters.formatDistance(journey.remainingDistanceMeters)} left',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. Search Bar
          DestinationSearchBar(
            userLocation: journey.currentPosition,
            onDestinationSelected: (dest) {
              journey.selectDestination(dest);
            },
          ),
          const SizedBox(height: 16),

          // 3. Saved Locations Carousel
          if (saved.destinations.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Destinations',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SavedDestinationsScreen()),
                    );
                  },
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: saved.destinations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = saved.destinations[index];
                  final isSelected = journey.destination?.name == item.name;
                  return ActionChip(
                    avatar: Icon(
                      item.category == 'home'
                          ? Icons.home_rounded
                          : item.category == 'work'
                              ? Icons.work_rounded
                              : item.category == 'station'
                                  ? Icons.train_rounded
                                  : Icons.place_rounded,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : const Color(0xFF64748B),
                    ),
                    label: Text(item.name),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1)),
                    ),
                    onPressed: () {
                      journey.selectDestination(item);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Map Preview Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  ProximityMap(
                    userPosition: journey.currentPosition,
                    destinationPosition: journey.destination?.latLng,
                    radiusMeters: journey.radiusMeters,
                    routePoints: journey.routePolyline,
                    isInteractive: false,
                    showRecenterButtons: false,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Interactive Map',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DestinationPickerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (journey.destination != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded,
                                color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                journey.destination!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              Formatters.formatDistance(
                                  journey.remainingDistanceMeters),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Radius Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: RadiusSelector(
                currentRadiusMeters: journey.radiusMeters,
                onRadiusChanged: (val) {
                  journey.setRadius(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Preparation Window Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Preparation Window',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${journey.prepWindowMinutes} min buffer',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alarm fires when ETA reaches this window or when entering the radius circle.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.prepWindowPresets.map((preset) {
                        final isSelected = journey.prepWindowMinutes == preset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$preset min'),
                            selected: isSelected,
                            onSelected: (_) => journey.setPrepWindow(preset),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Warnings / Notices
          if (journey.warningMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      journey.warningMessage!,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // 7. Prominent START JOURNEY Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: journey.destination == null
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                    : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: Text(
                journey.destination == null
                    ? 'Select a Destination First'
                    : 'START JOURNEY MONITORING',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: journey.destination == null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DestinationPickerScreen(),
                        ),
                      );
                    }
                  : () async {
                      final started = await journey.startJourney(
                        settings: settings.settings,
                      );
                      if (started && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ActiveJourneyScreen(),
                          ),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
