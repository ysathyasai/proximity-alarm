# Validation status

Validation performed in the project-generation environment on 2026-11-01:

- **Passed:** `python tool/verify_source.py` — Android manifest XML, required permission/service declarations, platform-channel name agreement, and expected source/test files.
- **Passed:** Pure Kotlin `ArrivalPolicy` smoke checks compiled with `kotlinc` and ran on the JVM.
- **Not run:** `flutter analyze`, Dart unit tests (`flutter test`), Android Gradle build, Kotlin/JUnit Android tests, emulator tests, and physical-device screen-off alarm tests.
- **Reason:** This environment does not have Flutter, Dart, Gradle, Android SDK/build tools, or an attached Android device. The project includes a Windows bootstrap script for obtaining Gradle wrapper files from the developer's installed Flutter template.

Do not rely on the app for an important journey until the device test matrix in `README.md` passes on the target phone. In particular, confirm permission behavior, location freshness, route-ETA fallback, screen-off monitoring, continuous audio playback, dismissal, and battery/OEM-specific behavior.
