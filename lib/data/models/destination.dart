import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class Destination {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String category; // 'home', 'work', 'station', 'favorite', 'custom'
  final DateTime createdAt;

  Destination({
    String? id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 2000.0,
    this.category = 'custom',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  LatLng get latLng => LatLng(latitude, longitude);

  Destination copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? category,
    DateTime? createdAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Selected Destination',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 2000.0,
      category: json['category'] as String? ?? 'custom',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

