import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/crop_catalog.dart';
import '../data/planting_calendar.dart';
import '../data/user_reminder.dart';
import '../utils/moon_utils.dart';
import 'weather_service.dart';

/// Сервис умных напоминаний. Только хранит данные в SharedPreferences.
/// НЕ импортирует NotificationService — иначе будет circular import.
/// Планированием уведомлений занимается NotificationService.rescheduleAll().
class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  static const String _prefsKey = 'user_reminders_v1';

  List<UserReminder> _reminders = [];
  List<UserReminder> get reminders => List.unmodifiable(_reminders);

  /// Загружает напоминания из памяти. Уведомления не трогает.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _reminders = list
            .map((e) => UserReminder.fromJson(e as Map<String, dynamic>))
            .whereType<UserReminder>()
            .toList();
        debugPrint('📋 Загружено напоминаний: ${_reminders.length}');
      } catch (e) {
        debugPrint('⚠️ Ошибка загрузки напоминаний: $e');
        _reminders = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_reminders.map((r) => r.toJson()).toList()),
    );
  }

  /// Создаёт автоматическое напоминание для культуры по календарю.
  /// Возвращает null, если культура не найдена или такое напоминание уже есть.
  Future<UserReminder?> createForCrop(String cropName) async {
    final record = CropCatalog.byName(cropName);
    if (record == null) return null;

    final cal = PlantingCalendarUtils.forCrop(cropName);
    if (cal == null) return null;

    final now = DateTime.now();
    PlantingStage? nextStage;
    int minDays = 10000;
    for (final stage in cal.stages) {
      final days = stage.daysUntilStart(now);
      if (days >= 0 && days < minDays) {
        minDays = days;
        nextStage = stage;
      }
    }
    if (nextStage == null) return null;

    final target = DateTime(now.year, nextStage.startMonth, nextStage.startDay);

    final id =
        'auto_${record.id}_${target.millisecondsSinceEpoch}_${nextStage.title.hashCode}';
    if (_reminders.any((r) => r.id == id)) return null;

    final reminder = UserReminder(
      id: id,
      cropName: record.name,
      cropEmoji: record.emoji,
      type: _mapStageToType(nextStage),
      targetDate: target,
    );
    _reminders.add(reminder);
    await _save();
    return reminder;
  }

  ReminderType _mapStageToType(PlantingStage stage) {
    final t = stage.title.toLowerCase();
    if (t.contains('рассад')) return ReminderType.sowSeedling;
    if (t.contains('высад') || t.contains('грунт')) {
      return ReminderType.transplant;
    }
    if (t.contains('урожа') || t.contains('сбор')) {
      return ReminderType.harvest;
    }
    return ReminderType.custom;
  }

  Future<void> add(UserReminder reminder) async {
    _reminders.add(reminder);
    await _save();
  }

  Future<void> remove(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _save();
  }

  Future<void> toggle(String id, bool active) async {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i < 0) return;
    _reminders[i] = _reminders[i].copyWith(isActive: active);
    await _save();
  }

  /// Рекомендация по Луне и погоде. Безопасна при пустых данных.
  Future<String> recommendation(UserReminder reminder) async {
    final parts = <String>[];

    final moon = MoonUtils.getMoonInfo(DateTime.now());
    if (moon.isNewOrFull) {
      parts.add('Луна в фазе «${moon.phaseName}» — день покоя.');
    } else if (moon.isWaxing) {
      parts.add('Луна растущая (${moon.phaseName}) — время роста над землёй.');
    } else {
      parts.add('Луна убывающая (${moon.phaseName}) — время корнеплодов.');
    }

    final weather = WeatherService.instance.lastData;
    if (weather != null) {
      final risky = weather.forecast.where((f) => f.tempMin <= 2).toList();
      if (risky.isNotEmpty) {
        final minT =
            risky.map((f) => f.tempMin).reduce((a, b) => a < b ? a : b);
        parts.add(
            '⚠️ Ожидаются заморозки до ${minT.toStringAsFixed(0)}°C — укройте растения.');
      } else if (weather.soilTemp >= 12) {
        parts.add(
            'Почва прогрелась до ${weather.soilTemp.toStringAsFixed(0)}°C — можно высаживать.');
      } else {
        parts.add(
            'Почва ещё холодная (${weather.soilTemp.toStringAsFixed(0)}°C), подождите или используйте теплицу.');
      }
    }

    return parts.join(' ');
  }
}
