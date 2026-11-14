import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crops_data.dart';

String cropIdOf(String name) => name.toLowerCase().replaceAll('ё', 'е').trim();

enum DiaryKind { planting, harvest, care, note }

class DiaryMeta {
  static String title(DiaryKind k) {
    switch (k) {
      case DiaryKind.planting:
        return 'Посадка';
      case DiaryKind.harvest:
        return 'Урожай';
      case DiaryKind.care:
        return 'Уход';
      case DiaryKind.note:
        return 'Заметка';
    }
  }

  static String emoji(DiaryKind k) {
    switch (k) {
      case DiaryKind.planting:
        return '🌱';
      case DiaryKind.harvest:
        return '🧺';
      case DiaryKind.care:
        return '💧';
      case DiaryKind.note:
        return '📝';
    }
  }
}

class DiaryEntry {
  final String id;
  final String cropId;
  final String cropName;
  final String cropEmoji;
  final DiaryKind kind;
  final DateTime date;
  final String variety;
  final String method;
  final double? amount;
  final String unit;
  final int rating;
  final String note;
  final String plotId;

  const DiaryEntry({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.cropEmoji,
    required this.kind,
    required this.date,
    this.variety = '',
    this.method = '',
    this.amount,
    this.unit = 'кг',
    this.rating = 0,
    this.note = '',
    this.plotId = 'Основная грядка',
  });

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

  DiaryEntry copyWith({
    String? cropId,
    String? cropName,
    String? cropEmoji,
    DiaryKind? kind,
    DateTime? date,
    String? variety,
    String? method,
    double? amount,
    bool clearAmount = false,
    String? unit,
    int? rating,
    String? note,
    String? plotId,
  }) {
    return DiaryEntry(
      id: id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      cropEmoji: cropEmoji ?? this.cropEmoji,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      variety: variety ?? this.variety,
      method: method ?? this.method,
      amount: clearAmount ? null : (amount ?? this.amount),
      unit: unit ?? this.unit,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      plotId: plotId ?? this.plotId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropId': cropId,
        'cropName': cropName,
        'cropEmoji': cropEmoji,
        'kind': kind.index,
        'date': date.millisecondsSinceEpoch,
        'variety': variety,
        'method': method,
        'amount': amount,
        'unit': unit,
        'rating': rating,
        'note': note,
        'plotId': plotId,
      };

  static DiaryEntry? fromJson(Map<String, dynamic> j) {
    try {
      return DiaryEntry(
        id: j['id'] as String,
        cropId: (j['cropId'] as String?) ?? '',
        cropName: (j['cropName'] as String?) ?? 'Весь сад',
        cropEmoji: (j['cropEmoji'] as String?) ?? '🌿',
        kind: DiaryKind.values[(j['kind'] as num?)?.toInt() ?? 3],
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        variety: (j['variety'] as String?) ?? '',
        method: (j['method'] as String?) ?? '',
        amount: (j['amount'] as num?)?.toDouble(),
        unit: (j['unit'] as String?) ?? 'кг',
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        note: (j['note'] as String?) ?? '',
        plotId: (j['plotId'] as String?) ?? 'Основная грядка',
      );
    } catch (_) {
      return null;
    }
  }

  String get amountText {
    if (amount == null) return '';
    final v = amount!;
    return '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} $unit';
  }
}

class DiaryStats {
  final int plantings, harvests, notes;
  final double totalKg;
  final double avgRating;
  final int cropsTouched;
  const DiaryStats(
      {this.plantings = 0,
      this.harvests = 0,
      this.notes = 0,
      this.totalKg = 0,
      this.avgRating = 0,
      this.cropsTouched = 0});
}

class GardenStore extends ChangeNotifier {
  GardenStore._();
  static final GardenStore instance = GardenStore._();

  static const _kCrops = 'garden_crops_v1';
  static const _kDiary = 'garden_diary_v1';
  static const _kSeason = 'garden_season_v1';

  final List<String> _crops = [];
  final List<DiaryEntry> _entries = [];
  int _season = DateTime.now().year;
  bool _ready = false;
  SharedPreferences? _prefs;

  bool get ready => _ready;
  int get season => _season;
  List<String> get cropIds => List.unmodifiable(_crops);
  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  int get count => _crops.length;
  bool get isEmpty => _crops.isEmpty;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _crops.clear();
    _crops.addAll(_prefs!.getStringList(_kCrops) ?? const []);
    _season = _prefs!.getInt(_kSeason) ?? DateTime.now().year;

    final raw = _prefs!.getString(_kDiary);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              final e = DiaryEntry.fromJson(Map<String, dynamic>.from(item));
              if (e != null) _entries.add(e);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Дневник повреждён: $e');
      }
    }
    _entries.sort((a, b) => b.date.compareTo(a.date));
    _ready = true;
    notifyListeners();
  }

  Crop? cropById(String id) {
    for (final c in availableCrops) {
      if (cropIdOf(c.name) == id) return c;
    }
    return null;
  }

  List<Crop> get crops {
    final out = <Crop>[];
    for (final id in _crops) {
      final c = cropById(id);
      if (c != null) out.add(c);
    }
    return out;
  }

  bool has(String id) => _crops.contains(id);
  List<Crop> get suggestions =>
      availableCrops.where((c) => !has(cropIdOf(c.name))).take(6).toList();

  Future<void> addCrop(String name) async {
    final id = cropIdOf(name);
    if (_crops.contains(id)) return;
    _crops.add(id);
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
  }

  Future<void> removeCrop(String id) async {
    if (!_crops.remove(id)) return;
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
  }

  Future<void> insertCrop(int index, String id) async {
    if (_crops.contains(id)) return;
    _crops.insert(index.clamp(0, _crops.length), id);
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _crops.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    final item = _crops.removeAt(oldIndex);
    _crops.insert(target.clamp(0, _crops.length), item);
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
  }

  Future<List<String>> clearGarden() async {
    final snapshot = List<String>.from(_crops);
    _crops.clear();
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
    return snapshot;
  }

  Future<void> restoreGarden(List<String> snapshot) async {
    _crops.clear();
    _crops.addAll(snapshot);
    notifyListeners();
    await _prefs?.setStringList(_kCrops, _crops);
  }

  List<int> get availableYears {
    final years = <int>{DateTime.now().year, _season};
    for (final e in _entries) {
      years.add(e.date.year);
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  Future<void> setSeason(int year) async {
    if (_season == year) return;
    _season = year;
    notifyListeners();
    await _prefs?.setInt(_kSeason, year);
  }

  Future<void> upsertEntry(DiaryEntry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      _entries[i] = entry;
    } else {
      _entries.add(entry);
    }
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _persistDiary();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistDiary();
  }

  Future<void> _persistDiary() async {
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await _prefs?.setString(_kDiary, raw);
  }

  List<DiaryEntry> query(
      {int? year, String? cropId, DiaryKind? kind, String search = ''}) {
    final q = search.trim().toLowerCase();
    return _entries.where((e) {
      if (year != null && e.date.year != year) return false;
      if (cropId != null && e.cropId != cropId) return false;
      if (kind != null && e.kind != kind) return false;
      if (q.isEmpty) return true;
      return e.cropName.toLowerCase().contains(q) ||
          e.note.toLowerCase().contains(q) ||
          e.variety.toLowerCase().contains(q);
    }).toList();
  }

  DiaryStats statsFor(int year) {
    final list = query(year: year);
    var plantings = 0, harvests = 0, notes = 0, ratings = 0, ratingSum = 0;
    var kg = 0.0;
    final touched = <String>{};
    for (final e in list) {
      if (e.cropId.isNotEmpty) touched.add(e.cropId);
      if (e.kind == DiaryKind.planting) {
        plantings++;
      } else if (e.kind == DiaryKind.harvest) {
        harvests++;
        if (e.unit == 'кг' && e.amount != null) kg += e.amount!;
        if (e.rating > 0) {
          ratings++;
          ratingSum += e.rating;
        }
      } else {
        notes++;
      }
    }
    return DiaryStats(
      plantings: plantings,
      harvests: harvests,
      notes: notes,
      totalKg: kg,
      avgRating: ratings == 0 ? 0 : ratingSum / ratings,
      cropsTouched: touched.length,
    );
  }

  MapEntry<String, double>? topCrop(int year) {
    final map = <String, double>{};
    for (final e in query(year: year, kind: DiaryKind.harvest)) {
      if (e.unit != 'кг' || e.amount == null) continue;
      map[e.cropName] = (map[e.cropName] ?? 0) + e.amount!;
    }
    if (map.isEmpty) return null;
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  // ✅ НОВОЕ: диагностический метод. Создаёт N тестовых записей,
  // замеряет все этапы (генерация, кодирование, декодирование,
  // запись в SharedPreferences, полный upsert) и откатывает всё назад.
  // Данные пользователя НЕ затрагиваются.
  Future<Map<String, int>> stressTest({int count = 300}) async {
    final original = List<DiaryEntry>.from(_entries);
    debugPrint(
        '🧪 СТРЕСС-ТЕСТ: начинаем, записей в дневнике сейчас: ${original.length}');

    // 1. Генерация объектов
    final sw = Stopwatch()..start();
    final testEntries = <DiaryEntry>[];
    for (int i = 0; i < count; i++) {
      testEntries.add(DiaryEntry(
        id: 'stress_${i}_${DateTime.now().microsecondsSinceEpoch}',
        cropId: 'crop_stress_$i',
        cropName: 'Стресс-культура $i',
        cropEmoji: '🌱',
        kind: DiaryKind.values[i % 4],
        date: DateTime.now().subtract(Duration(days: i)),
        variety: 'Тестовый сорт $i',
        method: 'Рассада',
        amount: (i % 10).toDouble(),
        unit: 'кг',
        rating: i % 6,
        note: 'Стресс-тестовая запись $i. Имитация реального текста заметки '
            'для проверки парсинга JSON на больших объёмах.',
        plotId: 'Грядка ${i % 5}',
      ));
    }
    sw.stop();
    final genMs = sw.elapsedMilliseconds;

    // 2. Кодирование в JSON (как при _persistDiary)
    sw.reset();
    final json = jsonEncode(testEntries.map((e) => e.toJson()).toList());
    sw.stop();
    final encodeMs = sw.elapsedMilliseconds;
    final jsonSizeKb = (json.length / 1024).round();

    // 3. Декодирование + парсинг (как при init)
    sw.reset();
    final decoded = jsonDecode(json);
    final parsed = <DiaryEntry>[];
    for (final item in decoded as List) {
      final e = DiaryEntry.fromJson(Map<String, dynamic>.from(item));
      if (e != null) parsed.add(e);
    }
    sw.stop();
    final decodeMs = sw.elapsedMilliseconds;

    // 4. Запись в SharedPreferences (ключ только для теста)
    sw.reset();
    await _prefs?.setString('__stress_test__', json);
    await _prefs?.remove('__stress_test__');
    sw.stop();
    final saveMs = sw.elapsedMilliseconds;

    // 5. Полный сценарий: добавить в store + persist (как upsertEntry x300)
    sw.reset();
    _entries.addAll(testEntries);
    _entries.sort((a, b) => b.date.compareTo(a.date));
    await _persistDiary();
    sw.stop();
    final fullUpsertMs = sw.elapsedMilliseconds;

    // 6. Откат: удаляем тестовые записи и сохраняем как было
    _entries.clear();
    _entries.addAll(original);
    _entries.sort((a, b) => b.date.compareTo(a.date));
    await _persistDiary();
    notifyListeners();

    final report = <String, int>{
      'count': count,
      'generation_ms': genMs,
      'encode_ms': encodeMs,
      'decode_parse_ms': decodeMs,
      'sharedprefs_save_ms': saveMs,
      'full_upsert_ms': fullUpsertMs,
      'json_size_kb': jsonSizeKb,
    };

    debugPrint('');
    debugPrint('════════════════════════════════════════════');
    debugPrint('📊 РЕЗУЛЬТАТЫ СТРЕСС-ТЕСТА ($count записей)');
    debugPrint('════════════════════════════════════════════');
    debugPrint('Генерация объектов:        $genMs мс');
    debugPrint('Кодирование JSON:          $encodeMs мс');
    debugPrint(
        'Декодирование + парсинг:   $decodeMs мс  ← ВАЖНО (каждый запуск)');
    debugPrint(
        'Сохранение в SharedPrefs:  $saveMs мс  ← ВАЖНО (каждое изменение)');
    debugPrint('Полный цикл (upsert+save): $fullUpsertMs мс');
    debugPrint('Размер JSON:               $jsonSizeKb КБ');
    debugPrint('════════════════════════════════════════════');
    debugPrint('ВЕРДИКТ:');
    if (decodeMs < 200 && fullUpsertMs < 500) {
      debugPrint('🟢 ОТЛИЧНО — SharedPreferences справляется, Hive НЕ НУЖЕН');
    } else if (decodeMs < 500 && fullUpsertMs < 1500) {
      debugPrint('🟡 ТЕРПИМО — можно жить, Hive под вопросом');
    } else {
      debugPrint('🔴 ПЛОХО — пришло время для Hive');
    }
    debugPrint('════════════════════════════════════════════');
    debugPrint('');

    return report;
  }
}
