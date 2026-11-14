import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/garden_store.dart';
import 'data/irrigation.dart';
import 'screens/home_screen.dart';
import 'services/reminder_service.dart';
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
  } catch (e) {
    debugPrint('⚠️ Уведомления (init): $e');
  }
  try {
    await ReminderService.instance.init();
    await NotificationService.rescheduleAll();
  } catch (e) {
    debugPrint('⚠️ Напоминания: $e');
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showHome = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) return const HomeScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1729),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'СадовникPRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Умный помощник для дачников',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
