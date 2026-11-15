#!/usr/bin/env python3
"""Fast source-structure checks that do not require Flutter or the Android SDK."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID_NS = '{http://schemas.android.com/apk/res/android}'


def fail(message: str) -> None:
    print(f'FAIL: {message}')
    sys.exit(1)

manifest_path = ROOT / 'android/app/src/main/AndroidManifest.xml'
try:
    manifest = ET.parse(manifest_path).getroot()
except Exception as exc:  # noqa: BLE001
    fail(f'AndroidManifest.xml is not valid XML: {exc}')

permissions = {node.get(ANDROID_NS + 'name') for node in manifest.findall('uses-permission')}
required_permissions = {
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_LOCATION',
    'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.WAKE_LOCK',
    'android.permission.INTERNET',
}
missing = required_permissions - permissions
if missing:
    fail('Missing manifest permissions: ' + ', '.join(sorted(missing)))
if 'android.permission.ACCESS_BACKGROUND_LOCATION' in permissions:
    fail('The MVP should not request ACCESS_BACKGROUND_LOCATION; the journey is armed while the app is visible and continues in a location foreground service.')

application = manifest.find('application')
if application is None:
    fail('Manifest has no application element')
services = application.findall('service')
service = next((item for item in services if item.get(ANDROID_NS + 'name') == '.ProximityTrackingService'), None)
if service is None:
    fail('ProximityTrackingService is not declared')
if 'location' not in (service.get(ANDROID_NS + 'foregroundServiceType') or ''):
    fail('Location foreground-service type is not declared')

channel = 'app.proximityalarm/journey'
main_activity = (ROOT / 'android/app/src/main/kotlin/com/example/proximity_alarm/MainActivity.kt').read_text()
flutter_bridge = (ROOT / 'lib/services/native_journey_service.dart').read_text()
if channel not in main_activity or channel not in flutter_bridge:
    fail('Flutter and Android MethodChannel names do not match')

native = (ROOT / 'android/app/src/main/kotlin/com/example/proximity_alarm/ProximityTrackingService.kt').read_text()
for required in ('ACTION_START', 'ACTION_DISMISS', 'ROUTING_BASE_URL', 'triggerAlarm', 'startAlarmSound', 'removeLocationUpdates'):
    if required not in native:
        fail(f'Native service is missing expected path: {required}')
if 'https://router.project-osrm.org' not in native:
    fail('Expected prototype route endpoint was not found')

for relative in ('lib/main.dart', 'lib/screens/home_screen.dart', 'lib/screens/destination_picker_screen.dart',
                 'lib/services/local_store.dart', 'lib/services/place_search_service.dart',
                 'test/arrival_policy_test.dart', 'android/app/src/test/kotlin/com/example/proximity_alarm/ArrivalPolicyTest.kt'):
    if not (ROOT / relative).is_file():
        fail(f'Missing project file: {relative}')

print('PASS: manifest XML parses, foreground location/alarm permissions are declared, the Android service is registered,')
print('      Flutter/Android channel names match, and expected MVP source/test files are present.')
print('NOTE: this is a structural check only; it does not replace flutter analyze, flutter test, Gradle tests, or device testing.')
