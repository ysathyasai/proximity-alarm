import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:proximity_alarm/models/destination.dart';
import 'package:proximity_alarm/models/tracking_state.dart';

void main() {
  group('Destination & Tracking Models', () {
    test('Calculates Haversine distance correctly', () {
      const dest = Destination(
        name: 'Secunderabad Junction',
        latitude: 17.4334,
        longitude: 78.5042,
      );
      // Roughly ~1.5 km away
      const currentPos = LatLng(17.4435, 78.4975);
      final dist = dest.distanceTo(currentPos);

      expect(dist, greaterThan(1000));
      expect(dist, lessThan(2000));
      expect(Destination.formatDistance(dist), contains('km'));
    });

    test('Formats short distances in meters', () {
      expect(Destination.formatDistance(450), '450 m');
      expect(Destination.formatDistance(1250), '1.3 km');
    });

    test('TrackingSnapshot serialization & state flags', () {
      const snapshot = TrackingSnapshot(
        status: TrackingStatus.active,
        distanceMeters: 800.0,
        radiusMeters: 1000.0,
      );

      expect(snapshot.isActive, isTrue);
      expect(snapshot.isWithinRadius, isTrue);
      expect(snapshot.formattedDistance, '800 m');

      final map = snapshot.toMap();
      final restored = TrackingSnapshot.fromMap(map);
      expect(restored.status, TrackingStatus.active);
      expect(restored.distanceMeters, 800.0);
    });
  });
}
