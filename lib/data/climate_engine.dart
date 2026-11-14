import 'dart:math' as math;
import 'region_profile.dart';
import 'irrigation.dart'; // ✅ ИМПОРТ ДОБАВЛЕН — отсюда берётся IrrigationSettings

class ClimateEngine {
  ClimateEngine._();

  /// Главный метод: по координатам возвращает финальный климатический профиль.
  /// Логика (от точного к общему):
  ///   1. Точный регион по координатам.
  ///   2. Ближайший регион, если он не дальше 15° (иначе климат будет чужим).
  ///   3. Широтный fallback — обоснованные нормы по широте.
  static RegionProfile resolve(double latitude, double longitude) {
    final exact = RegionProfiles.findByCoordinates(latitude, longitude);
    if (exact != null) return exact;

    final nearest = _findNearestWithDistance(latitude, longitude);
    if (nearest != null && nearest.$2 < 15.0) {
      return nearest.$1;
    }

    return _latitudeFallback(latitude, longitude);
  }

  static (RegionProfile, double)? _findNearestWithDistance(
      double lat, double lon) {
    RegionProfile? best;
    double bestDist = double.infinity;

    for (final p in RegionProfiles.all) {
      if (p.minLatitude == null || p.maxLatitude == null) continue;
      final cLat = (p.minLatitude! + p.maxLatitude!) / 2;
      final cLon = (p.minLongitude! + p.maxLongitude!) / 2;
      final dLat = lat - cLat;
      final dLon = (lon - cLon) * math.cos(cLat * math.pi / 180);
      final d = math.sqrt(dLat * dLat + dLon * dLon);
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    if (best == null) return null;
    return (best, bestDist);
  }

  /// Широтный fallback — средние климатические нормы по широте.
  static RegionProfile _latitudeFallback(double lat, double lon) {
    if (lat > 70) {
      return _virtual('arctic', 'Арктика', 'RU', 6, 25, 8, 20, 'UTC', lat, lon);
    }
    if (lat > 66.5) {
      return _virtual(
          'subarctic', 'Субарктика', 'RU', 6, 10, 9, 5, 'UTC', lat, lon);
    }
    if (lat > 62) {
      return _virtual('north', 'Север', 'RU', 6, 5, 9, 10, 'UTC', lat, lon);
    }
    if (lat > 58) {
      return _virtual('temperate_n', 'Умеренный север', 'RU', 5, 20, 9, 20,
          'UTC', lat, lon);
    }
    if (lat > 54) {
      return _virtual(
          'temperate', 'Умеренный', 'RU', 5, 15, 9, 25, 'UTC', lat, lon);
    }
    if (lat > 50) {
      return _virtual(
          'temperate_s', 'Умеренный юг', 'RU', 5, 5, 10, 5, 'UTC', lat, lon);
    }
    if (lat > 46) {
      return _virtual(
          'warm', 'Умеренно-тёплый', 'RU', 4, 25, 10, 15, 'UTC', lat, lon);
    }
    if (lat > 42) {
      return _virtual('subtropical_n', 'Субтропики север', 'RU', 4, 10, 10, 25,
          'UTC', lat, lon);
    }
    if (lat > 38) {
      return _virtual(
          'subtropical', 'Субтропики', 'RU', 3, 25, 11, 5, 'UTC', lat, lon);
    }
    return _virtual('south', 'Юг', 'RU', 3, 15, 11, 15, 'UTC', lat, lon);
  }

  static RegionProfile _virtual(
    String id,
    String name,
    String country,
    int lsM,
    int lsD,
    int faM,
    int faD,
    String tz,
    double lat,
    double lon,
  ) {
    return RegionProfile(
      id: 'virtual_$id',
      name: name,
      country: country,
      lastSpringFrostMonth: lsM,
      lastSpringFrostDay: lsD,
      firstAutumnFrostMonth: faM,
      firstAutumnFrostDay: faD,
      timezone: tz,
      minLatitude: lat - 0.5,
      maxLatitude: lat + 0.5,
      minLongitude: lon - 0.5,
      maxLongitude: lon + 0.5,
    );
  }

  static const List<String> _monthsGen = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String currentRegionName() {
    return resolve(
      IrrigationSettings.instance.latitude,
      IrrigationSettings.instance.longitude,
    ).name;
  }

  static String currentFrostPeriodText() {
    final p = resolve(
      IrrigationSettings.instance.latitude,
      IrrigationSettings.instance.longitude,
    );
    final lastSpring =
        '${p.lastSpringFrostDay} ${_monthsGen[p.lastSpringFrostMonth - 1]}';
    final firstAutumn =
        '${p.firstAutumnFrostDay} ${_monthsGen[p.firstAutumnFrostMonth - 1]}';
    return 'последние весенние ~$lastSpring, первые осенние ~$firstAutumn';
  }
}
