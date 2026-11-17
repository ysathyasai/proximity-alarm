# Proximity Alarm 🚨

> **Select your destination. Start your journey. Sleep peacefully. Get alerted before you miss your stop.**

Proximity Alarm is an intelligent, location-based arrival alarm designed specifically for commuters traveling on buses, trains, metros, and intercity transit. Unlike an ordinary alarm clock or a fixed timer, **Proximity Alarm monitors real-world location and arrival conditions**, guaranteeing that traffic delays or early arrivals won't cause you to miss your stop or get woken up prematurely.

---

## 🌟 Key Features

1. **Intelligent Arrival Detection**:
   - Dynamic alert radius triggers: Configurable 500m, 1 km, 2 km (default), 3 km, 5 km, and custom sliders up to 10 km.
   - Preparation window: Default 5-minute advance buffer before estimated arrival.
   - Dual condition arrival trigger: Alarms when `distance <= configuredRadius` OR `estimatedArrivalMinutes <= preparationWindow`.
   - Single-trigger guarantee: Built-in state machine prevents duplicate alarms during a single journey.

2. **Reliable Android Background Monitoring**:
   - Official Android Foreground Service (`flutter_foreground_task`) with `android:foregroundServiceType="location"`.
   - Continuous location tracking with screen locked and app minimized.
   - Live ongoing navigation-style notification refreshed with destination name, remaining distance, ETA, and quick actions ("Open App", "Stop Journey").
   - Adaptive GPS polling intervals:
     - > 10 km: battery-saver mode (100m filter)
     - 3 – 10 km: standard mode (50m filter)
     - 1 – 3 km: approaching mode (15m filter)
     - < 1 km: arrival precision mode (5m filter)

3. **Loud, Continuous Alarm Engine**:
   - Uses Android's native `STREAM_ALARM` (`UsageType.alarm`), which sounds even when device ringers are set to Silent or Vibrate.
   - Unstoppable looping alarm playback until explicitly dismissed.
   - Four high-fidelity synthesized alarm sound profiles bundled in-app:
     - *Radar Pulse (Urgent)*
     - *Transit Arrival Chime*
     - *Emergency Siren*
     - *Piercing Bell*
   - Looping haptic vibration pattern with full hardware vibrator control.
   - Full-Screen Intent notification pops up the Alarm screen over the lock screen.

4. **GPS Accuracy Filtering & Glitch Rejection**:
   - Rejects inaccurate GPS fixes where error radius exceeds 65 meters.
   - Filters implausible teleportation jumps (speed > 250 km/h or impossible distance/time delta).
   - Proximity warning if journey begins already inside or dangerously close to the destination zone.

5. **OpenStreetMap & Routing Integration**:
   - Vector and raster OpenStreetMap integration via `flutter_map` with compliant `User-Agent`.
   - Place and address search powered by OpenStreetMap Nominatim with rate limiting (max 1 req/sec) and location bias.
   - Road route geometry via Project OSRM (Open Source Routing Machine).
   - Zero-downtime offline fallback: falls back to geodesic Haversine distance and transit velocity estimation if offline.

6. **Interactive Demo Simulation**:
   - Built-in "Simulate Approach" button on the Active Journey screen allows instant testing and verification of the arrival alert without boarding a physical bus.

7. **Material 3 UI & Architecture**:
   - Cohesive light and dark theme (defaults to system setting).
   - 7 complete screens:
     - **Home**: Quick search, mini map preview, saved places carousel, radius & prep window config, Start Journey CTA.
     - **Destination Picker**: Interactive map, tap-to-pin with reverse geocoding, radius circle preview, location search.
     - **Active Journey**: Live map, road route, metrics grid (Distance, ETA, Speed, Alert Zone), stop/test actions.
     - **Alarm**: High-urgency pulsing screen, destination details, large Dismiss button, 2-minute snooze.
     - **Saved Destinations**: Add, edit, select, and delete favorite transit stops.
     - **Journey History**: Past transit logs, timestamps, durations, and alarm outcomes.
     - **Settings**: Theme, alert defaults, alarm tone previews, vibration toggle, auto-repeat, battery guidance.

---

## 🏗️ Architecture & Project Structure

The project follows clean architecture principles with complete separation of concerns:

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart             # Defaults, limits, presets, API endpoints, sound keys
│   ├── theme/
│   │   └── app_theme.dart                 # Material 3 light and dark themes
│   └── utils/
│       ├── geo_utils.dart                 # Haversine distance, bearings, GPS filtering, ETA math
│       ├── formatters.dart                # Distance, duration, speed, and time formatters
│       └── permission_utils.dart          # Location, notification, and battery permissions
├── data/
│   ├── models/
│   │   ├── destination.dart               # Destination model with coordinates, category, radius
│   │   ├── journey.dart                   # Journey entity, metrics, and outcome enum
│   │   └── app_settings.dart              # User preferences model
│   └── repositories/
│       └── local_storage_repository.dart  # SharedPreferences JSON persistence layer
├── services/
│   ├── geocoding_service.dart             # Nominatim geocoding & reverse geocoding (throttled)
│   ├── routing_service.dart               # OSRM road route fetching & offline fallback
│   ├── location_service.dart              # Geolocator stream & adaptive distance filters
│   ├── alarm_service.dart                 # AudioPlayer (STREAM_ALARM) & looping vibration
│   ├── notification_service.dart          # Local notifications & full screen alarm intent
│   └── background_monitoring_service.dart # Android foreground service & notification actions
├── providers/
│   ├── settings_provider.dart             # Reactive settings state
│   ├── saved_destinations_provider.dart   # Saved places list state
│   ├── journey_history_provider.dart      # Past journeys state
│   └── journey_provider.dart              # Core state machine for active transit journeys
├── presentation/
│   ├── widgets/
│   │   ├── proximity_map.dart             # FlutterMap with tiles, markers, radius, polylines
│   │   ├── radius_selector.dart           # Preset chips & continuous slider
│   │   ├── metric_badge.dart              # Clean card for distance, ETA, speed metrics
│   │   ├── destination_search_bar.dart    # Debounced autocomplete search
│   │   └── battery_guidance_sheet.dart    # OEM battery killer guidance & settings launcher
│   └── screens/
│       ├── home_screen.dart               # Main monitoring entrypoint
│       ├── destination_picker_screen.dart # Interactive map picker
│       ├── active_journey_screen.dart     # Live transit tracking screen
│       ├── alarm_screen.dart              # Urgent waking screen with large Dismiss
│       ├── saved_destinations_screen.dart # Frequently visited places
│       ├── journey_history_screen.dart    # Completed trips timeline
│       └── settings_screen.dart           # Preferences & sound preview
└── main.dart                              # MultiProvider entrypoint
```

---

## 📱 Android Platform Configuration

- **Minimum SDK**: Android 7.0 (API level 24)
- **Target SDK**: Android 14+ (API level 34+)
- **Core Library Desugaring**: Enabled via `desugar_jdk_libs:2.1.4`
- **Permissions**:
  - `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`
  - `ACCESS_BACKGROUND_LOCATION`
  - `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_LOCATION`
  - `POST_NOTIFICATIONS`
  - `WAKE_LOCK`
  - `VIBRATE`
  - `USE_FULL_SCREEN_INTENT`
  - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- **Lock Screen Activity**: `android:showWhenLocked="true"` and `android:turnScreenOn="true"` declared on MainActivity.

---

## 🧪 Testing

The application includes automated unit and widget tests covering:
- Distance calculations (Haversine formula accuracy)
- Geofence boundary detection
- GPS accuracy filtering (rejecting >65m errors)
- Implausible teleportation jump rejection (speed > 250 km/h)
- Normal transit speed acceptance
- ETA estimation with stationary transit fallback
- Dual-condition arrival trigger (radius condition and ETA window condition)
- Single-trigger invariant (alarm triggers at most once per trip)
- Journey outcome transitions (inProgress -> alarmActive -> dismissed / cancelled)
- Model serialization (Destination, Journey, AppSettings)
- Widget rendering, navigation, and settings interaction

Run all tests:
```bash
flutter test
```

Analyze static code:
```bash
flutter analyze
```

Build the Android APK:
```bash
flutter build apk --debug
```
