import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoilType { sand, loam, clay }

enum GrowthStage { initial, development, mid, late }

enum WeatherPreset { cool, mild, warm, hot, heatwave }

class WeatherInfo {
  final String label;
  final double tMax;
  final double tMin;
  const WeatherInfo(this.label, this.tMax, this.tMin);
}

const Map<WeatherPreset, WeatherInfo> kWeatherPresets = {
  WeatherPreset.cool: WeatherInfo('Прохладно +16/+8', 16, 8),
  WeatherPreset.mild: WeatherInfo('Умеренно +22/+12', 22, 12),
  WeatherPreset.warm: WeatherInfo('Тепло +27/+16', 27, 16),
  WeatherPreset.hot: WeatherInfo('Жара +32/+19', 32, 19),
  WeatherPreset.heatwave: WeatherInfo('Зной +36/+22', 36, 22),
};

class SoilProps {
  final String title;
  final String short;
  final double availableWater;
  final double maxDoseMm;
  const SoilProps(this.title, this.short, this.availableWater, this.maxDoseMm);
}

const Map<SoilType, SoilProps> kSoils = {
  SoilType.sand: SoilProps('Песчаная / супесь', 'Песок', 0.10, 18),
  SoilType.loam: SoilProps('Суглинок / чернозём', 'Суглинок', 0.18, 28),
  SoilType.clay: SoilProps('Тяжёлый суглинок / глина', 'Глина', 0.20, 22),
};

class WaterProfile {
  final String cropId;
  final double kcInit;
  final double kcMid;
  final double kcEnd;
  final double rootDepth;
  final double depletion;
  final bool droughtTolerant;

  const WaterProfile(
    this.cropId,
    this.kcInit,
    this.kcMid,
    this.kcEnd,
    this.rootDepth,
    this.depletion, {
    this.droughtTolerant = false,
  });
}

class IrrigationPlan {
  final double et0;
  final double etc;
  final double weeklyMm;
  final double doseMm;
  final double litersPerPlant;
  final int intervalDays;
  final double rawMm;
  final double tawMm;
  final double kc;
  final bool rainCoversNeed;
  final String summary;
  final String reasoning;

  const IrrigationPlan({
    required this.et0,
    required this.etc,
    required this.weeklyMm,
    required this.doseMm,
    required this.litersPerPlant,
    required this.intervalDays,
    required this.rawMm,
    required this.tawMm,
    required this.kc,
    required this.rainCoversNeed,
    required this.summary,
    required this.reasoning,
  });

  String get doseText => rainCoversNeed
      ? 'Полив не нужен'
      : '${litersPerPlant.toStringAsFixed(1)} л под растение';

  String get perAreaText => '${doseMm.toStringAsFixed(0)} л/м²';

  String get intervalText => rainCoversNeed
      ? 'достаточно дождя'
      : 'каждые $intervalDays ${_daysWord(intervalDays)}';

  static String _daysWord(int n) {
    final a = n % 10, b = n % 100;
    if (a == 1 && b != 11) return 'день';
    if (a >= 2 && a <= 4 && (b < 12 || b > 14)) return 'дня';
    return 'дней';
  }
}

class IrrigationAdvisor {
  static double extraterrestrialRadiation(double latDeg, int dayOfYear) {
    final lat = latDeg * math.pi / 180.0;
    final dr = 1 + 0.033 * math.cos(2 * math.pi * dayOfYear / 365.0);
    final decl = 0.409 * math.sin(2 * math.pi * dayOfYear / 365.0 - 1.39);
    final x = (-math.tan(lat) * math.tan(decl)).clamp(-1.0, 1.0);
    final ws = math.acos(x);
    return (24 * 60 / math.pi) *
        0.0820 *
        dr *
        (ws * math.sin(lat) * math.sin(decl) +
            math.cos(lat) * math.cos(decl) * math.sin(ws));
  }

  static double et0Hargreaves({
    required double latDeg,
    required int dayOfYear,
    required double tMax,
    required double tMin,
  }) {
    final tMean = (tMax + tMin) / 2;
    final dt = math.max(tMax - tMin, 0.5);
    final ra = extraterrestrialRadiation(latDeg, dayOfYear);
    final v = 0.0023 * ra * (tMean + 17.8) * math.sqrt(dt) * 0.408;
    return v.clamp(0.2, 12.0);
  }

  static double kcAt(WaterProfile p, GrowthStage s) {
    switch (s) {
      case GrowthStage.initial:
        return p.kcInit;
      case GrowthStage.development:
        return (p.kcInit + p.kcMid) / 2;
      case GrowthStage.mid:
        return p.kcMid;
      case GrowthStage.late:
        return p.kcEnd;
    }
  }

  static GrowthStage stageFromProgress(double progress) {
    if (progress < 0.15) return GrowthStage.initial;
    if (progress < 0.45) return GrowthStage.development;
    if (progress < 0.80) return GrowthStage.mid;
    return GrowthStage.late;
  }

  static String stageTitle(GrowthStage s) {
    switch (s) {
      case GrowthStage.initial:
        return 'начало роста';
      case GrowthStage.development:
        return 'наращивание';
      case GrowthStage.mid:
        return 'пик сезона';
      case GrowthStage.late:
        return 'конец сезона';
    }
  }

  static double wettedFraction(double plantAreaM2) {
    if (plantAreaM2 <= 0.04) return 1.0;
    if (plantAreaM2 <= 0.12) return 0.85;
    if (plantAreaM2 <= 0.30) return 0.65;
    if (plantAreaM2 <= 0.70) return 0.50;
    return 0.40;
  }

  static IrrigationPlan compute({
    required WaterProfile profile,
    required double latDeg,
    required DateTime date,
    required double tMax,
    required double tMin,
    required double plantAreaM2,
    SoilType soil = SoilType.loam,
    bool mulched = false,
    GrowthStage stage = GrowthStage.mid,
    double rainMm = 0,
  }) {
    final doy = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final et0 =
        et0Hargreaves(latDeg: latDeg, dayOfYear: doy, tMax: tMax, tMin: tMin);

    final kc = kcAt(profile, stage);
    final mulchFactor = mulched ? 0.80 : 1.0;
    final dryFactor = profile.droughtTolerant ? 0.70 : 1.0;
    final etc = et0 * kc * mulchFactor * dryFactor;

    final props = kSoils[soil]!;
    final taw = 1000 * profile.rootDepth * props.availableWater;
    final raw = taw * profile.depletion;

    final effectiveRain = math.min(rainMm, 15.0) * 0.8;
    final netDaily = math.max(etc - effectiveRain / 3.0, 0.15);

    final interval = (raw / netDaily).round().clamp(1, 14);
    final rainCovers = effectiveRain >= etc * 2;
    final dose = rainCovers ? 0.0 : math.min(raw, props.maxDoseMm);

    final wet = wettedFraction(plantAreaM2);
    final liters = dose * plantAreaM2 * wet;

    final summary = rainCovers
        ? 'Дождя достаточно — полив не нужен'
        : '${liters.toStringAsFixed(1)} л под растение (≈ ${dose.toStringAsFixed(0)} л/м²) каждые $interval ${IrrigationPlan._daysWord(interval)}';

    final reasoning = 'Испаряемость ET₀ = ${et0.toStringAsFixed(2)} мм/сут '
        '(широта ${latDeg.toStringAsFixed(1)}°, день года $doy, ${tMax.toStringAsFixed(0)}/${tMin.toStringAsFixed(0)} °C). '
        'Фаза «${stageTitle(stage)}»: Kc = ${kc.toStringAsFixed(2)} → потребность ${etc.toStringAsFixed(2)} мм/сут (${(etc * 7).toStringAsFixed(0)} мм/нед). '
        'Корневой слой ${profile.rootDepth.toStringAsFixed(2)} м, ${props.title.toLowerCase()}: доступной влаги ${taw.toStringAsFixed(0)} мм, без стресса можно израсходовать ${raw.toStringAsFixed(0)} мм → интервал ${raw.toStringAsFixed(0)} / ${netDaily.toStringAsFixed(2)} ≈ $interval дн. '
        'Доза ограничена впитыванием почвы (${props.maxDoseMm.toStringAsFixed(0)} мм). Увлажняется ${(wet * 100).toStringAsFixed(0)}% площади питания ${plantAreaM2.toStringAsFixed(2)} м². '
        '${mulched ? 'Мульча снижает испарение на 20%. ' : ''}'
        '${profile.droughtTolerant ? 'Культура засухоустойчива: −30%. ' : ''}'
        '${rainMm > 0 ? 'Учтён дождь ${rainMm.toStringAsFixed(0)} мм. ' : ''}'
        '⚠️ Это расчётная оценка по методике FAO-56 и ВНИИО. Проверка руками: комок земли на глубине 5–10 см распадается — пора поливать.';

    return IrrigationPlan(
      et0: et0,
      etc: etc,
      weeklyMm: etc * 7,
      doseMm: dose,
      litersPerPlant: liters,
      intervalDays: interval,
      rawMm: raw,
      tawMm: taw,
      kc: kc,
      rainCoversNeed: rainCovers,
      summary: summary,
      reasoning: reasoning,
    );
  }

  static IrrigationPlan planFor({
    required String cropId,
    required double plantAreaM2,
    GrowthStage stage = GrowthStage.mid,
    DateTime? date,
  }) {
    final s = IrrigationSettings.instance;
    final profile = WaterProfiles.byId(cropId) ?? WaterProfiles.fallback;
    return compute(
      profile: profile,
      latDeg: s.latitude,
      date: date ?? DateTime.now(),
      tMax: s.tMax,
      tMin: s.tMin,
      plantAreaM2: plantAreaM2 <= 0 ? 0.25 : plantAreaM2,
      soil: s.soil,
      mulched: s.mulched,
      stage: stage,
      rainMm: s.rainMm,
    );
  }
}

class IrrigationSettings extends ChangeNotifier {
  IrrigationSettings._();
  static final IrrigationSettings instance = IrrigationSettings._();

  static const _kSoil = 'irr_soil_v1';
  static const _kMulch = 'irr_mulch_v1';
  static const _kWeather = 'irr_weather_v1';
  static const _kRainDay = 'irr_rain_day_v1';

  double latitude = 53.2;
  double longitude = 50.6;
  SoilType soil = SoilType.loam;
  bool mulched = false;
  WeatherPreset weather = WeatherPreset.warm;
  bool _rainToday = false;
  bool ready = false;
  SharedPreferences? _prefs;

  double get tMax => kWeatherPresets[weather]!.tMax;
  double get tMin => kWeatherPresets[weather]!.tMin;
  double get rainMm => _rainToday ? 12.0 : 0.0;
  bool get rainToday => _rainToday;

  static WeatherPreset defaultForMonth(int month) {
    switch (month) {
      case 4:
      case 10:
        return WeatherPreset.cool;
      case 5:
      case 9:
        return WeatherPreset.mild;
      case 6:
      case 8:
        return WeatherPreset.warm;
      case 7:
        return WeatherPreset.hot;
      default:
        return WeatherPreset.mild;
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    latitude = _prefs!.getDouble('loc_lat') ?? 53.2;
    longitude = _prefs!.getDouble('loc_lon') ?? 50.6;
    soil = SoilType.values[(_prefs!.getInt(_kSoil) ?? 1).clamp(0, 2)];
    mulched = _prefs!.getBool(_kMulch) ?? false;
    final w = _prefs!.getInt(_kWeather);
    weather = w == null
        ? defaultForMonth(DateTime.now().month)
        : WeatherPreset.values[w.clamp(0, 4)];
    _rainToday = _prefs!.getString(_kRainDay) == _todayKey();
    ready = true;
    notifyListeners();
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> syncLatitude() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final lat = p.getDouble('loc_lat');
    final lon = p.getDouble('loc_lon');
    if (lat != null && (lat - latitude).abs() > 0.001) {
      latitude = lat;
      notifyListeners();
    }
    if (lon != null && (lon - longitude).abs() > 0.001) {
      longitude = lon;
    }
  }

  Future<void> setSoil(SoilType v) async {
    soil = v;
    notifyListeners();
    await _prefs?.setInt(_kSoil, v.index);
  }

  Future<void> setMulched(bool v) async {
    mulched = v;
    notifyListeners();
    await _prefs?.setBool(_kMulch, v);
  }

  Future<void> setWeather(WeatherPreset v) async {
    weather = v;
    notifyListeners();
    await _prefs?.setInt(_kWeather, v.index);
  }

  Future<void> setRainToday(bool v) async {
    _rainToday = v;
    notifyListeners();
    if (v) {
      await _prefs?.setString(_kRainDay, _todayKey());
    } else {
      await _prefs?.remove(_kRainDay);
    }
  }
}

class WaterProfiles {
  static WaterProfile? byId(String id) => _map[id];
  static const WaterProfile fallback =
      WaterProfile('generic', 0.60, 1.00, 0.90, 0.40, 0.35);

  static final Map<String, WaterProfile> _map = {
    for (final p in _list) p.cropId: p,
  };

  static const List<WaterProfile> _list = [
    WaterProfile('tomato', 0.60, 1.15, 0.80, 0.50, 0.40),
    WaterProfile('pepper', 0.60, 1.05, 0.90, 0.35, 0.30),
    WaterProfile('hotpepper', 0.60, 1.05, 0.90, 0.35, 0.30),
    WaterProfile('eggplant', 0.60, 1.05, 0.90, 0.45, 0.40),
    WaterProfile('potato', 0.50, 1.15, 0.75, 0.45, 0.35),
    WaterProfile('physalis', 0.60, 1.05, 0.85, 0.45, 0.40),
    WaterProfile('cucumber', 0.60, 1.05, 0.75, 0.35, 0.35),
    WaterProfile('zucchini', 0.50, 0.95, 0.75, 0.45, 0.35),
    WaterProfile('patisson', 0.50, 0.95, 0.75, 0.45, 0.35),
    WaterProfile('pumpkin', 0.50, 1.00, 0.80, 0.70, 0.35,
        droughtTolerant: true),
    WaterProfile('melon', 0.50, 1.05, 0.75, 0.60, 0.40),
    WaterProfile('watermelon', 0.50, 1.00, 0.75, 0.80, 0.40,
        droughtTolerant: true),
    WaterProfile('cabbage', 0.70, 1.15, 0.95, 0.35, 0.45),
    WaterProfile('cauliflower', 0.70, 1.15, 0.95, 0.35, 0.45),
    WaterProfile('broccoli', 0.70, 1.10, 0.95, 0.35, 0.45),
    WaterProfile('peking', 0.70, 1.05, 0.95, 0.30, 0.40),
    WaterProfile('kohlrabi', 0.70, 1.05, 0.95, 0.30, 0.40),
    WaterProfile('radish', 0.70, 0.90, 0.85, 0.20, 0.30),
    WaterProfile('daikon', 0.70, 1.05, 0.95, 0.40, 0.40),
    WaterProfile('onion', 0.70, 1.05, 0.70, 0.30, 0.30),
    WaterProfile('garlic', 0.70, 1.00, 0.70, 0.30, 0.30),
    WaterProfile('leek', 0.70, 1.05, 0.95, 0.35, 0.30),
    WaterProfile('batun', 0.70, 1.00, 0.95, 0.30, 0.35),
    WaterProfile('chives', 0.70, 1.00, 0.95, 0.25, 0.35),
    WaterProfile('pea', 0.50, 1.15, 1.10, 0.45, 0.50),
    WaterProfile('bean', 0.50, 1.05, 0.90, 0.40, 0.45),
    WaterProfile('broadbean', 0.50, 1.15, 1.10, 0.50, 0.50),
    WaterProfile('lettuce', 0.70, 1.00, 0.95, 0.25, 0.30),
    WaterProfile('headlettuce', 0.70, 1.00, 0.95, 0.25, 0.30),
    WaterProfile('endive', 0.70, 1.00, 0.95, 0.30, 0.30),
    WaterProfile('jerusalem', 0.50, 1.00, 0.85, 0.80, 0.45,
        droughtTolerant: true),
    WaterProfile('beet', 0.50, 1.05, 0.95, 0.45, 0.40),
    WaterProfile('spinach', 0.70, 1.00, 0.95, 0.25, 0.20),
    WaterProfile('chard', 0.50, 1.05, 0.95, 0.35, 0.35),
    WaterProfile('corn', 0.40, 1.15, 1.00, 0.90, 0.50),
    WaterProfile('sorrel', 0.70, 1.00, 0.95, 0.35, 0.35),
    WaterProfile('rhubarb', 0.60, 0.90, 0.85, 0.60, 0.40),
    WaterProfile('basil', 0.60, 1.00, 0.95, 0.30, 0.30),
    WaterProfile('mint', 0.70, 1.00, 0.95, 0.35, 0.35),
    WaterProfile('lemonbalm', 0.70, 1.00, 0.95, 0.35, 0.35),
    WaterProfile('thyme', 0.50, 0.60, 0.55, 0.35, 0.50, droughtTolerant: true),
    WaterProfile('strawberry', 0.40, 0.85, 0.75, 0.30, 0.20),
    WaterProfile('greens', 0.70, 1.00, 0.95, 0.25, 0.30),
    WaterProfile('brusselsprouts', 0.70, 1.10, 0.95, 0.35, 0.45),
    WaterProfile('arugula', 0.70, 1.00, 0.95, 0.25, 0.30),
    WaterProfile('kale', 0.70, 1.10, 0.95, 0.35, 0.45),
    WaterProfile('horseradish', 0.60, 1.00, 0.90, 0.50, 0.45,
        droughtTolerant: true),
    WaterProfile('tarragon', 0.60, 0.90, 0.85, 0.35, 0.50,
        droughtTolerant: true),
    WaterProfile('oregano', 0.60, 0.90, 0.85, 0.35, 0.50,
        droughtTolerant: true),
    WaterProfile('asparagus', 0.50, 0.95, 0.30, 0.70, 0.40),
    WaterProfile('okra', 0.50, 1.05, 0.85, 0.50, 0.40),
    WaterProfile('luffa', 0.50, 1.00, 0.80, 0.70, 0.35),
    WaterProfile('fennel', 0.70, 1.00, 0.95, 0.35, 0.35),
  ];
}
