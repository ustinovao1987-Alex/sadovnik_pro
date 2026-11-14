import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/climate_engine.dart';
import '../data/climate_zones.dart';
import '../data/irrigation.dart';
import '../data/region_profile.dart';

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final double precipitation;
  final int daysAhead;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitation,
    required this.daysAhead,
  });

  String get weatherDescription => _codeToText(weatherCode);
  IconData get weatherIcon => _codeToIcon(weatherCode);
}

class WeatherData {
  final double currentTemp;
  final double soilTemp;
  final double currentHumidity;
  final double windSpeed;
  final double? precipitation;
  final int weatherCode;
  final List<DailyForecast> forecast;
  final DateTime lastUpdated;
  final String locationName;
  final String source;
  final bool isFallback;

  WeatherData({
    required this.currentTemp,
    required this.soilTemp,
    required this.currentHumidity,
    required this.windSpeed,
    this.precipitation,
    required this.weatherCode,
    required this.forecast,
    required this.lastUpdated,
    required this.locationName,
    required this.source,
    this.isFallback = false,
  });

  String get weatherDescription => _codeToText(weatherCode);
  IconData get weatherIcon => _codeToIcon(weatherCode);

  bool get hasFrostWarning =>
      forecast.any((f) => f.tempMin < 0 && f.daysAhead <= 3);
  bool get hasHeatWarning =>
      forecast.any((f) => f.tempMax > 35 && f.daysAhead <= 3);
  bool get hasSevereFrost =>
      forecast.any((f) => f.tempMin <= -3 && f.daysAhead <= 3);
  bool get hasFrostRisk =>
      forecast.any((f) => f.tempMin <= 2 && f.daysAhead <= 3);

  Map<String, dynamic> toJson() {
    return {
      'currentTemp': currentTemp,
      'soilTemp': soilTemp,
      'currentHumidity': currentHumidity,
      'windSpeed': windSpeed,
      'precipitation': precipitation,
      'weatherCode': weatherCode,
      'forecast': forecast
          .map((f) => {
                'date': f.date.toIso8601String(),
                'tempMax': f.tempMax,
                'tempMin': f.tempMin,
                'weatherCode': f.weatherCode,
                'precipitation': f.precipitation,
                'daysAhead': f.daysAhead,
              })
          .toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'locationName': locationName,
      'source': source,
      'isFallback': isFallback,
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final forecastList = (json['forecast'] as List).map((f) {
      return DailyForecast(
        date: DateTime.parse(f['date'] as String),
        tempMax: (f['tempMax'] as num).toDouble(),
        tempMin: (f['tempMin'] as num).toDouble(),
        weatherCode: f['weatherCode'] as int,
        precipitation: (f['precipitation'] as num).toDouble(),
        daysAhead: f['daysAhead'] as int,
      );
    }).toList();

    return WeatherData(
      currentTemp: (json['currentTemp'] as num).toDouble(),
      soilTemp: (json['soilTemp'] as num).toDouble(),
      currentHumidity: (json['currentHumidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      precipitation: json['precipitation'] == null
          ? null
          : (json['precipitation'] as num).toDouble(),
      weatherCode: json['weatherCode'] as int,
      forecast: forecastList,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      locationName: json['locationName'] as String? ?? 'Ваш регион',
      source: json['source'] as String? ?? 'unknown',
      isFallback: (json['isFallback'] as bool?) ?? false,
    );
  }
}

String _codeToText(int code) {
  switch (code) {
    case 0:
      return 'Ясно';
    case 1:
      return 'Преимущественно ясно';
    case 2:
      return 'Переменная облачность';
    case 3:
      return 'Пасмурно';
    case 45:
    case 48:
      return 'Туман';
    case 51:
    case 53:
    case 55:
      return 'Морось';
    case 61:
      return 'Слабый дождь';
    case 63:
      return 'Умеренный дождь';
    case 65:
      return 'Сильный дождь';
    case 71:
      return 'Слабый снег';
    case 73:
      return 'Умеренный снег';
    case 75:
      return 'Сильный снег';
    case 80:
      return 'Слабый ливень';
    case 81:
      return 'Умеренный ливень';
    case 82:
      return 'Сильный ливень';
    case 95:
      return 'Гроза';
    default:
      return 'Облачно';
  }
}

IconData _codeToIcon(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code >= 1 && code <= 2) return Icons.wb_cloudy;
  if (code == 3) return Icons.cloud;
  if (code >= 45 && code <= 48) return Icons.foggy;
  if (code >= 51 && code <= 57) return Icons.umbrella;
  if (code >= 61 && code <= 67) return Icons.umbrella;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.water_drop;
  if (code >= 85 && code <= 86) return Icons.ac_unit;
  if (code >= 95) return Icons.flash_on;
  return Icons.cloud;
}

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const Duration _cacheDuration = Duration(hours: 3);
  static const String _kLastFetch = 'weather_last_fetch_v6';
  static const String _kLastData = 'weather_last_data_v6';

  WeatherData? _lastData;
  WeatherData? get lastData => _lastData;

  RegionProfile? _regionProfile;
  ClimateZone? _climateZone;
  RegionProfile? get regionProfile => _regionProfile;
  ClimateZone? get climateZone => _climateZone;

  void refreshRegionAndClimate(double latitude, double longitude) {
    try {
      _regionProfile = ClimateEngine.resolve(latitude, longitude);
      _climateZone = ClimateZoneDetector.detect(
        latitude: latitude,
        longitude: longitude,
        profile: _regionProfile,
      );
    } catch (e) {
      debugPrint('⚠️ Регион/климат: $e');
      _regionProfile = null;
      _climateZone = null;
    }
    debugPrint('🌍 Регион: ${_regionProfile?.name ?? "не определён"}');
    debugPrint('🌡️ Климат: ${_climateZone?.name ?? "не определён"}');
  }

  String _buildOpenMeteoUrl(double lat, double lon) {
    return 'https://api.open-meteo.com/v1/forecast?'
        'latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m'
        '&hourly=temperature_2m,soil_temperature_6cm'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code'
        '&temperature_unit=celsius&wind_speed_unit=kmh&precipitation_unit=mm'
        '&timezone=auto&forecast_days=7';
  }

  List<String> _proxiesFor(String originalUrl) {
    return [
      'https://proxy.cors.dev/$originalUrl',
      'https://corsproxy.io/?$originalUrl',
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}',
    ];
  }

  Future<Map<String, dynamic>?> _fetchJsonWithProxyCascade(
      String originalUrl) async {
    final direct =
        await _tryFetchJson(originalUrl, 'Прямой запрос', retries: 1);
    if (direct != null) return direct;

    final proxies = _proxiesFor(originalUrl);
    for (int i = 0; i < proxies.length; i++) {
      final proxyUrl = proxies[i];
      final name = 'Прокси #${i + 1} (${Uri.parse(proxyUrl).host})';
      final result = await _tryFetchJson(proxyUrl, name, retries: 2);
      if (result != null) {
        debugPrint('✅ Сработал $name');
        return result;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _tryFetchJson(
    String url,
    String sourceName, {
    int retries = 1,
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      final client = http.Client();
      try {
        debugPrint('🌤️ Попытка $attempt/$retries: $sourceName...');
        final response = await client.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'SadovnikPro/1.0 (Flutter; Android)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode != 200) {
          debugPrint('⚠️ $sourceName: HTTP ${response.statusCode}');
          continue;
        }

        final body = response.body.trim();
        if (body.isEmpty || body.startsWith('<')) {
          debugPrint('⚠️ $sourceName: не JSON');
          continue;
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['current'] is! Map) {
          debugPrint('⚠️ $sourceName: нет поля current');
          continue;
        }

        debugPrint('✅ $sourceName: успешно');
        return decoded;
      } catch (e) {
        debugPrint('❌ $sourceName (попытка $attempt): $e');
        if (attempt == retries) return null;
        await Future.delayed(const Duration(seconds: 2));
      } finally {
        client.close();
      }
    }
    return null;
  }

  WeatherData? _parseOpenMeteoResponse(
      Map<String, dynamic> data, String locationName, String source) {
    final current = data['current'];
    if (current is! Map<String, dynamic>) return null;

    final currentTemp = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
    final humidity =
        (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0;
    final precip = (current['precipitation'] as num?)?.toDouble();
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

    final hourly = data['hourly'];
    double soilTemp = currentTemp - 2;
    if (hourly is Map<String, dynamic>) {
      final soilTemps = hourly['soil_temperature_6cm'];
      final times = hourly['time'];
      if (soilTemps is List && times is List && soilTemps.isNotEmpty) {
        final now = DateTime.now();
        int bestIndex = 0;
        Duration bestDiff = const Duration(days: 100);
        for (int i = 0; i < times.length && i < soilTemps.length; i++) {
          try {
            final t = DateTime.parse(times[i] as String);
            final diff = (t.difference(now)).abs();
            if (diff < bestDiff) {
              bestDiff = diff;
              bestIndex = i;
            }
          } catch (_) {
            continue;
          }
        }
        final v = soilTemps[bestIndex];
        if (v is num) soilTemp = v.toDouble();
      }
    }

    final daily = data['daily'];
    final forecast = <DailyForecast>[];
    if (daily is Map<String, dynamic>) {
      final dates = daily['time'] as List?;
      final tempMaxs = daily['temperature_2m_max'] as List?;
      final tempMins = daily['temperature_2m_min'] as List?;
      final codes = daily['weather_code'] as List?;
      final precips = daily['precipitation_sum'] as List?;

      if (dates != null && tempMaxs != null && tempMins != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        for (int i = 0; i < dates.length && i < 7; i++) {
          try {
            final date = DateTime.parse(dates[i] as String);
            final daysAhead = date.difference(todayStart).inDays;
            forecast.add(DailyForecast(
              date: date,
              tempMax: (tempMaxs[i] as num?)?.toDouble() ?? 0.0,
              tempMin: (tempMins[i] as num?)?.toDouble() ?? 0.0,
              weatherCode: (codes?[i] as num?)?.toInt() ?? 0,
              precipitation: (precips?[i] as num?)?.toDouble() ?? 0.0,
              daysAhead: daysAhead,
            ));
          } catch (_) {
            continue;
          }
        }
      }
    }

    return WeatherData(
      currentTemp: currentTemp,
      soilTemp: soilTemp,
      currentHumidity: humidity,
      windSpeed: wind,
      precipitation: precip,
      weatherCode: weatherCode,
      forecast: forecast,
      lastUpdated: DateTime.now(),
      locationName: locationName,
      source: source,
      isFallback: false,
    );
  }

  Future<WeatherData?> fetchAndUpdate({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString('loc_name') ?? 'Ваш регион';

      refreshRegionAndClimate(latitude, longitude);

      final lastFetchStr = prefs.getString(_kLastFetch);
      final lastDataStr = prefs.getString(_kLastData);

      if (lastFetchStr != null && lastDataStr != null) {
        final lastFetch = DateTime.tryParse(lastFetchStr);
        if (lastFetch != null &&
            DateTime.now().difference(lastFetch) < _cacheDuration) {
          debugPrint('🌤️ Используем свежий кэш');
          final cached = WeatherData.fromJson(
              jsonDecode(lastDataStr) as Map<String, dynamic>);
          _lastData = cached;
          await _updateIrrigationSettings(cached);
          return cached;
        }
      }

      debugPrint('🌤️ Загружаем прогноз (каскад прокси)...');

      final originalUrl = _buildOpenMeteoUrl(latitude, longitude);
      final json = await _fetchJsonWithProxyCascade(originalUrl);

      WeatherData? weatherData;
      if (json != null) {
        weatherData = _parseOpenMeteoResponse(json, locationName, 'Open-Meteo');
      }

      if (weatherData == null && lastDataStr != null) {
        debugPrint('⚠️ Все прокси упали, используем старый кэш');
        try {
          final old = WeatherData.fromJson(
              jsonDecode(lastDataStr) as Map<String, dynamic>);
          weatherData = WeatherData(
            currentTemp: old.currentTemp,
            soilTemp: old.soilTemp,
            currentHumidity: old.currentHumidity,
            windSpeed: old.windSpeed,
            precipitation: old.precipitation,
            weatherCode: old.weatherCode,
            forecast: old.forecast,
            lastUpdated: old.lastUpdated,
            locationName: locationName,
            source: 'Кэш (устаревшие)',
            isFallback: true,
          );
        } catch (e) {
          debugPrint('⚠️ Ошибка парсинга старого кэша: $e');
        }
      }

      if (weatherData == null) {
        debugPrint('❌ Все источники недоступны — сезонные данные по зоне');
        return _fallbackWeatherData(latitude, longitude, locationName);
      }

      _lastData = weatherData;

      if (!weatherData.isFallback) {
        await prefs.setString(_kLastFetch, DateTime.now().toIso8601String());
        await prefs.setString(_kLastData, jsonEncode(weatherData.toJson()));
      }

      await _updateIrrigationSettings(weatherData);

      debugPrint(
          '✅ Погода: ${weatherData.currentTemp.toStringAsFixed(1)}°C из ${weatherData.source}'
          '${weatherData.isFallback ? " (fallback)" : ""}');
      return weatherData;
    } catch (e, stack) {
      debugPrint('❌ Критическая ошибка: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// ✅ НОВОЕ: fallback-погода зависит от климатической зоны и месяца,
  /// а не от «средней полосы». Для Алматы в январе будет +2, для Мурманска −15.
  WeatherData _fallbackWeatherData(
    double latitude,
    double longitude,
    String locationName,
  ) {
    final zone = _climateZone ??
        ClimateZoneDetector.detect(
          latitude: latitude,
          longitude: longitude,
          profile: _regionProfile,
        );

    final now = DateTime.now();
    final month = now.month;
    final temp = _monthlyAvgFor(zone, month);
    final soilTemp = temp - 3;

    final forecast = <DailyForecast>[];
    for (int i = 0; i < 7; i++) {
      forecast.add(DailyForecast(
        date: now.add(Duration(days: i)),
        tempMax: temp + 4,
        tempMin: temp - 4,
        weatherCode: 3,
        precipitation: 0,
        daysAhead: i,
      ));
    }

    final zoneName = ClimateZoneInfo.getDetails(zone).name;
    debugPrint('⚠️ Сезонная заглушка: $zoneName, месяц $month, '
        'средняя $temp°C');

    return WeatherData(
      currentTemp: temp,
      soilTemp: soilTemp,
      currentHumidity: 65,
      windSpeed: 10,
      precipitation: null,
      weatherCode: 3,
      forecast: forecast,
      lastUpdated: now,
      locationName: locationName,
      source: 'Сезонные данные ($zoneName)',
      isFallback: true,
    );
  }

  /// Средние многолетние температуры по климатической зоне и месяцу.
  /// Источник — климатические справочники, значения округлены до целых.
  double _monthlyAvgFor(ClimateZone zone, int month) {
    // Индекс 0 = январь, 11 = декабрь
    const Map<ClimateZone, List<double>> table = {
      ClimateZone.arctic: [
        -28,
        -28,
        -26,
        -18,
        -8,
        1,
        8,
        6,
        0,
        -10,
        -20,
        -26,
      ],
      ClimateZone.subarctic: [
        -22,
        -21,
        -16,
        -8,
        0,
        8,
        14,
        12,
        5,
        -3,
        -12,
        -19,
      ],
      ClimateZone.temperate: [
        -8,
        -7,
        -2,
        6,
        13,
        18,
        21,
        19,
        13,
        6,
        0,
        -5,
      ],
      ClimateZone.continental: [
        -20,
        -17,
        -8,
        3,
        12,
        18,
        22,
        20,
        13,
        4,
        -8,
        -17,
      ],
      ClimateZone.subtropical: [
        4,
        5,
        9,
        14,
        19,
        24,
        28,
        27,
        23,
        17,
        11,
        6,
      ],
    };
    final row = table[zone] ?? table[ClimateZone.temperate]!;
    return row[(month - 1).clamp(0, 11)];
  }

  Future<void> _updateIrrigationSettings(WeatherData data) async {
    final preset = _tempToPreset(data.currentTemp);
    await IrrigationSettings.instance.setWeather(preset);

    final hasRainNow = data.weatherCode >= 51 && data.weatherCode <= 67;
    if (hasRainNow || (data.precipitation ?? 0) > 1.0) {
      await IrrigationSettings.instance.setRainToday(true);
    }
  }

  WeatherPreset _tempToPreset(double temp) {
    if (temp < 18) return WeatherPreset.cool;
    if (temp < 25) return WeatherPreset.mild;
    if (temp < 30) return WeatherPreset.warm;
    if (temp < 35) return WeatherPreset.hot;
    return WeatherPreset.heatwave;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDataStr = prefs.getString(_kLastData);
    if (lastDataStr != null) {
      try {
        _lastData = WeatherData.fromJson(
            jsonDecode(lastDataStr) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ Ошибка кэша: $e');
      }
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastFetch);
    await prefs.remove(_kLastData);
    _lastData = null;
  }
}
