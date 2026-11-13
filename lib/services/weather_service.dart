import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/irrigation.dart';
import '../data/region_profile.dart';
import '../data/climate_zones.dart';

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
    case 56:
    case 57:
      return 'Ледяная морось';
    case 61:
      return 'Слабый дождь';
    case 63:
      return 'Умеренный дождь';
    case 65:
      return 'Сильный дождь';
    case 66:
    case 67:
      return 'Ледяной дождь';
    case 71:
      return 'Слабый снег';
    case 73:
      return 'Умеренный снег';
    case 75:
      return 'Сильный снег';
    case 77:
      return 'Снежные зёрна';
    case 80:
      return 'Слабый ливень';
    case 81:
      return 'Умеренный ливень';
    case 82:
      return 'Сильный ливень';
    case 85:
      return 'Слабый снегопад';
    case 86:
      return 'Сильный снегопад';
    case 95:
      return 'Гроза';
    case 96:
    case 99:
      return 'Гроза с градом';
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
  static const String _kTimezone = 'weather_timezone_v1';

  WeatherData? _lastData;
  WeatherData? get lastData => _lastData;

  // === Новое: часовой пояс, регион, климатическая зона ===
  String? _timezone;
  RegionProfile? _regionProfile;
  ClimateZone? _climateZone;

  String? get timezone => _timezone;
  RegionProfile? get regionProfile => _regionProfile;
  ClimateZone? get climateZone => _climateZone;

  Future<WeatherData?> _fetchFromURL(
      String url, String sourceName, String locationName) async {
    debugPrint('🌤️ Попытка загрузки из $sourceName...');

    final client = http.Client();
    try {
      final response = await client.get(Uri.parse(url), headers: {
        'User-Agent': 'SadovnikPro/1.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('⚠️ $sourceName вернул код ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        debugPrint('⚠️ Неверный формат ответа $sourceName');
        return null;
      }

      final result = _parseOpenMeteoResponse(data, locationName, sourceName);
      if (result != null) {
        debugPrint('✅ Успешно загружено из $sourceName');
      }
      return result;
    } catch (e, stack) {
      debugPrint('❌ Ошибка $sourceName: $e');
      debugPrint('Stack: $stack');
      return null;
    } finally {
      client.close();
    }
  }

  WeatherData? _parseOpenMeteoResponse(
      Map<String, dynamic> data, String locationName, String source) {
    final current = data['current'];
    if (current is! Map<String, dynamic>) {
      debugPrint('⚠️ Нет данных о текущей погоде');
      return null;
    }

    // ✅ Timezone берём из API — это ТОЧНОЕ значение, а не приближение
    final apiTimezone = data['timezone'];
    if (apiTimezone is String && apiTimezone.isNotEmpty) {
      _timezone = apiTimezone;
      debugPrint('🕐 Timezone из API: $_timezone');
    }

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
    );
  }

  Future<WeatherData?> fetchAndUpdate({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString('loc_name') ?? 'Ваш регион';

      // === Автоопределение региона и климатической зоны ===
      try {
        _regionProfile = RegionProfiles.findByCoordinates(latitude, longitude);
        _climateZone = ClimateZoneDetector.detect(
          latitude: latitude,
          longitude: longitude,
          profile: _regionProfile,
        );

        // ✅ Защита: корректируем только если ОБА не null
        if (_regionProfile != null && _climateZone != null) {
          _regionProfile = ClimateZoneDetector.adjustProfile(
            _regionProfile!,
            _climateZone!,
          );
        }

        debugPrint('🌍 Регион: ${_regionProfile?.name ?? "Не определён"}');
        debugPrint(
            '🌡️ Климатическая зона: ${_climateZone?.name ?? "Не определена"}');
      } catch (e) {
        // Если файлы region_profile/climate_zones сломаны — не падаем
        debugPrint('⚠️ Не удалось определить регион: $e');
        _regionProfile = null;
        _climateZone = null;
      }
      // ==================================================

      final lastFetchStr = prefs.getString(_kLastFetch);
      final lastDataStr = prefs.getString(_kLastData);

      if (lastFetchStr != null && lastDataStr != null) {
        final lastFetch = DateTime.tryParse(lastFetchStr);
        if (lastFetch != null &&
            DateTime.now().difference(lastFetch) < _cacheDuration) {
          debugPrint('🌤️ Используем кэшированную погоду');
          final cached = WeatherData.fromJson(
              jsonDecode(lastDataStr) as Map<String, dynamic>);

          // Восстанавливаем timezone из кэша
          _timezone ??= _regionProfile?.timezone;
          if (_timezone != null) {
            debugPrint('🕐 Timezone из RegionProfile: $_timezone');
          }

          _lastData = cached;
          await _updateIrrigationSettings(cached);
          return cached;
        }
      }

      debugPrint('🌤️ Загружаем прогноз для $latitude, $longitude...');

      final params = 'latitude=$latitude&longitude=$longitude'
          '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m'
          '&hourly=temperature_2m,soil_temperature_6cm'
          '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code'
          '&temperature_unit=celsius&wind_speed_unit=kmh&precipitation_unit=mm'
          '&timezone=auto&forecast_days=7';

      WeatherData? weatherData = await _fetchFromURL(
        'https://api.open-meteo.com/v1/forecast?$params',
        'Open-Meteo',
        locationName,
      );

      if (weatherData == null) {
        debugPrint('🔄 Пробуем через CORS proxy...');
        weatherData = await _fetchFromURL(
          'https://corsproxy.io/?https://api.open-meteo.com/v1/forecast?$params',
          'Open-Meteo (CORS)',
          locationName,
        );
      }

      if (weatherData == null) {
        debugPrint('🔄 Пробуем через allorigins...');
        weatherData = await _fetchFromURL(
          'https://api.allorigins.win/raw?url=https://api.open-meteo.com/v1/forecast?$params',
          'Open-Meteo (AllOrigins)',
          locationName,
        );
      }

      if (weatherData == null) {
        debugPrint('❌ Все источники погоды недоступны');
        return _fallbackWeatherData(locationName);
      }

      // ✅ Fallback: если API не вернул timezone (маловероятно), берём из региона
      if (_timezone == null && _regionProfile != null) {
        _timezone = _regionProfile!.timezone;
        debugPrint('🕐 Timezone из RegionProfile: $_timezone');
      }

      _lastData = weatherData;

      await prefs.setString(_kLastFetch, DateTime.now().toIso8601String());
      await prefs.setString(_kLastData, jsonEncode(weatherData.toJson()));
      if (_timezone != null) {
        await prefs.setString(_kTimezone, _timezone!);
      }

      await _updateIrrigationSettings(weatherData);

      debugPrint(
          '✅ Погода загружена из ${weatherData.source}: ${weatherData.currentTemp.toStringAsFixed(1)}°C');
      return weatherData;
    } catch (e, stack) {
      debugPrint('❌ Критическая ошибка загрузки прогноза: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  WeatherData _fallbackWeatherData(String locationName) {
    debugPrint('⚠️ Используем fallback данные на основе сезона');

    final now = DateTime.now();
    final month = now.month;

    double temp;
    if (month >= 12 || month <= 2) {
      temp = -10;
    } else if (month == 3 || month == 11) {
      temp = 2;
    } else if (month == 4 || month == 10) {
      temp = 10;
    } else if (month == 5 || month == 9) {
      temp = 18;
    } else {
      temp = 25;
    }

    final forecast = <DailyForecast>[];
    for (int i = 0; i < 7; i++) {
      forecast.add(DailyForecast(
        date: now.add(Duration(days: i)),
        tempMax: temp + 5,
        tempMin: temp - 5,
        weatherCode: 3,
        precipitation: 0,
        daysAhead: i,
      ));
    }

    return WeatherData(
      currentTemp: temp,
      soilTemp: temp - 3,
      currentHumidity: 60,
      windSpeed: 10,
      precipitation: null,
      weatherCode: 3,
      forecast: forecast,
      lastUpdated: now,
      locationName: locationName,
      source: 'Сезонные данные',
    );
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
    final savedTz = prefs.getString(_kTimezone);
    if (savedTz != null) _timezone = savedTz;

    if (lastDataStr != null) {
      try {
        _lastData = WeatherData.fromJson(
            jsonDecode(lastDataStr) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ Ошибка загрузки кэшированной погоды: $e');
      }
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastFetch);
    await prefs.remove(_kLastData);
    // timezone НЕ удаляем — он остаётся валидным
    _lastData = null;
  }
}
