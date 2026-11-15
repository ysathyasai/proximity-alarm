import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo_utils.dart';
import '../../data/models/destination.dart';
import '../../providers/journey_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/geocoding_service.dart';
import '../../services/map_launcher_service.dart';
import '../widgets/destination_search_bar.dart';
import '../widgets/proximity_map.dart';
import '../widgets/radius_selector.dart';

class DestinationPickerScreen extends StatefulWidget {
  const DestinationPickerScreen({super.key});

  @override
  State<DestinationPickerScreen> createState() =>
      _DestinationPickerScreenState();
}

class _DestinationPickerScreenState extends State<DestinationPickerScreen> {
  final GeocodingService _geocodingService = GeocodingService();
  Destination? _pickedDestination;
  double _radiusMeters = 2000.0;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    final journey = context.read<JourneyProvider>();
    _pickedDestination = journey.destination;
    _radiusMeters = journey.radiusMeters;
  }

  Future<void> _onMapTapped(LatLng point) async {
    setState(() {
      _isReverseGeocoding = true;
      _pickedDestination = Destination(
        name: 'Pinned Location',
        address:
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        latitude: point.latitude,
        longitude: point.longitude,
        radiusMeters: _radiusMeters,
      );
    });

    final destination = await _geocodingService.reverseGeocode(point);
    if (mounted) {
      setState(() {
        _pickedDestination = destination.copyWith(radiusMeters: _radiusMeters);
        _isReverseGeocoding = false;
      });
    }
  }

  void _onSearchSelected(Destination destination) {
    setState(() {
      _pickedDestination = destination.copyWith(radiusMeters: _radiusMeters);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final journey = context.watch<JourneyProvider>();
    final saved = context.read<SavedDestinationsProvider>();
    final settings = context.watch<SettingsProvider>();

    final userPos = journey.currentPosition;
    final double? distanceMeters =
        userPos != null && _pickedDestination != null
            ? GeoUtils.calculateDistanceMeters(
                userPos, _pickedDestination!.latLng)
            : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pick Destination'),
        backgroundColor: (isDark ? const Color(0xFF0F172A) : Colors.white)
            .withValues(alpha: 0.85),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Full Screen Interactive Map
          Positioned.fill(
            child: ProximityMap(
              userPosition: userPos,
              destinationPosition: _pickedDestination?.latLng,
              radiusMeters: _radiusMeters,
              onTap: _onMapTapped,
              isInteractive: true,
              showRecenterButtons: true,
              showRadiusCircle: settings.showRadiusCircle,
              showConnectingLine: settings.showConnectingLine,
              showRoutePolyline: settings.showRoutePolyline,
              distanceUnit: settings.distanceUnit,
            ),
          ),

          // 2. Floating Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: DestinationSearchBar(
              userLocation: userPos,
              onDestinationSelected: _onSearchSelected,
              hintText: 'Type place name or tap on map...',
            ),
          ),

          // 3. Map tap hint
          if (_pickedDestination == null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Tap anywhere on the map to set a stop pin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Confirmation Sheet (when destination is selected)
          if (_pickedDestination != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedDestination!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isReverseGeocoding
                                    ? 'Resolving address...'
                                    : _pickedDestination!.address,
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
                        if (distanceMeters != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              Formatters.formatDistance(distanceMeters, settings.distanceUnit),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Radius Selector
                    RadiusSelector(
                      currentRadiusMeters: _radiusMeters,
                      distanceUnit: settings.distanceUnit,
                      onRadiusChanged: (val) {
                        setState(() {
                          _radiusMeters = val;
                          _pickedDestination =
                              _pickedDestination!.copyWith(radiusMeters: val);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Actions
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Open in downloaded Google Maps (Offline)',
                          onPressed: () {
                            if (_pickedDestination != null) {
                              MapLauncherService.openGoogleMaps(
                                latitude: _pickedDestination!.latitude,
                                longitude: _pickedDestination!.longitude,
                                label: _pickedDestination!.name,
                              );
                            }
                          },
                          icon: const Icon(Icons.explore_rounded, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Save destination',
                          onPressed: () {
                            saved.addDestination(_pickedDestination!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Saved "${_pickedDestination!.name}" to favorites!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              journey.selectDestination(
                                _pickedDestination!.copyWith(
                                    radiusMeters: _radiusMeters),
                              );
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'CONFIRM DESTINATION',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

