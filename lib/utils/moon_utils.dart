import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:astronomia/astronomia.dart' as astro;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/solar.dart' as solar;
import 'package:astronomia/sidereal.dart' as sid;
import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/rise.dart' as rise;

class MoonInfo {
  final int lunarDay;
  final double ageDays;
  final String phaseName;
  final String phaseEmoji;
  final int illumination;
  final bool isWaxing;
  final bool isNewOrFull;

  const MoonInfo({
    required this.lunarDay,
    required this.ageDays,
    required this.phaseName,
    required this.phaseEmoji,
    required this.illumination,
    required this.isWaxing,
    required this.isNewOrFull,
  });
}

class MoonTimes {
  final DateTime? rise;
  final DateTime? set;
  const MoonTimes({this.rise, this.set});
}

/// Астрономический расчёт Луны.
/// Основной движок: профессиональная библиотека astronomia (Meeus).
/// Страховка: встроенный проверенный расчёт (включается при сбое библиотеки).
class MoonUtils {
  static const double _rad = math.pi / 180;
  static const double _synodic = 29.530588853;
  static const double _dayMs = 1000 * 60 * 60 * 24;
  static const double _j2000 = 2451545.0;

  // ================= ПУБЛИЧНЫЙ API (не меняется) =================

  /// Возраст Луны в днях от новолуния
  static double moonAge(DateTime date) =>
      _elongation(date) / (2 * math.pi) * _synodic;

  /// Освещённость, %
  static int illumination(DateTime date) =>
      (((1 - math.cos(_elongation(date))) / 2) * 100).round();

  /// Полная информация о Луне
  static MoonInfo getMoonInfo(DateTime date) {
    final age = moonAge(date);
    final lunarDay = age.floor() + 1;
    final illum = illumination(date);
    final waxing = age < _synodic / 2;

    String name;
    String emoji;
    bool newOrFull = false;

    if (age < 1.0 || age > _synodic - 1.0) {
      name = 'Новолуние';
      emoji = '🌑';
      newOrFull = true;
    } else if ((age - _synodic / 2).abs() <= 1.0) {
      name = 'Полнолуние';
      emoji = '🌕';
      newOrFull = true;
    } else if (waxing) {
      if (age < 6.4) {
        name = 'Молодая Луна';
        emoji = '🌒';
      } else if (age < 8.4) {
        name = 'Первая четверть';
        emoji = '🌓';
      } else {
        name = 'Растущая Луна';
        emoji = '🌔';
      }
    } else {
      if (age < 21.1) {
        name = 'Убывающая Луна';
        emoji = '🌖';
      } else if (age < 23.1) {
        name = 'Последняя четверть';
        emoji = '🌗';
      } else {
        name = 'Старая Луна';
        emoji = '🌘';
      }
    }

    return MoonInfo(
      lunarDay: lunarDay,
      ageDays: age,
      phaseName: name,
      phaseEmoji: emoji,
      illumination: illum,
      isWaxing: waxing,
      isNewOrFull: newOrFull,
    );
  }

  /// Высота Луны над горизонтом (радианы) для конкретных координат
  static double altitudeAt(DateTime date, double lat, double lon) {
    try {
      final u = date.toUtc();
      final jd0 =
          astro.calendarGregorianToJD(u.year, u.month, u.day.toDouble());
      final th0 = sid.apparent0UT(jd0);
      final frac = (u.hour * 3600 + u.minute * 60 + u.second) / 86400.0;
      final theta = th0 + 2 * math.pi * 1.00273790935 * frac;

      final jd = _jdOf(date);
      final pos = moon.position(jd);
      final eps = _eps(jd);
      final eq = coord.eclToEq(pos.lon, pos.lat, math.sin(eps), math.cos(eps));

      final h = theta + lon * _rad - eq.ra;
      final phi = lat * _rad;
      return math.asin(math.sin(phi) * math.sin(eq.dec) +
          math.cos(phi) * math.cos(eq.dec) * math.cos(h));
    } catch (e) {
      debugPrint('⚠️ astronomia (altitude): $e → встроенный расчёт');
      return _fbAltitude(date, lat, lon);
    }
  }

  /// Восход и заход Луны за МЕСТНЫЕ сутки для конкретных координат
  static MoonTimes getMoonTimesForCoords(
      DateTime date, double lat, double lon, int utcOffset) {
    try {
      final localMidnightUtc = DateTime.utc(date.year, date.month, date.day)
          .subtract(Duration(hours: utcOffset));
      final dayEndUtc = localMidnightUtc.add(const Duration(hours: 24));
      final ut0 = DateTime.utc(
          localMidnightUtc.year, localMidnightUtc.month, localMidnightUtc.day);

      DateTime? riseUtc;
      DateTime? setUtc;

      // Библиотека считает UT-сутки → берём два дня и отбираем события
      // внутри местных суток.
      for (int n = 0; n <= 1; n++) {
        final d = ut0.add(Duration(days: n));
        final jd =
            astro.calendarGregorianToJD(d.year, d.month, d.day.toDouble());
        final th0 = sid.apparent0UT(jd);

        final res = rise.moonTimes(
          jd,
          lat * _rad,
          -lon * _rad, // ВНИМАНИЕ: в библиотеке долгота положительна на ЗАПАД
          69, // стандартный параметр из официального примера библиотеки
          th0,
          (double jde) {
            final pos = moon.position(jde);
            final eps = _eps(jde);
            final eq =
                coord.eclToEq(pos.lon, pos.lat, math.sin(eps), math.cos(eps));
            return (ra: eq.ra, dec: eq.dec, parallax: moon.parallax(pos.delta));
          },
        );

        if (res == null) continue;

        riseUtc ??= _eventInWindow(res.rise, d, localMidnightUtc, dayEndUtc);
        setUtc ??= _eventInWindow(res.set, d, localMidnightUtc, dayEndUtc);

        if (riseUtc != null && setUtc != null) break;
      }

      if (riseUtc == null && setUtc == null) {
        debugPrint(
            'ℹ️ astronomia: событий нет, перепроверяю встроенным расчётом');
        return _fbTimes(date, lat, lon, utcOffset);
      }

      return MoonTimes(rise: riseUtc, set: setUtc);
    } catch (e) {
      debugPrint('⚠️ astronomia (rise/set): $e → встроенный расчёт');
      return _fbTimes(date, lat, lon, utcOffset);
    }
  }

  static String formatCityTime(DateTime? utcTime, int utcOffsetHours) {
    if (utcTime == null) return '—';
    final city = utcTime.add(Duration(hours: utcOffsetHours));
    return '${city.hour.toString().padLeft(2, '0')}:${city.minute.toString().padLeft(2, '0')}';
  }

  static bool isRootCrop(String name) =>
      name.contains('Морковь') ||
      name.contains('Лук') ||
      name.contains('Картофель') ||
      name.contains('Свёкла') ||
      name.contains('Редис');

  static String getPlantingAdvice(String cropName, MoonInfo info) {
    final isRoot = isRootCrop(cropName);
    final lower = cropName.toLowerCase();

    if (info.isNewOrFull) {
      return 'Сегодня ${info.phaseName.toLowerCase()} — день покоя. Посадку и пересадку лучше отложить. Займитесь поливом, прополкой или планированием грядок.';
    }
    if (info.isWaxing) {
      return isRoot
          ? 'Луна растущая: соки идут в надземную часть. Корнеплоды ($lower) сейчас сажать не стоит — дождитесь убывающей луны.'
          : 'Луна растущая: соки идут в стебли и плоды. Отличное время для посадки — $lower будут расти активно!';
    }
    return isRoot
        ? 'Луна убывающая: соки уходят в корень. Идеальное время для посадки: $lower!'
        : 'Луна убывающая: лучшее время для корнеплодов и борьбы с сорняками. Для культуры «$lower» дождитесь растущей луны.';
  }

  // ================= СЛУЖЕБНОЕ (astronomia) =================

  static double _jdOf(DateTime date) {
    final u = date.toUtc();
    final frac =
        (u.hour * 3600 + u.minute * 60 + u.second + u.millisecond / 1000.0) /
            86400.0;
    return astro.calendarGregorianToJD(u.year, u.month, u.day + frac);
  }

  static double _eps(double jd) {
    final t = (jd - _j2000) / 36525.0;
    return (23.4393 - 0.0130 * t) * _rad;
  }

  static double _elongation(DateTime date) {
    try {
      final jd = _jdOf(date);
      final m = moon.position(jd);
      final s = solar.apparentLongitude(astro.j2000Century(jd));
      var el = (m.lon - s) % (2 * math.pi);
      if (el < 0) el += 2 * math.pi;
      return el;
    } catch (e) {
      debugPrint('⚠️ astronomia (elongation): $e → встроенный расчёт');
      return _fbElongation(date);
    }
  }

  static DateTime? _eventInWindow(
      double? seconds, DateTime utDay, DateTime from, DateTime to) {
    if (seconds == null) return null;
    final t = utDay.add(Duration(milliseconds: (seconds * 1000).round()));
    if (t.isBefore(from) || !t.isBefore(to)) return null;
    return t;
  }

  // ================= СТРАХОВКА: встроенный проверенный расчёт =================

  static double _fbToDays(DateTime date) =>
      date.millisecondsSinceEpoch / _dayMs - 0.5 + 2440588.0 - _j2000;

  static DateTime _fbHoursLater(DateTime date, double hours) =>
      DateTime.fromMillisecondsSinceEpoch(
        date.millisecondsSinceEpoch + (hours * _dayMs / 24).round(),
        isUtc: true,
      );

  static List<double> _fbMoonEcliptic(double d) {
    final t = d / 36525.0;
    final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t;
    final dd = (297.8501921 + 445267.1114034 * t - 0.0018819 * t * t) * _rad;
    final m = (357.5291092 + 35999.0502909 * t - 0.0001536 * t * t) * _rad;
    final mp = (134.9633964 + 477198.8675055 * t + 0.0087414 * t * t) * _rad;
    final f = (93.2720950 + 483202.0175233 * t - 0.0036539 * t * t) * _rad;

    final sl = 6288774 * math.sin(mp) +
        1274027 * math.sin(2 * dd - mp) +
        658314 * math.sin(2 * dd) +
        213618 * math.sin(2 * mp) -
        185116 * math.sin(m) -
        114332 * math.sin(2 * f) +
        58793 * math.sin(2 * dd - 2 * mp) +
        57066 * math.sin(2 * dd - m - mp) +
        53322 * math.sin(2 * dd + mp) +
        45758 * math.sin(2 * dd - m) -
        40923 * math.sin(m - mp) -
        34720 * math.sin(dd) -
        30383 * math.sin(m + mp) +
        15327 * math.sin(2 * dd - 2 * f) -
        12528 * math.sin(mp + 2 * f) +
        10980 * math.sin(mp - 2 * f) +
        10675 * math.sin(4 * dd - mp) +
        10034 * math.sin(3 * mp) +
        8548 * math.sin(4 * dd - 2 * mp) -
        7888 * math.sin(2 * dd + m - mp) -
        6766 * math.sin(2 * dd + m) -
        5163 * math.sin(dd - mp) +
        4987 * math.sin(dd + m) +
        4036 * math.sin(2 * dd - m + mp);

    final sb = 5128122 * math.sin(f) +
        280602 * math.sin(mp + f) +
        277693 * math.sin(mp - f) +
        173237 * math.sin(2 * dd - f) +
        55413 * math.sin(2 * dd - mp + f) +
        46271 * math.sin(2 * dd - mp - f) +
        32573 * math.sin(2 * dd + f) +
        17198 * math.sin(2 * mp + f) +
        9266 * math.sin(2 * dd + mp - f) +
        8822 * math.sin(2 * mp - f) +
        8216 * math.sin(2 * dd - m - f) +
        4324 * math.sin(2 * dd - 2 * mp - f) +
        4200 * math.sin(2 * dd + mp + f);

    return [(lp + sl / 1e6) * _rad, (sb / 1e6) * _rad];
  }

  static double _fbSunLon(double d) {
    final t = d / 36525.0;
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * _rad;
    final c = (1.914602 - 0.004817 * t) * math.sin(m) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m) +
        0.000289 * math.sin(3 * m);
    return (l0 + c) * _rad;
  }

  static double _fbElongation(DateTime date) {
    final d = _fbToDays(date);
    var el = (_fbMoonEcliptic(d)[0] - _fbSunLon(d)) % (2 * math.pi);
    if (el < 0) el += 2 * math.pi;
    return el;
  }

  static double _fbAltitude(DateTime date, double lat, double lon) {
    final d = _fbToDays(date);
    final t = d / 36525.0;
    final eps = (23.4393 - 0.0130 * t) * _rad;
    final ecl = _fbMoonEcliptic(d);
    final l = ecl[0];
    final b = ecl[1];
    final ra = math.atan2(
        math.sin(l) * math.cos(eps) - math.tan(b) * math.sin(eps), math.cos(l));
    final dec = math.asin(math.sin(b) * math.cos(eps) +
        math.cos(b) * math.sin(eps) * math.sin(l));
    final theta = _rad * (280.46061837 + 360.98564736629 * d);
    final h = theta + lon * _rad - ra;
    final phi = lat * _rad;
    return math.asin(math.sin(phi) * math.sin(dec) +
        math.cos(phi) * math.cos(dec) * math.cos(h));
  }

  static MoonTimes _fbTimes(
      DateTime date, double lat, double lon, int utcOffset) {
    final t = DateTime.utc(date.year, date.month, date.day)
        .subtract(Duration(hours: utcOffset));

    const hc = 0.133 * _rad;
    double h0 = _fbAltitude(t, lat, lon) - hc;
    DateTime? riseUtc;
    DateTime? setUtc;

    for (int i = 1; i <= 24; i += 2) {
      final h1 = _fbAltitude(_fbHoursLater(t, i.toDouble()), lat, lon) - hc;
      final h2 = _fbAltitude(_fbHoursLater(t, i + 1.0), lat, lon) - hc;

      final a = (h0 + h2) / 2 - h1;
      final b = (h2 - h0) / 2;

      if (a.abs() < 1e-12) {
        h0 = h2;
        continue;
      }

      final xe = -b / (2 * a);
      final ye = (a * xe + b) * xe + h1;
      final d = b * b - 4 * a * h1;
      int roots = 0;
      double r1 = 0;
      double r2 = 0;

      if (d >= 0) {
        final dx = math.sqrt(d) / (a.abs() * 2);
        r1 = xe - dx;
        r2 = xe + dx;
        if (r1.abs() <= 1) roots++;
        if (r2.abs() <= 1) roots++;
        if (r1 < -1) r1 = r2;
      }

      if (roots == 1) {
        if (h0 < 0) {
          riseUtc = _fbHoursLater(t, i + r1);
        } else {
          setUtc = _fbHoursLater(t, i + r1);
        }
      } else if (roots == 2) {
        riseUtc = _fbHoursLater(t, i + (ye < 0 ? r2 : r1));
        setUtc = _fbHoursLater(t, i + (ye < 0 ? r1 : r2));
      }

      if (riseUtc != null && setUtc != null) break;
      h0 = h2;
    }

    return MoonTimes(rise: riseUtc, set: setUtc);
  }
}
