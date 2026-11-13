import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/cities.dart';

class LocationService {
  // Политика OpenStreetMap требует идентифицирующий User-Agent.
  // ЗАМЕНИТЕ email ниже на свой реальный — это требование сервиса Nominatim.
  static const String _userAgent =
      'SadovnikPro/0.1 (Flutter gardening app; contact: your-email@example.com)';

  static DateTime? _lastNominatimRequest;

  /// Главная функция: точные координаты + реальное название места.
  static Future<City?> getCurrentCity() async {
    // 1. Разрешения
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Геолокация выключена в настройках телефона');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('❌ Доступ к геолокации запрещён');
      return null;
    }

    // 2. Координаты (три стратегии)
    final position = await _resolvePosition();
    if (position == null) {
      debugPrint('💥 Координаты получить не удалось');
      return null;
    }
    debugPrint(
        '📍 Координаты: ${position.latitude}, ${position.longitude} (точность ${position.accuracy.toStringAsFixed(0)} м)');

    // 3. Название места через OpenStreetMap (бесплатно, без ключей)
    final geo = await _reverseGeocode(position.latitude, position.longitude);

    String name;
    String region;
    String district;

    if (geo != null && geo['settlement']!.isNotEmpty) {
      name = geo['settlement']!;
      region = geo['region']!.isNotEmpty ? geo['region']! : 'Самарская область';
      district =
          geo['district']!.isNotEmpty ? geo['district']! : 'Определено по GPS';
      debugPrint('🏷️ OSM определил: "$name", район: "$district"');
    } else {
      // Офлайн-запасной вариант: ближайший известный город (≤ 15 км)
      final cities = await CityRepository.instance.loadCities();
      City? nearest;
      double best = double.infinity;
      for (final c in cities) {
        final d =
            _distanceKm(position.latitude, position.longitude, c.lat, c.lon);
        if (d < best) {
          best = d;
          nearest = c;
        }
      }
      if (nearest != null && best <= 15.0) {
        name = nearest.name;
        region = nearest.region;
        district = '${nearest.district} (офлайн)';
        debugPrint(
            '🏙️ Офлайн-режим: ближайший город "$name" (${best.toStringAsFixed(1)} км)');
      } else {
        name =
            'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        region = 'Определено по GPS';
        district = 'Точные координаты';
        debugPrint('🌲 Название недоступно, использую координаты');
      }
    }

    // 4. ВАЖНО: для расчёта Луны — ВСЕГДА точные GPS-координаты пользователя
    return City(
      name: name,
      region: region,
      district: district,
      lat: position.latitude,
      lon: position.longitude,
      utcOffset: 4,
    );
  }

  /// Стратегия A: чистый Android LocationManager (без сервисов Google).
  /// Стратегия B: системный провайдер (быстро по Wi-Fi).
  /// Стратегия C: последние известные координаты.
  static Future<Position?> _resolvePosition() async {
    try {
      debugPrint('📡 Стратегия A: чистый GPS (LocationManager)...');
      final p = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      debugPrint('✅ Стратегия A сработала');
      return p;
    } catch (e) {
      debugPrint('⚠️ Стратегия A: $e');
    }

    try {
      debugPrint('📡 Стратегия B: системный провайдер (Wi-Fi/сети)...');
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      debugPrint('✅ Стратегия B сработала');
      return p;
    } catch (e) {
      debugPrint('⚠️ Стратегия B: $e');
    }

    try {
      debugPrint('📡 Стратегия C: кэш системы...');
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) {
        debugPrint('✅ Стратегия C сработала');
      }
      return p;
    } catch (e) {
      debugPrint('⚠️ Стратегия C: $e');
      return null;
    }
  }

  /// Обратное геокодирование через Nominatim (OpenStreetMap).
  /// Без API-ключей. Соблюдаем политику: User-Agent + не чаще 1 запроса/сек.
  static Future<Map<String, String>?> _reverseGeocode(
      double lat, double lon) async {
    // Лимит: не чаще 1 запроса в секунду (требование Nominatim)
    if (_lastNominatimRequest != null) {
      final diff = DateTime.now().difference(_lastNominatimRequest!);
      if (diff < const Duration(seconds: 1)) {
        await Future.delayed(const Duration(seconds: 1) - diff);
      }
    }
    _lastNominatimRequest = DateTime.now();

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lon&zoom=14&accept-language=ru',
      );
      debugPrint('🌍 Запрос названия к OpenStreetMap...');
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'ru');

      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('⚠️ Nominatim ответил кодом ${response.statusCode}');
        return null;
      }

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) return null;

      final address = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};

      String pick(List<String> keys) {
        for (final k in keys) {
          final v = address[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return '';
      }

      final settlement = pick([
        'city',
        'town',
        'village',
        'hamlet',
        'municipality',
        'suburb',
        'city_district',
      ]);
      final district = pick(['county', 'state_district']);
      final region = pick(['state']);

      if (settlement.isEmpty && district.isEmpty) return null;
      return {
        'settlement': settlement,
        'district': district,
        'region': region,
      };
    } catch (e) {
      debugPrint('⚠️ Nominatim недоступен: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static double _distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * (math.pi / 180);
}
