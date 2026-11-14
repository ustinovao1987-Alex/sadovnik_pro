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

class RegionProfiles {
  static const List<RegionProfile> all = [
    // ================= РОССИЯ =================
    RegionProfile(
      id: 'ru_kaliningrad',
      name: 'Калининградская область',
      country: 'RU',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 15,
      timezone: 'Europe/Kaliningrad',
      minLatitude: 54.0,
      maxLatitude: 55.5,
      minLongitude: 19.0,
      maxLongitude: 23.0,
    ),
    RegionProfile(
      id: 'ru_northwest',
      name: 'Северо-Запад России',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 15,
      timezone: 'Europe/Moscow',
      minLatitude: 58.0,
      maxLatitude: 62.0,
      minLongitude: 27.0,
      maxLongitude: 35.0,
    ),
    RegionProfile(
      id: 'ru_center',
      name: 'Средняя полоса России',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Moscow',
      minLatitude: 53.5,
      maxLatitude: 58.0,
      minLongitude: 33.0,
      maxLongitude: 48.0,
    ),
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
      maxLatitude: 50.5,
      minLongitude: 37.0,
      maxLongitude: 48.0,
    ),
    RegionProfile(
      id: 'ru_caucasus',
      name: 'Северный Кавказ',
      country: 'RU',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 20,
      timezone: 'Europe/Moscow',
      minLatitude: 42.5,
      maxLatitude: 44.5,
      minLongitude: 43.0,
      maxLongitude: 48.5,
    ),
    RegionProfile(
      id: 'ru_volga',
      name: 'Поволжье',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 25,
      timezone: 'Europe/Samara',
      minLatitude: 51.5,
      maxLatitude: 55.5,
      minLongitude: 46.0,
      maxLongitude: 53.5,
    ),
    RegionProfile(
      id: 'ru_ural',
      name: 'Урал',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 5,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Yekaterinburg',
      minLatitude: 52.0,
      maxLatitude: 60.0,
      minLongitude: 56.0,
      maxLongitude: 66.0,
    ),
    RegionProfile(
      id: 'ru_siberia',
      name: 'Западная Сибирь',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 5,
      timezone: 'Asia/Novosibirsk',
      minLatitude: 52.0,
      maxLatitude: 58.0,
      minLongitude: 66.0,
      maxLongitude: 88.0,
    ),
    RegionProfile(
      id: 'ru_yakutia',
      name: 'Якутия / Восточная Сибирь',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 8,
      firstAutumnFrostDay: 25,
      timezone: 'Asia/Yakutsk',
      minLatitude: 58.0,
      maxLatitude: 68.0,
      minLongitude: 105.0,
      maxLongitude: 145.0,
    ),
    RegionProfile(
      id: 'ru_norilsk',
      name: 'Таймыр / Норильск',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 8,
      firstAutumnFrostDay: 20,
      timezone: 'Asia/Krasnoyarsk',
      minLatitude: 68.0,
      maxLatitude: 75.0,
      minLongitude: 80.0,
      maxLongitude: 110.0,
    ),
    RegionProfile(
      id: 'ru_murmansk',
      name: 'Мурманская область',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 5,
      timezone: 'Europe/Moscow',
      minLatitude: 66.0,
      maxLatitude: 70.5,
      minLongitude: 28.0,
      maxLongitude: 42.0,
    ),
    RegionProfile(
      id: 'ru_far_east',
      name: 'Дальний Восток',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Vladivostok',
      minLatitude: 42.0,
      maxLatitude: 50.0,
      minLongitude: 130.0,
      maxLongitude: 141.0,
    ),
    RegionProfile(
      id: 'ru_sakhalin',
      name: 'Сахалин',
      country: 'RU',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Sakhalin',
      minLatitude: 45.0,
      maxLatitude: 55.0,
      minLongitude: 141.0,
      maxLongitude: 145.0,
    ),
    RegionProfile(
      id: 'ru_magadan',
      name: 'Магаданская область',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Magadan',
      minLatitude: 58.0,
      maxLatitude: 63.0,
      minLongitude: 145.0,
      maxLongitude: 162.0,
    ),
    RegionProfile(
      id: 'ru_kamchatka',
      name: 'Камчатка',
      country: 'RU',
      lastSpringFrostMonth: 6,
      lastSpringFrostDay: 5,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 1,
      timezone: 'Asia/Kamchatka',
      minLatitude: 50.0,
      maxLatitude: 62.0,
      minLongitude: 155.0,
      maxLongitude: 170.0,
    ),

    // ================= БЕЛАРУСЬ =================
    RegionProfile(
      id: 'by_center',
      name: 'Беларусь',
      country: 'BY',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 5,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 5,
      timezone: 'Europe/Minsk',
      minLatitude: 51.0,
      maxLatitude: 56.5,
      minLongitude: 23.0,
      maxLongitude: 33.0,
    ),

    // ================= МОЛДОВА =================
    RegionProfile(
      id: 'md_center',
      name: 'Молдова',
      country: 'MD',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 15,
      timezone: 'Europe/Chisinau',
      minLatitude: 45.0,
      maxLatitude: 48.5,
      minLongitude: 26.0,
      maxLongitude: 30.5,
    ),

    // ================= КАЗАХСТАН =================
    RegionProfile(
      id: 'kz_north',
      name: 'Северный Казахстан',
      country: 'KZ',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 9,
      firstAutumnFrostDay: 15,
      timezone: 'Asia/Almaty',
      minLatitude: 51.0,
      maxLatitude: 55.5,
      minLongitude: 60.0,
      maxLongitude: 78.0,
    ),
    RegionProfile(
      id: 'kz_south',
      name: 'Южный Казахстан',
      country: 'KZ',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 15,
      timezone: 'Asia/Almaty',
      minLatitude: 42.0,
      maxLatitude: 46.0,
      minLongitude: 68.0,
      maxLongitude: 82.0,
    ),
    RegionProfile(
      id: 'kz_west',
      name: 'Западный Казахстан',
      country: 'KZ',
      lastSpringFrostMonth: 5,
      lastSpringFrostDay: 2,
      firstAutumnFrostMonth: 10,
      firstAutumnFrostDay: 3,
      timezone: 'Asia/Aqtobe',
      minLatitude: 46.0,
      maxLatitude: 51.0,
      minLongitude: 49.0,
      maxLongitude: 60.0,
    ),

    // ================= УЗБЕКИСТАН =================
    RegionProfile(
      id: 'uz_tashkent',
      name: 'Узбекистан (Ташкент)',
      country: 'UZ',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 25,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Tashkent',
      minLatitude: 40.0,
      maxLatitude: 42.5,
      minLongitude: 68.0,
      maxLongitude: 72.0,
    ),
    RegionProfile(
      id: 'uz_samarkand',
      name: 'Узбекистан (Самарканд)',
      country: 'UZ',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Samarkand',
      minLatitude: 37.5,
      maxLatitude: 40.0,
      minLongitude: 62.0,
      maxLongitude: 68.5,
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
      minLatitude: 40.0,
      maxLatitude: 43.5,
      minLongitude: 71.0,
      maxLongitude: 76.0,
    ),

    // ================= ТАДЖИКИСТАН =================
    RegionProfile(
      id: 'tj_center',
      name: 'Таджикистан',
      country: 'TJ',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 5,
      timezone: 'Asia/Dushanbe',
      minLatitude: 36.5,
      maxLatitude: 39.5,
      minLongitude: 67.0,
      maxLongitude: 71.0,
    ),

    // ================= ТУРКМЕНИСТАН =================
    RegionProfile(
      id: 'tm_center',
      name: 'Туркменистан',
      country: 'TM',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 15,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Ashgabat',
      minLatitude: 36.0,
      maxLatitude: 39.5,
      minLongitude: 55.0,
      maxLongitude: 60.5,
    ),

    // ================= ЗАКАВКАЗЬЕ =================
    RegionProfile(
      id: 'ge_tbilisi',
      name: 'Грузия',
      country: 'GE',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 20,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 10,
      timezone: 'Asia/Tbilisi',
      minLatitude: 41.0,
      maxLatitude: 43.0,
      minLongitude: 41.0,
      maxLongitude: 46.5,
    ),
    RegionProfile(
      id: 'am_yerevan',
      name: 'Армения',
      country: 'AM',
      lastSpringFrostMonth: 4,
      lastSpringFrostDay: 5,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 5,
      timezone: 'Asia/Yerevan',
      minLatitude: 39.0,
      maxLatitude: 41.5,
      minLongitude: 43.5,
      maxLongitude: 46.5,
    ),
    RegionProfile(
      id: 'az_baku',
      name: 'Азербайджан',
      country: 'AZ',
      lastSpringFrostMonth: 3,
      lastSpringFrostDay: 10,
      firstAutumnFrostMonth: 11,
      firstAutumnFrostDay: 20,
      timezone: 'Asia/Baku',
      minLatitude: 38.0,
      maxLatitude: 42.0,
      minLongitude: 45.0,
      maxLongitude: 50.5,
    ),
  ];

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

  static RegionProfile? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static RegionProfile get defaultProfile => all.firstWhere(
        (p) => p.id == 'ru_center',
        orElse: () => all.first,
      );
}
