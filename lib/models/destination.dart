import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class Destination {
  const Destination({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.category = 'place',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String category;

  LatLng get point => LatLng(latitude, longitude);

  /// Calculate straight-line distance in meters using Haversine formula
  double distanceTo(LatLng other) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = (other.latitude - latitude) * (math.pi / 180.0);
    final dLon = (other.longitude - longitude) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * (math.pi / 180.0)) *
            math.cos(other.latitude * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static String formatDistance(double meters) {
    if (meters.isNaN || meters.isInfinite || meters < 0) return '--';
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'category': category,
      };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        name: json['name'] as String? ?? 'Saved destination',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String? ?? '',
        category: json['category'] as String? ?? 'place',
      );

  Map<String, dynamic> toNativeMap() => {
        'destinationName': name,
        'destinationLatitude': latitude,
        'destinationLongitude': longitude,
      };

  Destination copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? category,
  }) {
    return Destination(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      category: category ?? this.category,
    );
  }
}
