import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';

class ProximityMap extends StatefulWidget {
  final LatLng? userPosition;
  final LatLng? destinationPosition;
  final double radiusMeters;
  final List<LatLng> routePoints;
  final bool isInteractive;
  final void Function(LatLng point)? onTap;
  final MapController? mapController;
  final bool showRecenterButtons;

  const ProximityMap({
    super.key,
    this.userPosition,
    this.destinationPosition,
    this.radiusMeters = 2000.0,
    this.routePoints = const [],
    this.isInteractive = true,
    this.onTap,
    this.mapController,
    this.showRecenterButtons = true,
  });

  @override
  State<ProximityMap> createState() => _ProximityMapState();
}

class _ProximityMapState extends State<ProximityMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
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

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.destinationPosition ??
        widget.userPosition ??
        const LatLng(13.0827, 80.2707); // Default fallback

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14.0,
            interactionOptions: InteractionOptions(
              flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
            onTap: widget.onTap != null
                ? (tapPosition, point) => widget.onTap!(point)
                : null,
          ),
          children: [
            // 1. OpenStreetMap Tile Layer with required User-Agent
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: 'com.proximityalarm.proximity_alarm',
            ),

            // 2. Alert Radius Circle around Destination
            if (widget.destinationPosition != null)
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

            // 3. Route Polyline
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),

            // 4. Markers: Destination & User
            MarkerLayer(
              markers: [
                // User Location Marker
                if (widget.userPosition != null)
                  Marker(
                    point: widget.userPosition!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Destination Marker
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
        ),

        // Controls overlay
        if (widget.showRecenterButtons && widget.isInteractive)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.userPosition != null && widget.destinationPosition != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_fit',
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    tooltip: 'Fit route',
                    onPressed: _fitBounds,
                    child: const Icon(Icons.zoom_out_map),
                  ),
                const SizedBox(height: 8),
                if (widget.destinationPosition != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_dest',
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    tooltip: 'Go to destination',
                    onPressed: () => _recenter(widget.destinationPosition!, 14.5),
                    child: const Icon(Icons.flag_rounded),
                  ),
                const SizedBox(height: 8),
                if (widget.userPosition != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_user',
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    tooltip: 'My location',
                    onPressed: () => _recenter(widget.userPosition!, 15.5),
                    child: const Icon(Icons.my_location),
                  ),
              ],
            ),
          ),

        // OpenStreetMap Attribution Badge (OSM Policy Compliance)
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              AppConstants.osmAttribution,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
