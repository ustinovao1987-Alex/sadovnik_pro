import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/user_reminder.dart';
import '../services/reminder_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'sadovnik_work';

  /// Диапазон ID для напоминаний о посадках.
  static const int _reminderIdStart = 2000;
  static const int _reminderIdEnd = 2999;

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin
        .initialize(const InitializationSettings(android: androidInit));
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

    final exact = await canScheduleExact();
    debugPrint('✅ Сервис уведомлений готов (точные: $exact)');
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  static Future<bool> canScheduleExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      final can = await android.canScheduleExactNotifications();
      return can ?? true;
    } catch (e) {
      debugPrint('⚠️ canScheduleExact: $e');
      return false;
    }
  }

  static Future<bool> requestExactPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      final granted = await android.requestExactAlarmsPermission();
      debugPrint('🔔 requestExactAlarmsPermission: $granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('⚠️ requestExactAlarmsPermission: $e');
      return false;
    }
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Работы в саду',
          channelDescription: 'Напоминания о сроках посадки и ухода',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

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
    return tz.TZDateTime(
      loc,
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
    );
  }

  /// Пересоздаёт все уведомления напоминаний из ReminderService.
  static Future<void> rescheduleAll() async {
    if (!_ready) return;

    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _reminderIdStart && p.id <= _reminderIdEnd) {
        await _plugin.cancel(p.id);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    if (!enabled) {
      await prefs.setInt('notifications_count', 0);
      return;
    }

    final reminders = ReminderService.instance.reminders;
    final utcOffset = prefs.getInt('loc_utc') ?? 4;
    final now = DateTime.now();
    int id = _reminderIdStart;
    int scheduled = 0;

    final exactAllowed = await canScheduleExact();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('📅 Планирование напоминаний: '
        '${exactAllowed ? "точное (9:00)" : "примерное (±2ч)"}');

    for (final r in reminders) {
      if (!r.isActive) continue;
      if (r.targetDate.isBefore(now)) continue;
      if (id > _reminderIdEnd) break;

      final when = DateTime(
        r.targetDate.year,
        r.targetDate.month,
        r.targetDate.day,
        9,
        0,
      );
      if (when.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id++,
        '${r.cropEmoji} ${r.title}',
        '${r.cropName}: проверьте Луну и погоду в приложении.',
        _zoned(when, utcOffset),
        _details(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      scheduled++;
    }

    await prefs.setInt('notifications_count', scheduled);
    debugPrint('🔔 Запланировано напоминаний: $scheduled '
        '(${exactAllowed ? "exact" : "inexact"})');
  }

  static Future<void> cancelAll() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _reminderIdStart && p.id <= _reminderIdEnd) {
        await _plugin.cancel(p.id);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notifications_count', 0);
  }
}
