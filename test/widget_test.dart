import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proximity_alarm/core/constants/app_constants.dart';
import 'package:proximity_alarm/core/theme/app_theme.dart';
import 'package:proximity_alarm/data/models/destination.dart';
import 'package:proximity_alarm/data/repositories/local_storage_repository.dart';
import 'package:proximity_alarm/presentation/screens/active_journey_screen.dart';
import 'package:proximity_alarm/presentation/screens/home_screen.dart';
import 'package:proximity_alarm/presentation/screens/settings_screen.dart';
import 'package:proximity_alarm/providers/journey_history_provider.dart';
import 'package:proximity_alarm/providers/journey_provider.dart';
import 'package:proximity_alarm/providers/saved_destinations_provider.dart';
import 'package:proximity_alarm/providers/settings_provider.dart';
import 'package:proximity_alarm/services/alarm_service.dart';
import 'package:proximity_alarm/services/background_monitoring_service.dart';
import 'package:proximity_alarm/services/location_service.dart';
import 'package:proximity_alarm/services/notification_service.dart';
import 'package:proximity_alarm/services/routing_service.dart';

void main() {
  testWidgets('App renders Home screen with navigation and start button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalStorageRepository(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(repository)),
          ChangeNotifierProvider(
              create: (_) => SavedDestinationsProvider(repository)),
          ChangeNotifierProvider(
              create: (_) => JourneyHistoryProvider(repository)),
          ChangeNotifierProvider(
            create: (_) => JourneyProvider(
              locationService: LocationService(),
              routingService: RoutingService(),
              alarmService: AlarmService(),
              notificationService: NotificationService(),
              backgroundService: BackgroundMonitoringService(),
              repository: repository,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app title exists
    expect(find.text(AppConstants.appName), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify destination prompt
    expect(find.text('Select a Destination First'), findsOneWidget);
  });

  testWidgets('Settings screen renders theme choices and alert sounds',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalStorageRepository(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(repository)),
          ChangeNotifierProvider(
              create: (_) => SavedDestinationsProvider(repository)),
          ChangeNotifierProvider(
              create: (_) => JourneyHistoryProvider(repository)),
          ChangeNotifierProvider(
            create: (_) => JourneyProvider(
              locationService: LocationService(),
              routingService: RoutingService(),
              alarmService: AlarmService(),
              notificationService: NotificationService(),
              backgroundService: BackgroundMonitoringService(),
              repository: repository,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings & Customization'), findsOneWidget);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Accent Brand Color'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('ALARM AUDIO, HAPTICS & DISMISSAL'), findsOneWidget);
  });

  testWidgets('ActiveJourneyScreen renders monitoring status and toggles OLED Night Nap display',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalStorageRepository(prefs);

    final journeyProvider = JourneyProvider(
      locationService: LocationService(),
      routingService: RoutingService(),
      alarmService: AlarmService(),
      notificationService: NotificationService(),
      backgroundService: BackgroundMonitoringService(),
      repository: repository,
    );

    journeyProvider.selectDestination(
      Destination(
        name: 'Grand Central Station',
        address: 'Downtown Main St',
        latitude: 13.0827,
        longitude: 80.2707,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(repository)),
          ChangeNotifierProvider(create: (_) => SavedDestinationsProvider(repository)),
          ChangeNotifierProvider(create: (_) => JourneyHistoryProvider(repository)),
          ChangeNotifierProvider.value(value: journeyProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ActiveJourneyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Grand Central Station'), findsOneWidget);
    expect(find.text('STOP JOURNEY'), findsOneWidget);

    // Toggle Night Nap mode
    await tester.tap(find.byIcon(Icons.nightlight_round));
    await tester.pumpAndSettle();

    expect(find.text('Tap anywhere to wake display'), findsOneWidget);

    // Tap to wake
    await tester.tap(find.text('Tap anywhere to wake display'));
    await tester.pumpAndSettle();

    expect(find.text('STOP JOURNEY'), findsOneWidget);
  });
}
