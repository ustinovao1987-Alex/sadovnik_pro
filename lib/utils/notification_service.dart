import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/planting_calendar.dart';

/// Сервис напоминаний о работах в саду.
/// Планирует уведомления на 90 дней вперёд, пересоздаёт их при каждом запуске.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sadovnik_work';
  static bool _ready = false;

  /// Инициализация — вызывать один раз при старте приложения.
  static Future<void> init() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Работы в саду',
      description: 'Напоминания о сроках посадки и ухода за растениями',
      importance: Importance.high,
    ));

    tzdata.initializeTimeZones();
    _ready = true;
    debugPrint('🔔 Сервис уведомлений готов');
  }

  /// Запрос разрешения (Android 13+). Возвращает true, если можно показывать.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Работы в саду',
          channelDescription:
              'Напоминания о сроках посадки и ухода за растениями',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Часовой пояс сада: UTC+4 → 'Etc/GMT-4' (знаки POSIX инвертированы).
  static tz.TZDateTime _zoned(DateTime wallClock, int utcOffset) {
    final String name;
    if (utcOffset == 0) {
      name = 'UTC';
    } else if (utcOffset > 0) {
      name = 'Etc/GMT-$utcOffset';
    } else {
      name = 'Etc/GMT+${-utcOffset}';
    }
    final loc = tz.getLocation(name);
    return tz.TZDateTime(loc, wallClock.year, wallClock.month, wallClock.day,
        wallClock.hour, wallClock.minute);
  }

  static Future<void> _schedule(
      int id, String title, String body, DateTime when, int utcOffset) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _zoned(when, utcOffset),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Пересоздаёт все напоминания на 90 дней вперёд.
  /// Возвращает количество запланированных уведомлений.
  static Future<int> rescheduleAll() async {
    if (!_ready) return 0;
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    if (!enabled) {
      await prefs.setInt('notifications_count', 0);
      return 0;
    }

    final utcOffset = prefs.getInt('loc_utc') ?? 4;
    final now = DateTime.now();
    int id = 1000;
    int count = 0;

    for (final cal in kPlantingCalendars) {
      for (final s in cal.stages) {
        if (!s.isPlanting) continue; // напоминаем о посадках/посевах

        var start = DateTime(now.year, s.startMonth, s.startDay, 9, 0);
        if (start.isBefore(now)) {
          start = DateTime(now.year + 1, s.startMonth, s.startDay, 9, 0);
        }
        if (start.difference(now).inDays > 90) continue;

        // За 3 дня до открытия окна
        final pre = start.subtract(const Duration(days: 3));
        if (pre.isAfter(now)) {
          await _schedule(
            id++,
            'Скоро: ${s.title} 🌱',
            '${cal.name}: окно откроется ${s.rangeText}. Подготовьте семена и грунт.',
            pre,
            utcOffset,
          );
          count++;
        }

        // В день открытия окна
        await _schedule(
          id++,
          'Сегодня можно: ${s.title} ✅',
          '${cal.name}: благоприятное окно ${s.rangeText}. Проверьте погоду и почву.',
          start,
          utcOffset,
        );
        count++;
      }
    }

    await prefs.setInt('notifications_count', count);
    debugPrint('🔔 Запланировано напоминаний: $count');
    return count;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notifications_count', 0);
  }

  /// Мгновенное тестовое уведомление.
  static Future<void> showTest() async {
    await _plugin.show(
      0,
      'СадовникPRO 🌱',
      'Уведомления работают! Напоминания о посадках будут приходить сюда.',
      _details(),
    );
  }

  /// Тест планировщика: уведомление через 1 минуту (может прийти чуть позже).
  static Future<void> scheduleTest() async {
    final prefs = await SharedPreferences.getInstance();
    final utcOffset = prefs.getInt('loc_utc') ?? 4;
    await _schedule(
      999999,
      'Тест по расписанию ⏰',
      'Если вы это видите — запланированные напоминания работают!',
      DateTime.now().add(const Duration(minutes: 1)),
      utcOffset,
    );
  }
}
