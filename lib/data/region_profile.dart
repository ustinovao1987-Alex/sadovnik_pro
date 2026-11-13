/// Климатические профили регионов для постсоветского пространства.
/// Содержит даты последних весенних и первых осенних заморозков.
class RegionProfile {
  final String id;
  final String name;
  final String country;
  final int lastSpringFrostMonth;
  final int lastSpringFrostDay;
  final int firstAutumnFrostMonth;
  final int firstAutumnFrostDay;
  final String timezone;
  final double? minLatitude;
  final double? maxLatitude;
  final double? minLongitude;
  final double? maxLongitude;

  const RegionProfile({
    required this.id,
    required this.name,
    required this.country,
    required this.lastSpringFrostMonth,
    required this.lastSpringFrostDay,
    required this.firstAutumnFrostMonth,
    required this.firstAutumnFrostDay,
    required this.timezone,
    this.minLatitude,
    this.maxLatitude,
    this.minLongitude,
    this.maxLongitude,
  });

  DateTime lastSpringFrost(int year) =>
      DateTime(year, lastSpringFrostMonth, lastSpringFrostDay);

  DateTime firstAutumnFrost(int year) =>
      DateTime(year, firstAutumnFrostMonth, firstAutumnFrostDay);

  String get frostPeriod =>
      '$lastSpringFrostDay.$lastSpringFrostMonth – $firstAutumnFrostDay.$firstAutumnFrostMonth';
}

/// Реестр климатических профилей
class RegionProfiles {
  static const List<RegionProfile> all = [
    // ================= РОССИЯ =================
    // Средняя полоса (Москва, Нижегородская, Владимирская обл.)
    RegionProfile(
      id: 'ru_center',
      name: 'Средняя полоса России',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Moscow',
      minLatitude: 54.0,
      maxLatitude: 58.0,
      minLongitude: 35.0,
      maxLongitude: 45.0,
    ),
    // Северо-Запад (Санкт-Петербург, Ленинградская обл.)
    RegionProfile(
      id: 'ru_northwest',
      name: 'Северо-Запад России',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 15,
      timezone: 'Europe/Moscow',
      minLatitude: 59.0,
      maxLatitude: 61.0,
      minLongitude: 28.0,
      maxLongitude: 33.0,
    ),
    // Юг России (Краснодар, Ростов, Ставрополь)
    RegionProfile(
      id: 'ru_south',
      name: 'Юг России',
      country: 'RU',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Moscow',
      minLatitude: 43.0,
      maxLatitude: 48.0,
      minLongitude: 37.0,
      maxLongitude: 44.0,
    ),
    // Урал (Свердловская, Челябинская обл.)
    RegionProfile(
      id: 'ru_ural',
      name: 'Урал',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 5,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Yekaterinburg',
      minLatitude: 55.0,
      maxLatitude: 58.0,
      minLongitude: 58.0,
      maxLongitude: 62.0,
    ),
    // Сибирь (Новосибирск, Омск)
    RegionProfile(
      id: 'ru_siberia',
      name: 'Западная Сибирь',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 5,
      timezone: 'Asia/Novosibirsk',
      minLatitude: 54.0,
      maxLatitude: 56.0,
      minLongitude: 73.0,
      maxLongitude: 84.0,
    ),
    // Поволжье (Самара, Казань, Волгоград)
    RegionProfile(
      id: 'ru_volga',
      name: 'Поволжье',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Samara',
      minLatitude: 52.0,
      maxLatitude: 54.0,
      minLongitude: 48.0,
      maxLongitude: 50.0,
    ),
    // Дальний Восток (Владивосток, Хабаровск)
    RegionProfile(
      id: 'ru_far_east',
      name: 'Дальний Восток',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Vladivostok',
      minLatitude: 43.0,
      maxLatitude: 49.0,
      minLongitude: 131.0,
      maxLongitude: 136.0,
    ),

    // ================= БЕЛАРУСЬ =================
    RegionProfile(
      id: 'by_center',
      name: 'Беларусь',
      country: 'BY',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Minsk',
      minLatitude: 52.0,
      maxLatitude: 56.0,
      minLongitude: 23.0,
      maxLongitude: 33.0,
    ),

    // ================= КАЗАХСТАН =================
    // Северный Казахстан
    RegionProfile(
      id: 'kz_north',
      name: 'Северный Казахстан',
      country: 'KZ',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 15,
      timezone: 'Asia/Almaty',
      minLatitude: 53.0,
      maxLatitude: 55.0,
      minLongitude: 68.0,
      maxLongitude: 77.0,
    ),
    // Южный Казахстан (Алматы, Шымкент)
    RegionProfile(
      id: 'kz_south',
      name: 'Южный Казахстан',
      country: 'KZ',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 20,
      timezone: 'Asia/Almaty',
      minLatitude: 42.0,
      maxLatitude: 44.0,
      minLongitude: 76.0,
      maxLongitude: 77.0,
    ),

    // ================= УЗБЕКИСТАН =================
    RegionProfile(
      id: 'uz_center',
      name: 'Узбекистан',
      country: 'UZ',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Tashkent',
      minLatitude: 40.0,
      maxLatitude: 42.0,
      minLongitude: 69.0,
      maxLongitude: 72.0,
    ),

    // ================= КИРГИЗИЯ =================
    RegionProfile(
      id: 'kg_center',
      name: 'Киргизия',
      country: 'KG',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 15,
      timezone: 'Asia/Bishkek',
      minLatitude: 42.0,
      maxLatitude: 43.5,
      minLongitude: 74.0,
      maxLongitude: 75.5,
    ),
  ];

  /// Находит профиль по координатам
  static RegionProfile? findByCoordinates(double lat, double lon) {
    for (final profile in all) {
      if (profile.minLatitude != null &&
          profile.maxLatitude != null &&
          profile.minLongitude != null &&
          profile.maxLongitude != null) {
        if (lat >= profile.minLatitude! &&
            lat <= profile.maxLatitude! &&
            lon >= profile.minLongitude! &&
            lon <= profile.maxLongitude!) {
          return profile;
        }
      }
    }
    return null;
  }

  /// Находит профиль по ID
  static RegionProfile? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Получает профиль по умолчанию (Средняя полоса России)
  static RegionProfile get defaultProfile => all.firstWhere(
        (p) => p.id == 'ru_center',
        orElse: () => all.first,
      );
}
