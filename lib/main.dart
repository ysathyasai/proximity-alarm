import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/journey_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/settings_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global settings & background service
  await SettingsService.instance.initialize();
  await TransitBackgroundService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(
          value: SettingsService.instance,
        ),
        ChangeNotifierProvider<JourneyProvider>(
          create: (_) => JourneyProvider()..initialize(),
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
    final settings = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Transit Proximity Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
