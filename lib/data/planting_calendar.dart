import 'crop_catalog.dart';
import 'climate_engine.dart';
import 'irrigation.dart';
import 'region_profile.dart';

const List<String> _monthsGen = [
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

class PlantingStage {
  final String title;
  final int startMonth, startDay, endMonth, endDay;
  final bool isPlanting;
  final String note;

  const PlantingStage({
    required this.title,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    this.isPlanting = true,
    this.note = '',
  });

  bool contains(DateTime d) {
    final x = d.month * 100 + d.day;
    final s = startMonth * 100 + startDay;
    final e = endMonth * 100 + endDay;
    if (s <= e) return x >= s && x <= e;
    return x >= s || x <= e;
  }

  int daysUntilStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var target = DateTime(now.year, startMonth, startDay);
    if (target.isBefore(today)) {
      target = DateTime(now.year + 1, startMonth, startDay);
    }
    return target.difference(today).inDays;
  }

  String get rangeText =>
      '$startDay ${_monthsGen[startMonth - 1]} – $endDay ${_monthsGen[endMonth - 1]}';
}

class CropCalendar {
  final String key;
  final String name;
  final List<PlantingStage> stages;
  const CropCalendar({
    required this.key,
    required this.name,
    required this.stages,
  });
}

class CalendarStatus {
  final List<PlantingStage> active;
  final PlantingStage? next;
  final int daysUntilNext;
  const CalendarStatus({
    required this.active,
    this.next,
    this.daysUntilNext = 0,
  });
}

class PlantingCalendarUtils {
  static CropCalendar? forCrop(String cropName) {
    final rec = CropCatalog.byName(cropName);
    if (rec != null) {
      final manual = _manualByKey(rec.careKey ?? rec.id);
      if (manual != null) return manual;
      return fromRecord(rec);
    }
    final n = cropName.toLowerCase().replaceAll('ё', 'е');
    for (final c in _manual) {
      if (n.contains(c.key)) return c;
    }
    return null;
  }

  static CropCalendar? _manualByKey(String key) {
    for (final c in _manual) {
      if (c.key == key) return c;
    }
    return null;
  }

  static CropCalendar fromRecord(CropRecord r, {RegionProfile? climate}) {
    final year = DateTime.now().year;
    final profile = climate ??
        ClimateEngine.resolve(
          IrrigationSettings.instance.latitude,
          IrrigationSettings.instance.longitude,
        );
    final frost = profile.lastSpringFrost(year);

    PlantingStage stage(String title, DateTime from, int window,
        {bool planting = true, String note = ''}) {
      final to = from.add(Duration(days: window));
      return PlantingStage(
        title: title,
        startMonth: from.month,
        startDay: from.day,
        endMonth: to.month,
        endDay: to.day,
        isPlanting: planting,
        note: note,
      );
    }

    final stages = <PlantingStage>[];
    final transplant = frost.add(Duration(days: r.transplantOffset));
    final ground = frost.add(Duration(days: r.sowOffset));

    if (r.hasSeedling) {
      final seedling = transplant.subtract(Duration(days: r.seedlingDays));
      stages.add(stage('Посев на рассаду', seedling, 12,
          note: 'возраст рассады ${r.seedlingDays} дней'));
      stages.add(stage('Пикировка и подкормка рассады',
          seedling.add(const Duration(days: 18)), 12));
      if (r.greenhouse) {
        stages.add(stage('Высадка в теплицу',
            transplant.subtract(const Duration(days: 14)), 12));
      }
      stages.add(stage('Высадка в открытый грунт', transplant, 12,
          note: 'почва от +${r.plantingTemp} °C, ${r.scheme}'));
    } else {
      stages.add(stage('Посев в грунт', ground, 14,
          note: 'почва от +${r.plantingTemp} °C, глубина ${r.sowDepth} см'));
    }

    if (r.secondSowOffset != null) {
      final secondGround = frost.add(Duration(days: r.secondSowOffset!));
      stages.add(stage('Повторный посев в грунт', secondGround, 14,
          note: 'почва от +${r.plantingTemp} °C'));
    }

    if (r.winterSow) {
      stages.add(stage('Подзимний посев', DateTime(year, 10, 22), 16,
          note: 'по устойчивому холоду'));
    }

    if (r.maturity < 300) {
      final base = r.hasSeedling ? transplant : ground;
      final harvest = base.add(Duration(days: r.maturity));
      stages.add(stage('Сбор урожая', harvest, 35,
          planting: false,
          note:
              'через ${r.maturity} дней после ${r.hasSeedling ? "высадки" : "посева"}'));
    } else {
      stages.add(stage('Сбор урожая', DateTime(year, 7, 1), 60,
          planting: false, note: 'многолетняя культура'));
    }

    return CropCalendar(key: r.id, name: r.name, stages: stages);
  }

  static CalendarStatus getStatus(CropCalendar cal, DateTime now) {
    final active = cal.stages.where((s) => s.contains(now)).toList();
    PlantingStage? next;
    int best = 1 << 30;
    for (final s in cal.stages) {
      final d = s.daysUntilStart(now);
      if (d > 0 && d < best) {
        best = d;
        next = s;
      }
    }
    return CalendarStatus(
        active: active, next: next, daysUntilNext: next == null ? 0 : best);
  }

  static String buildAdvice({
    required CropCalendar? cal,
    required CalendarStatus? status,
    required bool isWaxing,
    required bool isNewOrFull,
    required bool isRoot,
  }) {
    if (cal == null || status == null) {
      return 'Для этой культуры пока нет точного календаря. Общий ориентир: '
          'высаживайте после последних заморозков. Следите за прогнозом.';
    }
    if (status.active.isNotEmpty) {
      final stage = status.active.first;
      if (!stage.isPlanting) {
        final note = stage.note.isNotEmpty ? ' ${stage.note}.' : '';
        return '🧺 Сейчас этап «${stage.title}» (${stage.rangeText}).$note';
      }
      final base = '✅ Открыто окно «${stage.title}» (${stage.rangeText}).';
      if (isNewOrFull) {
        return '$base По лунной традиции сегодня день покоя — можно подождать '
            '1–2 дня. Но погода и сроки важнее фазы Луны.';
      }
      final phaseGood = isRoot ? !isWaxing : isWaxing;
      if (phaseGood) {
        return '$base Луна в подходящей фазе — по традиции отличный день!';
      }
      return '$base Фаза Луны не идеальна, но климатическое окно важнее — работать можно.';
    }
    final next = status.next;
    if (next == null) {
      return 'Сезон для этой культуры завершён. Спланируйте работы на следующий год.';
    }
    final d = status.daysUntilNext;
    return 'Сейчас не сезон. Ближайший этап: «${next.title}» через $d '
        '${_daysWord(d)} (${next.rangeText}).';
  }

  static String _daysWord(int n) {
    final a = n % 10, b = n % 100;
    if (a == 1 && b != 11) return 'день';
    if (a >= 2 && a <= 4 && (b < 12 || b > 14)) return 'дня';
    return 'дней';
  }

  static const List<CropCalendar> _manual = [
    CropCalendar(key: 'помидор', name: 'Помидоры', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 3,
          startDay: 15,
          endMonth: 4,
          endDay: 5,
          note: 'прорастание при +22…25 °C'),
      PlantingStage(
          title: 'Пикировка рассады',
          startMonth: 4,
          startDay: 1,
          endMonth: 4,
          endDay: 20),
      PlantingStage(
          title: 'Высадка в теплицу',
          startMonth: 5,
          startDay: 1,
          endMonth: 5,
          endDay: 15,
          note: 'почва от +14 °C'),
      PlantingStage(
          title: 'Высадка в открытый грунт',
          startMonth: 5,
          startDay: 25,
          endMonth: 6,
          endDay: 10,
          note: 'почва от +14 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 15,
          endMonth: 9,
          endDay: 20,
          isPlanting: false),
    ]),
    CropCalendar(key: 'огурц', name: 'Огурцы', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 4,
          startDay: 15,
          endMonth: 4,
          endDay: 30,
          note: 'прорастание при +18…20 °C'),
      PlantingStage(
          title: 'Высадка в теплицу',
          startMonth: 5,
          startDay: 5,
          endMonth: 5,
          endDay: 15,
          note: 'почва от +16 °C'),
      PlantingStage(
          title: 'Посев и высадка в грунт',
          startMonth: 5,
          startDay: 25,
          endMonth: 6,
          endDay: 5,
          note: 'почва от +16 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 10,
          endMonth: 9,
          endDay: 5,
          isPlanting: false),
    ]),
    CropCalendar(key: 'перц', name: 'Перец', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 2,
          startDay: 20,
          endMonth: 3,
          endDay: 10,
          note: 'прорастание при +25…28 °C'),
      PlantingStage(
          title: 'Пикировка рассады',
          startMonth: 3,
          startDay: 10,
          endMonth: 3,
          endDay: 31),
      PlantingStage(
          title: 'Высадка в теплицу',
          startMonth: 5,
          startDay: 10,
          endMonth: 5,
          endDay: 20,
          note: 'почва от +15 °C'),
      PlantingStage(
          title: 'Высадка в открытый грунт',
          startMonth: 6,
          startDay: 1,
          endMonth: 6,
          endDay: 10,
          note: 'почва от +15 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 20,
          endMonth: 9,
          endDay: 25,
          isPlanting: false),
    ]),
    CropCalendar(key: 'баклажан', name: 'Баклажаны', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 2,
          startDay: 25,
          endMonth: 3,
          endDay: 15,
          note: 'прорастание при +25…28 °C'),
      PlantingStage(
          title: 'Высадка в теплицу',
          startMonth: 5,
          startDay: 10,
          endMonth: 5,
          endDay: 20,
          note: 'почва от +16 °C'),
      PlantingStage(
          title: 'Высадка в открытый грунт',
          startMonth: 6,
          startDay: 1,
          endMonth: 6,
          endDay: 10,
          note: 'почва от +16 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 25,
          endMonth: 9,
          endDay: 15,
          isPlanting: false),
    ]),
    CropCalendar(key: 'морков', name: 'Морковь', stages: [
      PlantingStage(
          title: 'Посев в грунт',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 10,
          note: 'почва от +6 °C'),
      PlantingStage(
          title: 'Подзимний посев',
          startMonth: 10,
          startDay: 20,
          endMonth: 11,
          endDay: 5),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 8,
          startDay: 10,
          endMonth: 9,
          endDay: 30,
          isPlanting: false),
    ]),
    CropCalendar(key: 'лук', name: 'Лук', stages: [
      PlantingStage(
          title: 'Посев чернушки на рассаду',
          startMonth: 2,
          startDay: 20,
          endMonth: 3,
          endDay: 10),
      PlantingStage(
          title: 'Посадка севка в грунт',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 10,
          note: 'почва от +8 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 8,
          startDay: 10,
          endMonth: 8,
          endDay: 31,
          isPlanting: false),
    ]),
    CropCalendar(key: 'чеснок', name: 'Чеснок', stages: [
      PlantingStage(
          title: 'Посадка ярового чеснока',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 5,
          note: 'почва от +5 °C'),
      PlantingStage(
          title: 'Посадка озимого чеснока',
          startMonth: 9,
          startDay: 25,
          endMonth: 10,
          endDay: 15,
          note: 'за 3–4 недели до морозов'),
      PlantingStage(
          title: 'Сбор озимого чеснока',
          startMonth: 7,
          startDay: 15,
          endMonth: 8,
          endDay: 10,
          isPlanting: false),
    ]),
    CropCalendar(key: 'картоф', name: 'Картофель', stages: [
      PlantingStage(
          title: 'Проращивание клубней',
          startMonth: 4,
          startDay: 1,
          endMonth: 4,
          endDay: 15,
          isPlanting: false),
      PlantingStage(
          title: 'Посадка в грунт',
          startMonth: 5,
          startDay: 5,
          endMonth: 5,
          endDay: 20,
          note: 'почва от +8 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 8,
          startDay: 10,
          endMonth: 9,
          endDay: 5,
          isPlanting: false),
    ]),
    CropCalendar(key: 'свекл', name: 'Свёкла', stages: [
      PlantingStage(
          title: 'Посев в грунт',
          startMonth: 5,
          startDay: 10,
          endMonth: 5,
          endDay: 25,
          note: 'почва от +10 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 9,
          startDay: 1,
          endMonth: 9,
          endDay: 30,
          isPlanting: false),
    ]),
    CropCalendar(key: 'капуст', name: 'Капуста', stages: [
      PlantingStage(
          title: 'Посев ранней на рассаду',
          startMonth: 3,
          startDay: 1,
          endMonth: 3,
          endDay: 15,
          note: 'прорастание при +6…8 °C'),
      PlantingStage(
          title: 'Высадка ранней в грунт',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 10,
          note: 'почва от +6 °C'),
      PlantingStage(
          title: 'Посев поздней на рассаду',
          startMonth: 4,
          startDay: 1,
          endMonth: 4,
          endDay: 15),
      PlantingStage(
          title: 'Высадка поздней в грунт',
          startMonth: 5,
          startDay: 15,
          endMonth: 5,
          endDay: 30),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 15,
          endMonth: 10,
          endDay: 10,
          isPlanting: false),
    ]),
    CropCalendar(key: 'редис', name: 'Редис', stages: [
      PlantingStage(
          title: 'Весенний посев',
          startMonth: 4,
          startDay: 20,
          endMonth: 5,
          endDay: 10,
          note: 'почва от +5 °C'),
      PlantingStage(
          title: 'Сбор весеннего урожая',
          startMonth: 5,
          startDay: 15,
          endMonth: 6,
          endDay: 15,
          isPlanting: false),
      PlantingStage(
          title: 'Летний посев',
          startMonth: 8,
          startDay: 1,
          endMonth: 8,
          endDay: 15,
          note: 'почва от +5 °C'),
      PlantingStage(
          title: 'Сбор летнего урожая',
          startMonth: 8,
          startDay: 20,
          endMonth: 9,
          endDay: 20,
          isPlanting: false),
    ]),
    CropCalendar(key: 'кабачк', name: 'Кабачки', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 4,
          startDay: 20,
          endMonth: 4,
          endDay: 30,
          note: 'прорастание при +15…18 °C'),
      PlantingStage(
          title: 'Высадка и посев в грунт',
          startMonth: 5,
          startDay: 25,
          endMonth: 6,
          endDay: 5,
          note: 'почва от +14 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 15,
          endMonth: 9,
          endDay: 15,
          isPlanting: false),
    ]),
    CropCalendar(key: 'зелен', name: 'Зелень', stages: [
      PlantingStage(
          title: 'Весенний посев в грунт',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 20,
          note: 'почва от +5 °C'),
      PlantingStage(
          title: 'Летний посев',
          startMonth: 8,
          startDay: 15,
          endMonth: 9,
          endDay: 1,
          note: 'почва от +5 °C'),
      PlantingStage(
          title: 'Подзимний посев',
          startMonth: 10,
          startDay: 25,
          endMonth: 11,
          endDay: 10),
      PlantingStage(
          title: 'Срезка зелени',
          startMonth: 6,
          startDay: 1,
          endMonth: 9,
          endDay: 30,
          isPlanting: false),
    ]),
    CropCalendar(key: 'горох', name: 'Горох', stages: [
      PlantingStage(
          title: 'Посев в грунт',
          startMonth: 4,
          startDay: 25,
          endMonth: 5,
          endDay: 10,
          note: 'почва от +6 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 7,
          startDay: 5,
          endMonth: 8,
          endDay: 10,
          isPlanting: false),
    ]),
    CropCalendar(key: 'тыкв', name: 'Тыква', stages: [
      PlantingStage(
          title: 'Посев на рассаду',
          startMonth: 4,
          startDay: 20,
          endMonth: 5,
          endDay: 5,
          note: 'прорастание при +14…16 °C'),
      PlantingStage(
          title: 'Высадка в грунт',
          startMonth: 5,
          startDay: 25,
          endMonth: 6,
          endDay: 5,
          note: 'почва от +14 °C'),
      PlantingStage(
          title: 'Сбор урожая',
          startMonth: 9,
          startDay: 1,
          endMonth: 9,
          endDay: 30,
          isPlanting: false),
    ]),
  ];

  static List<CropCalendar> get kPlantingCalendars => _manual;
}

List<CropCalendar> get kPlantingCalendars {
  final out = <CropCalendar>[];
  for (final r in CropCatalog.all) {
    final cal = PlantingCalendarUtils.forCrop(r.name);
    if (cal != null) out.add(cal);
  }
  return out;
}
