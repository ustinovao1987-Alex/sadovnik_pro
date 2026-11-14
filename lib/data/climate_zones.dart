import 'region_profile.dart';

enum ClimateZone {
  arctic,
  subarctic,
  temperate,
  continental,
  subtropical,
}

class ClimateZoneInfo {
  final ClimateZone zone;
  final String name;
  final String description;
  final int growingSeasonDays;
  final double minTemp;
  final double maxTemp;

  const ClimateZoneInfo({
    required this.zone,
    required this.name,
    required this.description,
    required this.growingSeasonDays,
    required this.minTemp,
    required this.maxTemp,
  });

  static ClimateZoneInfo getDetails(ClimateZone zone) {
    switch (zone) {
      case ClimateZone.arctic:
        return const ClimateZoneInfo(
          zone: ClimateZone.arctic,
          name: 'Арктическая',
          description: 'Короткое лето. Открытый грунт ограничен.',
          growingSeasonDays: 60,
          minTemp: -40,
          maxTemp: 15,
        );
      case ClimateZone.subarctic:
        return const ClimateZoneInfo(
          zone: ClimateZone.subarctic,
          name: 'Субарктическая',
          description: 'Короткое прохладное лето. Теплицы обязательны.',
          growingSeasonDays: 90,
          minTemp: -35,
          maxTemp: 25,
        );
      case ClimateZone.temperate:
        return const ClimateZoneInfo(
          zone: ClimateZone.temperate,
          name: 'Умеренная',
          description: 'Классический умеренный климат.',
          growingSeasonDays: 130,
          minTemp: -25,
          maxTemp: 32,
        );
      case ClimateZone.continental:
        return const ClimateZoneInfo(
          zone: ClimateZone.continental,
          name: 'Резко континентальная',
          description: 'Холодная зима, жаркое лето. Короткий сезон.',
          growingSeasonDays: 110,
          minTemp: -45,
          maxTemp: 38,
        );
      case ClimateZone.subtropical:
        return const ClimateZoneInfo(
          zone: ClimateZone.subtropical,
          name: 'Субтропическая',
          description: 'Мягкая зима, длинный сезон.',
          growingSeasonDays: 220,
          minTemp: -5,
          maxTemp: 40,
        );
    }
  }
}

class ClimateZoneDetector {
  static ClimateZone detect({
    required double latitude,
    required double longitude,
    RegionProfile? profile,
  }) {
    if (latitude > 66.5) return ClimateZone.arctic;
    if (latitude > 60) return ClimateZone.subarctic;

    if (latitude < 45) {
      if (latitude > 43 && latitude < 45 && longitude > 37 && longitude < 41) {
        return ClimateZone.subtropical; // Сочи, Крым
      }
      if (latitude < 44 && longitude > 65 && longitude < 77) {
        return ClimateZone.subtropical; // Южный Казахстан, Узбекистан
      }
    }
    if (longitude > 80 && latitude > 50 && latitude < 60) {
      return ClimateZone.continental; // Сибирь
    }
    return ClimateZone.temperate;
  }

  /// ✅ ИСПРАВЛЕНО: смещения применяются через DateTime,
  /// поэтому «40 октября» автоматически превращается в «9 ноября».
  static RegionProfile adjustProfile(
    RegionProfile baseProfile,
    ClimateZone zone,
  ) {
    int springOffsetDays = 0;
    int autumnOffsetDays = 0;

    switch (zone) {
      case ClimateZone.arctic:
        springOffsetDays = 30;
        autumnOffsetDays = -30;
        break;
      case ClimateZone.subarctic:
        springOffsetDays = 15;
        autumnOffsetDays = -15;
        break;
      case ClimateZone.continental:
        springOffsetDays = 10;
        autumnOffsetDays = -10;
        break;
      case ClimateZone.subtropical:
        springOffsetDays = -20;
        autumnOffsetDays = 20;
        break;
      case ClimateZone.temperate:
        break;
    }

    // ✅ Нормализация через DateTime (год берём условный, важен только месяц/день)
    const int y = 2025;
    final springDate = DateTime(
            y, baseProfile.lastSpringFrostMonth, baseProfile.lastSpringFrostDay)
        .add(Duration(days: springOffsetDays));
    final autumnDate = DateTime(y, baseProfile.firstAutumnFrostMonth,
            baseProfile.firstAutumnFrostDay)
        .add(Duration(days: autumnOffsetDays));

    return RegionProfile(
      id: '${baseProfile.id}_${zone.name}',
      name: baseProfile.name,
      country: baseProfile.country,
      lastSpringFrostMonth: springDate.month,
      lastSpringFrostDay: springDate.day,
      firstAutumnFrostMonth: autumnDate.month,
      firstAutumnFrostDay: autumnDate.day,
      timezone: baseProfile.timezone,
      minLatitude: baseProfile.minLatitude,
      maxLatitude: baseProfile.maxLatitude,
      minLongitude: baseProfile.minLongitude,
      maxLongitude: baseProfile.maxLongitude,
    );
  }
}
