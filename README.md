# Proximity Alarm (Android-first Flutter prototype)

A destination-aware alarm for bus, train, and road journeys. The user chooses a destination, a fallback radius (default **2 km**), and a preparation window (default **5 minutes**). The Android foreground service monitors location while the phone is locked. It triggers a looping alarm when either the route ETA reaches the preparation window or the fallback radius is entered.

> **Reliability note:** This repository contains a working implementation path, native Android source, Flutter UI, and tests, but it has **not been built or run on a device in this environment** because Flutter/Dart and Android SDK tools are not installed here. Do not rely on it for an important journey until the physical-device test matrix below passes on your phone.

## What is implemented

- Flutter Material 3 home screen, destination selector, route-monitor status, adjustable radius and preparation time.
- Place search and map-pin selection using Photon geocoding plus OpenStreetMap map tiles.
- On-device saved destinations and recent trigger history.
- Android native location foreground service using Google Play services fused location, with adaptive sampling (lower-power updates while far away and faster/high-accuracy updates near the destination).
- Native looped alarm audio that continues until dismissed from the app or the persistent alarm notification.
- Road ETA requests through the **public OSRM demo server** with rate limiting. Radius-based triggering works without internet/routing.
- Persistent status stored in Android SharedPreferences, plus Kotlin and Dart arrival-rule tests.
- Battery-optimization and location-settings shortcuts.

## Important product decisions and limitations

1. **The public OSRM endpoint is a development dependency, not a production SLA.** It estimates duration from a road network but does not give live traffic prediction. Replace it with a traffic-aware provider (for example, a configured Google Routes API integration) before claiming traffic-aware arrival times. Keep radius fallback enabled.
2. **The alarm is condition-triggered, not a scheduled exact alarm.** `SCHEDULE_EXACT_ALARM` is not needed for the current design.
3. **The active trip is a foreground service.** Android displays an ongoing notification. If the user force-stops the app, revokes permissions, disables location, or the manufacturer aggressively kills background processes, delivery cannot be guaranteed.
4. **Battery optimization is surfaced, not silently bypassed.** The user can open the system optimization settings and make an informed choice. Some OEMs have additional app-sleep controls.
5. **The alarm loops until dismissed.** Sound output can still be affected by alarm volume, Do Not Disturb settings, connected audio devices, and hardware/software faults. Test on the target handset.
6. **Location can be delayed or inaccurate.** The service rejects fixes with reported accuracy worse than 100 m and uses the radius as a fallback. GPS may be much less reliable indoors or in dense urban areas.
7. **No alarm system can guarantee delivery after Android force-stop or battery failure.** Never use this prototype as the sole safety mechanism until extensive real-device tests have passed.
8. **iOS is not implemented yet.** The Flutter screen layer is portable; iOS needs a separate native Core Location region-monitoring/background implementation and iOS alarm/notification behavior. It cannot reuse Android foreground-service assumptions.

## Architecture

```text
Flutter UI (lib/)
  ├── DestinationPickerScreen: place search + tappable OpenStreetMap
  ├── LocalStore: saved destinations + trigger history
  └── NativeJourneyService (MethodChannel)
            │
            ▼
Android MainActivity / MethodChannel
            │
            ▼
ProximityTrackingService (foreground service)
  ├── FusedLocationProviderClient (location updates)
  ├── OSRM route ETA (rate limited; best effort)
  ├── ArrivalPolicy (ETA OR configured radius)
  ├── SharedPreferences journey state
  └── MediaPlayer alarm loop + alarm notification
```

## Toolchain

Use a recent stable Flutter SDK (Flutter **3.47+** and Dart **3.11+** recommended), Android Studio/Android SDK, Java 17, and an Android device with Google Play services for the intended fused-location implementation. The project config currently targets Android API 36 and compiles against API 37 using AGP 9.3 / Gradle 9.5. If your installed Flutter template differs, let `flutter create` generate the wrapper/scaffold and preserve this project's Kotlin service, manifest permissions, and Flutter source.

### Windows setup

1. Extract the ZIP to a normal development directory, e.g. `C:\Projects\proximity_alarm`.
2. Confirm `flutter doctor -v` shows Flutter, Android toolchain, and a Java 17 runtime.
3. Open PowerShell in the project folder and run the bootstrap script once to create the Gradle wrapper files from your locally installed Flutter template:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\tool\bootstrap_android_wrapper.ps1
   ```

4. Fetch Dart dependencies and generate Android local configuration:

   ```powershell
   flutter pub get
   ```

5. Connect an Android phone with USB debugging enabled, accept the debugging prompt, and verify:

   ```powershell
   flutter devices
   flutter analyze
   flutter test
   flutter run
   ```

If your Flutter SDK's Gradle plugin template differs from this project's pinned versions, keep the Flutter toolchain's compatible plugin versions. Do not blindly mix Gradle/AGP versions; use the versions supported by the installed Flutter release and compile SDK 37 or a version compatible with your dependency set.

## Android permissions and why they exist

| Permission / capability | Purpose |
|---|---|
| `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` | Read location; precise location is important for a 1–2 km alert boundary. |
| Background location | Not requested by this MVP: the user arms the journey while the app is visible, and the ongoing location foreground service continues monitoring when the app is backgrounded or the screen turns off. Do not add `ACCESS_BACKGROUND_LOCATION` unless a future feature genuinely needs location outside this foreground-service model. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` | Run visible location monitoring on current Android versions. |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Declared because the same foreground service plays the repeating alarm. |
| `POST_NOTIFICATIONS` | Show the ongoing journey/alarm status on Android 13+. |
| `WAKE_LOCK` | Allows the active media player to keep audio playback operating with the screen off. |
| `INTERNET` | Query geocoding and routing endpoints. Location fallback still works without network routing. |

Request precise foreground location and notification permission before starting the journey. The service must be started while the activity is visible; Android then treats location access through the active location foreground service as foreground use, including when the screen turns off. This avoids asking for the more sensitive `ACCESS_BACKGROUND_LOCATION` permission in the MVP. Android 12+ users may choose approximate location; this app refuses to start if precision is insufficient for its 1–2 km alert boundary. If a future feature needs to start location monitoring while the app is already backgrounded, re-evaluate Android permission and Google Play policy before adding background access.

## Journey trigger rules

- **ETA rule:** `route ETA <= preparation window` (5 minutes by default).
- **Radius rule:** `distance <= configured radius + reported location-accuracy allowance`.
- **Poor fix rule:** ignore fixes reported worse than 100 m; keep monitoring and show a status message.
- **Once triggered:** persist `TRIGGERED`, stop location updates, start repeating alarm audio and update the ongoing notification. No further arrival checks run for that journey.
- **Fallback:** if routing fails, stale ETA is ignored and radius-only behavior remains active.

The ETA is a best-effort road estimate, not a promise. The OSRM public endpoint can fail, and route duration can diverge significantly from actual bus travel due to traffic, route deviations, stops, or data coverage.

## Manual device test plan (required before real use)

Use an Android phone, not only an emulator. Test with alarm volume audible and the phone locked. Have another safe navigation method available; do not test while driving.

### Permission and setup checks

- [ ] Fresh install: deny foreground location; app must explain the blocker and must not start monitoring.
- [ ] Grant precise foreground location and start a trip while the app is visible; lock the screen and verify the foreground service keeps monitoring without requesting `ACCESS_BACKGROUND_LOCATION`.
- [ ] Grant approximate location only; app should refuse reliable journey monitoring and explain how to enable precise location.
- [ ] Disable device Location; app must direct the user to Location settings.
- [ ] Deny notifications; app must explain that active journey status will be hidden and not silently claim full readiness.

### Screen-off and trigger checks

- [ ] Start a test destination about 3 km away, lock the screen, and move toward it. The ongoing notification must remain visible and distance/ETA should refresh.
- [ ] Trigger inside a 2 km radius with network disabled. The loud alarm must start and repeat.
- [ ] Trigger with a fresh OSRM ETA under the preparation window before entering the radius. Confirm the notification describes the ETA trigger.
- [ ] Keep the phone locked and verify alarm audio continues for at least five minutes until explicitly dismissed.
- [ ] Dismiss from the notification action. Audio must stop, the notification must clear, and status must become dismissed.
- [ ] Dismiss from the Flutter UI. Verify identical behavior.
- [ ] Start a second journey after dismissal. It must not inherit the prior trip's alarm state.
- [ ] Move with GPS disabled/poor, then restore GPS. The app must surface stale-fix status and recover without firing on a single bad fix.
- [ ] Reboot the device during an active trip. The current build does not promise trip restoration after reboot; document the observed behavior and add a boot-resume flow only if product policy and test results justify it.

### Battery and process checks

- [ ] Observe adaptive sampling: initial fixes use balanced power; monitoring slows beyond 10 km, tightens inside 10 km, and uses faster high-accuracy fixes inside 3 km.
- [ ] Repeat a screen-off trip with Android Battery Saver on and off.
- [ ] Repeat with app battery optimization enabled and then manually allow unrestricted/background use.
- [ ] Test Android's force-stop behavior: it is a hard stop and must not be represented as recoverable background monitoring.
- [ ] Test the phone's OEM-specific auto-start/sleep-management settings.
- [ ] Verify audio behavior with Do Not Disturb enabled and disabled, alarm volume low/high, wired/headset Bluetooth disconnected, and after screen-off for 15–30 minutes.

Record phone model, Android version, permission state, battery settings, estimated and actual trigger distance/time, and any alarm delay for each run.

## Replacing the routing/geocoding providers for release

- The map uses OpenStreetMap tiles and includes attribution. Review the tile usage policy before shipping at scale; do not treat the community tile servers as an unlimited commercial map API.
- The search uses the public Photon geocoding endpoint. Replace it with a provider whose rate limits, privacy terms, operational availability, and attribution meet your release requirements.
- The route request uses OSRM's public demo endpoint and is throttled in code to approximately one request per minute unless the device moves more than 800 m. Use an appropriate provider, documented quotas, and explicit API-key management before a production release.
- Avoid sending precise user location to third-party services without clear disclosure. Location is sent to the routing provider while road ETA is requested.

## Build/release checklist

- Change `applicationId` and Kotlin package to your real reverse-domain namespace.
- Replace the placeholder Android launcher icon and configure production signing.
- Document a privacy policy and location use-case disclosure before publishing.
- Re-check Google Play location-use disclosures and foreground-service declarations. Do not add background-location access unless the final feature set and store policy justify it.
- Decide whether a full-screen alarm UI is needed. It is intentionally not enabled in this MVP because Android 14+ restricts full-screen intents to qualifying alarm/calling use cases and the persistent audio + notification works without it.
- Add proper error reporting, analytics only with consent, an integration test on physical devices, and provider-failure monitoring before release.
