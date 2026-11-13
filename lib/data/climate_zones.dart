import 'region_profile.dart';

/// Определение климатической зоны по координатам
/// Используется для коррекции календаря и рекомендаций
enum ClimateZone {
  arctic, // Арктическая
  subarctic, // Субарктическая (Мурманск, Норильск)
  temperate, // Умеренная (большая часть РФ, РБ, КЗ)
  continental, // Резко континентальная (Сибирь)
  subtropical, // Субтропическая (Сочи, Крым)
}

class ClimateZoneInfo {
  final ClimateZone zone;
  final String name;
  final String description;
  final int growingSeasonDays; // дней вегетационного периода
  final double minTemp; // минимальная зимняя температура
  final double maxTemp; // максимальная летняя температура

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
          description: 'Короткое лето, длинная зима. Открытый грунт ограничен.',
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
          description:
              'Классический умеренный климат. Подходят большинство культур.',
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
          description: 'Мягкая зима, длинный сезон. Теплолюбивые культуры.',
          growingSeasonDays: 220,
          minTemp: -5,
          maxTemp: 40,
        );
    }
  }
}

class ClimateZoneDetector {
  /// Определяет климатическую зону по координатам и профилю региона
  static ClimateZone detect({
    required double latitude,
    required double longitude,
    RegionProfile? profile,
  }) {
    // Арктика
    if (latitude > 66.5) {
      return ClimateZone.arctic;
    }

    // Субарктика (севернее 60°)
    if (latitude > 60) {
      return ClimateZone.subarctic;
    }

    // Субтропики (южнее 45° и определенные регионы)
    if (latitude < 45) {
      // Проверка на Черноморское побережье
      if (latitude > 43 && latitude < 45 && longitude > 37 && longitude < 41) {
        return ClimateZone.subtropical; // Сочи, Крым
      }
      // Средняя Азия (Узбекистан, Южный Казахстан)
      if (latitude < 44 && longitude > 65 && longitude < 77) {
        return ClimateZone.subtropical;
      }
    }

    // Резко континентальный климат (Сибирь, восток)
    if (longitude > 80 && latitude > 50 && latitude < 60) {
      return ClimateZone.continental;
    }

    // Умеренный климат (по умолчанию для большинства регионов)
    return ClimateZone.temperate;
  }

  /// Корректирует даты заморозков на основе климатической зоны
  static RegionProfile adjustProfile(
    RegionProfile baseProfile,
    ClimateZone zone,
  ) {
    int springOffset = 0;
    int autumnOffset = 0;

    switch (zone) {
      case ClimateZone.arctic:
        springOffset = 30; // +30 дней к весенним заморозкам
        autumnOffset = -30; // -30 дней к осенним
        break;
      case ClimateZone.subarctic:
        springOffset = 15;
        autumnOffset = -15;
        break;
      case ClimateZone.continental:
        springOffset = 10;
        autumnOffset = -10;
        break;
      case ClimateZone.subtropical:
        springOffset = -20; // раньше на 20 дней
        autumnOffset = 20; // позже на 20 дней
        break;
      case ClimateZone.temperate:
        // Без корректировки
        break;
    }

    return RegionProfile(
      id: '${baseProfile.id}_${zone.name}',
      name: baseProfile.name,
      country: baseProfile.country,
      lastSpringFrostMonth: baseProfile.lastSpringFrostMonth,
      lastSpringFrostDay: baseProfile.lastSpringFrostDay + springOffset,
      firstAutumnFrostMonth: baseProfile.firstAutumnFrostMonth,
      firstAutumnFrostDay: baseProfile.firstAutumnFrostDay + autumnOffset,
      timezone: baseProfile.timezone,
    );
  }
}
