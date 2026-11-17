import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../services/map_launcher_service.dart';

class ProximityMap extends StatefulWidget {
  final LatLng? userPosition;
  final LatLng? destinationPosition;
  final String? destinationName;
  final double radiusMeters;
  final List<LatLng> routePoints;
  final bool isInteractive;
  final void Function(LatLng point)? onTap;
  final MapController? mapController;
  final bool showRecenterButtons;
  final bool showGoogleMapsButton;
  final bool showRadiusCircle;
  final bool showConnectingLine;
  final bool showRoutePolyline;
  final DistanceUnit distanceUnit;
  final double? userHeading;
  final double? userSpeed;

  const ProximityMap({
    super.key,
    this.userPosition,
    this.destinationPosition,
    this.destinationName,
    this.radiusMeters = 2000.0,
    this.routePoints = const [],
    this.isInteractive = true,
    this.onTap,
    this.mapController,
    this.showRecenterButtons = true,
    this.showGoogleMapsButton = true,
    this.showRadiusCircle = true,
    this.showConnectingLine = true,
    this.showRoutePolyline = true,
    this.distanceUnit = DistanceUnit.metric,
    this.userHeading,
    this.userSpeed,
  });

  @override
  State<ProximityMap> createState() => _ProximityMapState();
}

class _ProximityMapState extends State<ProximityMap> {
  late final MapController _mapController;
  bool _useRadarMode = false; // Ultra-lightweight battery saver mode

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  void didUpdateWidget(covariant ProximityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationPosition != null &&
        widget.destinationPosition != oldWidget.destinationPosition) {
      _mapController.move(widget.destinationPosition!, 14.5);
    }
  }

  void _recenter(LatLng point, double zoom) {
    _mapController.move(point, zoom);
  }

  void _fitBounds() {
    if (widget.userPosition != null && widget.destinationPosition != null) {
      final bounds = LatLngBounds(
        widget.userPosition!,
        widget.destinationPosition!,
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  void _openGoogleMapsOffline() {
    if (widget.destinationPosition != null) {
      MapLauncherService.openGoogleMaps(
        latitude: widget.destinationPosition!.latitude,
        longitude: widget.destinationPosition!.longitude,
        label: widget.destinationName,
      );
    } else if (widget.userPosition != null) {
      MapLauncherService.openGoogleMaps(
        latitude: widget.userPosition!.latitude,
        longitude: widget.userPosition!.longitude,
        label: 'Current Location',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.destinationPosition ??
        widget.userPosition ??
        const LatLng(13.0827, 80.2707);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        children: [
          if (!_useRadarMode)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14.0,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
                onTap: widget.onTap != null
                    ? (tapPosition, point) => widget.onTap!(point)
                    : null,
              ),
              children: [
                // 1. Tile Layer with memory & keepBuffer optimization
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: 'com.proximityalarm.proximity_alarm',
                  panBuffer: 1,
                  keepBuffer: 2,
                  maxZoom: 18,
                  minZoom: 4,
                ),

                // 2. Alert Radius Circle
                if (widget.showRadiusCircle && widget.destinationPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: widget.destinationPosition!,
                        radius: widget.radiusMeters,
                        useRadiusInMeter: true,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                        borderColor: const Color(0xFFD97706),
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),

                // 3. Straight-line connecting indicator (when enabled)
                if (widget.showConnectingLine &&
                    widget.userPosition != null &&
                    widget.destinationPosition != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [widget.userPosition!, widget.destinationPosition!],
                        strokeWidth: 2.0,
                        color: const Color(0xFF64748B).withValues(alpha: 0.6),
                      ),
                    ],
                  ),

                // 4. Road Route Polyline
                if (widget.showRoutePolyline && widget.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        strokeWidth: 4.5,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),

                // 5. Markers
                MarkerLayer(
                  markers: [
                    if (widget.userPosition != null)
                      Marker(
                        point: widget.userPosition!,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: (widget.userSpeed != null &&
                                  widget.userSpeed! > 1.0 &&
                                  widget.userHeading != null)
                              ? Transform.rotate(
                                  angle: widget.userHeading! * 3.141592653589793 / 180,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (widget.destinationPosition != null)
                      Marker(
                        point: widget.destinationPosition!,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFDC2626),
                          size: 42,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            // Battery Saver / Radar Compass HUD (zero tile lag)
            Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.radar_rounded,
                          size: 64,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Radar Mode Active',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring destination without downloading map tiles.\n'
                      'Radius: ${Formatters.formatDistance(widget.radiusMeters, widget.distanceUnit)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // Top Controls: Radar Mode & Google Maps Action
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                // Radar Toggle
                FloatingActionButton.small(
                  heroTag: 'map_radar_toggle',
                  backgroundColor: _useRadarMode
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  foregroundColor: _useRadarMode
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  tooltip: _useRadarMode ? 'Switch to Map Tiles' : 'Switch to Radar Mode',
                  onPressed: () {
                    setState(() {
                      _useRadarMode = !_useRadarMode;
                    });
                  },
                  child: Icon(
                    _useRadarMode ? Icons.map_rounded : Icons.radar_rounded,
                    size: 20,
                  ),
                ),
                if (widget.showGoogleMapsButton) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_google_maps_offline',
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: const Color(0xFF10B981),
                    tooltip: 'Open in downloaded Google Maps',
                    onPressed: _openGoogleMapsOffline,
                    child: const Icon(Icons.explore_rounded, size: 20),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Left: Attribution
          if (!_useRadarMode)
            Positioned(
              bottom: 4,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  AppConstants.osmAttribution,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom Right: Recenter Buttons
          if (widget.showRecenterButtons && !_useRadarMode)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.userPosition != null &&
                      widget.destinationPosition != null)
                    FloatingActionButton.small(
                      heroTag: 'map_fit_bounds',
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      tooltip: 'Show both points',
                      onPressed: _fitBounds,
                      child: const Icon(Icons.zoom_out_map_rounded, size: 20),
                    ),
                  if (widget.destinationPosition != null) ...[
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_center_destination',
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: const Color(0xFFDC2626),
                      tooltip: 'Center on Destination',
                      onPressed: () =>
                          _recenter(widget.destinationPosition!, 15.0),
                      child: const Icon(Icons.flag_rounded, size: 20),
                    ),
                  ],
                  if (widget.userPosition != null) ...[
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_center_user',
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      tooltip: 'Center on My Location',
                      onPressed: () => _recenter(widget.userPosition!, 16.0),
                      child: const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
