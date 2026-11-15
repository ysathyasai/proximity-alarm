import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../services/place_search_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialDestination});

  final Destination? initialDestination;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final PlaceSearchService _searchService = PlaceSearchService();

  static const LatLng _fallbackCenter = LatLng(17.4435, 78.4975);

  Destination? _selectedDestination;
  double _radiusMeters = 1000.0;
  List<Destination> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    final journey = context.read<JourneyProvider>();
    _selectedDestination = widget.initialDestination ?? journey.destination;
    _radiusMeters = journey.radiusMeters;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchService.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query, LatLng? userPos) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _showSearchResults = true;
    });

    try {
      final results = await _searchService.search(
        trimmed,
        userLocation: userPos,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _searchError = 'No local stops or places found. Try a different query.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Search failed. Please check internet connection.';
      });
    }
  }

  void _onSelectPlace(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _showSearchResults = false;
      _searchController.text = dest.name;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(dest.point, 14.5);
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _selectedDestination = Destination(
        name: 'Selected Pin Location',
        latitude: point.latitude,
        longitude: point.longitude,
        address: 'Lat: ${point.latitude.toStringAsFixed(4)}, Lon: ${point.longitude.toStringAsFixed(4)}',
        category: 'place',
      );
      _showSearchResults = false;
    });
  }

  void _recenterToUser(LatLng? userPos) {
    if (userPos == null) return;
    _mapController.move(userPos, 15.0);
  }

  void _fitBothBounds(LatLng? userPos, LatLng? destPos) {
    if (userPos == null && destPos == null) return;
    if (userPos != null && destPos == null) {
      _mapController.move(userPos, 15.0);
      return;
    }
    if (userPos == null && destPos != null) {
      _mapController.move(destPos, 14.5);
      return;
    }

    final bounds = LatLngBounds(userPos!, destPos!);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(left: 60, right: 60, top: 120, bottom: 200),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'station':
        return Icons.train_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'airport':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journey = context.watch<JourneyProvider>();
    final userPos = journey.liveUserPosition;
    final destPos = _selectedDestination?.point;

    final initialCenter = destPos ?? userPos ?? _fallbackCenter;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.5,
              onTap: (_, point) => _onMapTapped(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.proximity_alarm',
              ),

              // Radius Circle around Destination
              if (_selectedDestination != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedDestination!.point,
                      radius: _radiusMeters,
                      useRadiusInMeter: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.16),
                      borderColor: theme.colorScheme.primary.withValues(alpha: 0.85),
                      borderStrokeWidth: 2.2,
                    ),
                  ],
                ),

              // Dynamic Connecting Line
              if (userPos != null && _selectedDestination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [userPos, _selectedDestination!.point],
                      color: theme.colorScheme.primary,
                      strokeWidth: 3.5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.2,
                    ),
                  ],
                ),

              // Destination Pin Marker
              if (_selectedDestination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedDestination!.point,
                      width: 140,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxStyle(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _selectedDestination!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.location_on_rounded,
                            size: 42,
                            color: theme.colorScheme.error,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // User's Live Location Dot with Pulsing Glow
              if (userPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userPos,
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulsing glow
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          // Crisp white outline
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          // Blue center core
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // 2. Floating Search Bar at Top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search local stops, stations, places...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults = [];
                                          _showSearchResults = false;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (val) => _performSearch(val, userPos),
                            onChanged: (val) {
                              if (val.trim().isEmpty) {
                                setState(() => _showSearchResults = false);
                              }
                            },
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () => _performSearch(_searchController.text, userPos),
                          ),
                      ],
                    ),
                  ),

                  // Search Results Dropdown Overlay
                  if (_showSearchResults) ...[
                    const SizedBox(height: 8),
                    Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: _searchError != null
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _searchError!,
                                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = _searchResults[idx];
                                  final dist = userPos != null ? item.distanceTo(userPos) : null;
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        _iconForCategory(item.category),
                                        size: 18,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      item.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: dist != null
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              Destination.formatDistance(dist),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          )
                                        : null,
                                    onTap: () => _onSelectPlace(item),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls (Recenter & Fit)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_fit_bounds',
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  tooltip: 'Fit route',
                  onPressed: () => _fitBothBounds(userPos, destPos),
                  child: const Icon(Icons.zoom_out_map_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'fab_recenter',
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  tooltip: 'My location',
                  onPressed: () => _recenterToUser(userPos),
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // 4. Bottom Destination Confirmation & Radius Control Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            _selectedDestination != null
                                ? _iconForCategory(_selectedDestination!.category)
                                : Icons.touch_app_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDestination?.name ?? 'Tap map or search destination',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDestination?.address ?? 'Search for a stop or drop a pin anywhere',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_selectedDestination != null && userPos != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              Destination.formatDistance(
                                _selectedDestination!.distanceTo(userPos),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Radius Selector Chips
                    Row(
                      children: [
                        Text(
                          'Alert Radius:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [500.0, 1000.0, 2000.0, 5000.0].map((r) {
                              final isSelected = (_radiusMeters - r).abs() < 10;
                              return ChoiceChip(
                                label: Text(Destination.formatDistance(r)),
                                selected: isSelected,
                                visualDensity: VisualDensity.compact,
                                onSelected: (sel) {
                                  if (sel) setState(() => _radiusMeters = r);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Confirm Destination Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Confirm Destination'),
                        onPressed: _selectedDestination == null
                            ? null
                            : () {
                                journey.setDestination(_selectedDestination!);
                                journey.setRadius(_radiusMeters);
                                Navigator.of(context).pop(_selectedDestination);
                              },
                      ),
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

class BoxStyle extends BoxShadow {
  const BoxStyle({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });
}
