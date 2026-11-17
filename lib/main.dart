import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/local_storage_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'providers/journey_history_provider.dart';
import 'providers/journey_provider.dart';
import 'providers/saved_destinations_provider.dart';
import 'providers/settings_provider.dart';
import 'services/alarm_service.dart';
import 'services/background_monitoring_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/routing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize foreground task communication port
  BackgroundMonitoringService.initCommunication();

  // Initialize notification channels
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize repositories and services
  final storageRepository = await LocalStorageRepository.getInstance();
  final locationService = LocationService();
  final routingService = RoutingService();
  final alarmService = AlarmService();
  final backgroundService = BackgroundMonitoringService();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageRepository>.value(
          value: storageRepository,
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedDestinationsProvider(storageRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => JourneyHistoryProvider(storageRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => JourneyProvider(
            locationService: locationService,
            routingService: routingService,
            alarmService: alarmService,
            notificationService: notificationService,
            backgroundService: backgroundService,
            repository: storageRepository,
          ),
        ),
      ],
      child: const ProximityAlarmApp(),
    ),
  );
}

class ProximityAlarmApp extends StatelessWidget {
  const ProximityAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(settingsProvider.accentColor),
      darkTheme: settingsProvider.isPitchBlack
          ? AppTheme.getPitchBlackTheme(settingsProvider.accentColor)
          : AppTheme.getDarkTheme(settingsProvider.accentColor),
      themeMode: settingsProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}
