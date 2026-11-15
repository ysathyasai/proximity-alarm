# Implementation plan and acceptance criteria

## Phase 1 — MVP foundation (included in this source package)

1. Create a Flutter UI and local storage for destinations and history.
2. Add search and map-pin destination selection.
3. Add Android MethodChannel commands for start, stop, status, and dismiss.
4. Start location monitoring from the visible app in a native Android foreground service.
5. Persist journey config/state in Android SharedPreferences so the Dart UI does not own service lifetime.
6. Implement ETA-or-radius decision policy and reject poor fixes.
7. Play the default Android alarm sound in a loop until a dismiss action is received.
8. Add pure decision-rule tests on Dart and Kotlin sides.

**Acceptance criteria:** destination selection works; a test destination can be started; the persistent notification appears; status contains location freshness and current distance; entering the test radius starts alarm audio; dismissal stops the audio and permits another journey.

## Phase 2 — Device reliability hardening

1. Add native instrumentation for service restart, process recreation, notification action, and permission-revocation cases.
2. Test on the target Android version and OEM; establish a documented battery/Doze baseline.
3. Add accurate handling for a last-known fix, stale route ETA, GPS off, disabled precise location, no network, and no route response.
4. Persist a lifecycle event log suitable for diagnostics (avoid collecting location history beyond the user's explicit choice).
5. Decide the product's boot behavior only after policy and UX review; do not silently restart location access after reboot.
6. Test all volume, audio-focus, DND, bluetooth, notification, and power scenarios.

**Acceptance criteria:** the team can distinguish permission blockers, stale GPS, unavailable route ETA, service shutdown, and audio failure from a healthy active state.

## Phase 3 — Production location/ETA

1. Select a supported routing provider with documented traffic data, availability, costs, and rate limits.
2. Keep routing calls rate-limited and use a clear privacy disclosure before sending origin/destination coordinates to that provider.
3. Maintain a fixed-radius fallback that never requires network availability.
4. Evaluate false-trigger rate and late-trigger rate using recorded test journeys across city, highway, tunnels, and dense urban settings.
5. Define a max accepted accuracy threshold, configurable preparation interval, and minimum alert lead time based on real measurements.

**Acceptance criteria:** ETA quality is measured against actual arrival across representative routes and the app displays when it is operating in fallback mode.

## Phase 4 — iOS implementation

1. Implement a separate Swift/Core Location adapter with region monitoring and background location modes.
2. Add iOS permission education, Always authorization, notification/alarm behavior and state restoration.
3. Document that iOS may defer location-region events and does not provide Android-equivalent arbitrary continuous background execution.
4. Keep shared Dart models and local-store contract where possible; do not force Android service assumptions into shared code.

## Key risks

- OS/OEM restrictions can interrupt background work or location delivery.
- GPS error and low update frequency can produce late or early triggers.
- Free routing/geocoding demo services are not guaranteed production infrastructure.
- Alarm volume, DND, headphones, and force-stop behavior are outside the app's complete control.
- The initial implementation is a source prototype until it passes real-device tests.
