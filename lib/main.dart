import 'package:flutter/material.dart';

import 'data/garden_store.dart';
import 'data/irrigation.dart';
import 'screens/home_screen.dart';
import 'services/weather_service.dart';
import 'utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await GardenStore.instance.init();
  } catch (e) {
    debugPrint('⚠️ Сад: $e');
  }
  try {
    await IrrigationSettings.instance.init();
  } catch (e) {
    debugPrint('⚠️ Настройки полива: $e');
  }
  try {
    await WeatherService.instance.init();
  } catch (e) {
    debugPrint('⚠️ Погода: $e');
  }
  try {
    await NotificationService.init();
    await NotificationService.rescheduleAll();
  } catch (e) {
    debugPrint('⚠️ Уведомления: $e');
  }
  runApp(const SadovnikProApp());
}

class SadovnikProApp extends StatelessWidget {
  const SadovnikProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'СадовникPRO',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
