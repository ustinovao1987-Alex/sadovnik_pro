import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'region_profile.dart';

/// Модель одного населённого пункта.
class City {
  final String name;
  final String region;
  final String district;
  final double lat;
  final double lon;
  final int utcOffset;
  final String? timezone;
  final RegionProfile? profile;

  const City({
    required this.name,
    required this.region,
    required this.district,
    required this.lat,
    required this.lon,
    required this.utcOffset,
    this.timezone,
    this.profile,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      region: (json['region'] as String?) ?? '',
      district: (json['district'] as String?) ?? '',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      utcOffset: (json['utcOffset'] as num?)?.toInt() ?? 4,
      timezone: json['timezone'] as String?,
    );
  }

  City copyWith({
    String? name,
    String? region,
    String? district,
    double? lat,
    double? lon,
    int? utcOffset,
    String? timezone,
    RegionProfile? profile,
  }) {
    return City(
      name: name ?? this.name,
      region: region ?? this.region,
      district: district ?? this.district,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      utcOffset: utcOffset ?? this.utcOffset,
      timezone: timezone ?? this.timezone,
      profile: profile ?? this.profile,
    );
  }

  @override
  String toString() => 'City($name, lat=$lat, lon=$lon, tz=$timezone)';
}

class CityRepository {
  static final CityRepository instance = CityRepository._();
  CityRepository._();

  List<City> _cities = const [];
  bool _loaded = false;
  Future<List<City>>? _loading;

  Future<List<City>> loadCities() {
    if (_loaded) return Future.value(_cities);
    if (_loading != null) return _loading!;
    _loading = _performLoad();
    return _loading!;
  }

  Future<List<City>> _performLoad() async {
    try {
      final raw = await rootBundle.loadString('assets/data/cities.json');
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException('Ожидался список городов в JSON');
      }

      final parsed = decoded
          .map((item) => City.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      parsed
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _cities = List.unmodifiable(parsed);
    } catch (e, st) {
      debugPrint('❌ Ошибка загрузки cities.json: $e');
      debugPrintStack(stackTrace: st);

      _cities = List.unmodifiable([
        const City(
          name: 'Самара',
          region: 'Самарская область',
          district: 'городской округ',
          lat: 53.1959,
          lon: 50.1008,
          utcOffset: 4,
          timezone: 'Europe/Samara',
        ),
      ]);
    }

    _loaded = true;
    _loading = null;
    return _cities;
  }

  City? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final city in _cities) {
      if (city.name.toLowerCase() == name.toLowerCase()) return city;
    }
    return null;
  }

  City get defaultCity {
    if (_cities.isNotEmpty) {
      return _cities.firstWhere(
        (c) => c.name == 'Самара',
        orElse: () => _cities.first,
      );
    }
    return const City(
      name: 'Самара',
      region: 'Самарская область',
      district: 'городской округ',
      lat: 53.1959,
      lon: 50.1008,
      utcOffset: 4,
      timezone: 'Europe/Samara',
    );
  }
}
