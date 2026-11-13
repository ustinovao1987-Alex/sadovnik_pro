import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cities.dart';
import '../data/climate_zones.dart';
import '../data/crop_care_data.dart';
import '../data/crops_data.dart';
import '../data/garden_store.dart';
import '../data/irrigation.dart';
import '../data/planting_calendar.dart';
import '../data/region_profile.dart';
import '../data/work_agenda.dart';
import '../services/weather_service.dart';
import '../utils/moon_utils.dart';
import '../widgets/crop_icon.dart';
import '../widgets/moon_visual.dart';
import '../widgets/weather_widget.dart';
import 'about_screen.dart';
import 'add_crop_screen.dart';
import 'city_picker_screen.dart';
import 'crop_detail_screen.dart';
import 'diary_entry_screen.dart';
import 'diary_screen.dart';
import 'export_screen.dart';
import 'reminders_screen.dart';
import 'rotation_screen.dart';

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
const List<String> _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

class _CropInfo {
  final Crop crop;
  final CropCare care;
  final DateTime? lastWater;
  final bool tracked;
  final bool due;
  final bool favorable;
  final String windowText;
  final bool windowActive;
  final int urgency;
  final int diaryCount;

  const _CropInfo({
    required this.crop,
    required this.care,
    required this.lastWater,
    required this.tracked,
    required this.due,
    required this.favorable,
    required this.windowText,
    required this.windowActive,
    required this.urgency,
    required this.diaryCount,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _night = Color(0xFF0E1729);
  static const Color _night2 = Color(0xFF1D2B47);
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _sprout = Color(0xFF66BB6A);
  static const Color _water = Color(0xFF1E88E5);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _moonGold = Color(0xFFFFD54F);
  static const Color _berry = Color(0xFFC62828);
  static const Color _cream = Color(0xFFF7F5EF);

  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  bool _loading = true;
  City? _city;
  DateTime _now = DateTime.now();
  Map<String, DateTime?> _waterMap = {};
  bool _notifEnabled = false;
  int _notifCount = 0;
  String _query = '';
  int _filter = 0;
  bool _sortUrgency = false;
  WeatherData? _weather;

  RegionProfile? _regionProfile;
  ClimateZone? _climateZone;

  @override
  void initState() {
    super.initState();
    GardenStore.instance.addListener(_onGarden);
    _bootstrap();
  }

  void _onGarden() {
    if (mounted) _load();
  }

  Future<void> _bootstrap() async {
    await GardenStore.instance.init();
    await WeatherService.instance.init();
    await _load();

    final s = IrrigationSettings.instance;
    final weather = await WeatherService.instance.fetchAndUpdate(
      latitude: s.latitude,
      longitude: s.longitude,
    );

    if (mounted) {
      setState(() {
        _weather = weather;
        _regionProfile = WeatherService.instance.regionProfile;
        _climateZone = WeatherService.instance.climateZone;
      });
    }
  }

  @override
  void dispose() {
    GardenStore.instance.removeListener(_onGarden);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    await CityRepository.instance.loadCities();

    final lat = prefs.getDouble('loc_lat');
    final lon = prefs.getDouble('loc_lon');
    final name = prefs.getString('loc_name');

    City city;
    if (lat != null && lon != null && name != null) {
      city = City(
        name: name,
        region: prefs.getString('loc_region') ?? '',
        district: prefs.getString('loc_district') ?? '',
        lat: lat,
        lon: lon,
        utcOffset: prefs.getInt('loc_utc') ?? 4,
        timezone: prefs.getString('loc_timezone'),
      );
    } else {
      city = CityRepository.instance
              .findByName(prefs.getString('selected_city')) ??
          CityRepository.instance.defaultCity;
    }

    final map = <String, DateTime?>{};
    for (final crop in GardenStore.instance.crops) {
      final care = CropCareRepository.forCrop(crop.name);
      map[care.key] = await WateringLog.last(care.key);
    }

    if (!mounted) return;
    setState(() {
      _city = city;
      _now = DateTime.now();
      _waterMap = map;
      _notifEnabled = prefs.getBool('notifications_enabled') ?? false;
      _notifCount = prefs.getInt('notifications_count') ?? 0;
      _loading = false;
    });
  }

  Future<void> _pickCity() async {
    final current = _city;
    if (current == null) return;
    final picked = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (_) => CityPickerScreen(currentCity: current)),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loc_name', picked.name);
    await prefs.setDouble('loc_lat', picked.lat);
    await prefs.setDouble('loc_lon', picked.lon);
    await prefs.setString('loc_region', picked.region);
    await prefs.setString('loc_district', picked.district);
    await prefs.setInt('loc_utc', picked.utcOffset);
    if (picked.timezone != null) {
      await prefs.setString('loc_timezone', picked.timezone!);
    }
    if (!mounted) return;
    setState(() {
      _city = picked;
      _now = DateTime.now();
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  Future<void> _removeCrop(_CropInfo info) async {
    final store = GardenStore.instance;
    final id = cropIdOf(info.crop.name);
    final index = store.cropIds.indexOf(id);
    await store.removeCrop(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _berry,
        duration: const Duration(seconds: 5),
        content: Text('${info.crop.name} убрана из сада'),
        action: SnackBarAction(
          label: 'Вернуть',
          textColor: _sun,
          onPressed: () => store.insertCrop(index < 0 ? 0 : index, id),
        ),
      ),
    );
  }

  void _cropSheet(_CropInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CropIcon(
                      id: cropIdOf(info.crop.name),
                      emoji: info.crop.emoji,
                      size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(info.crop.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            _sheetTile(ctx, Icons.visibility, _leaf, 'Открыть карточку',
                'Луна, календарь, уход и защита', () {
              Navigator.pop(ctx);
              _open(CropDetailScreen(crop: info.crop));
            }),
            _sheetTile(ctx, Icons.edit_note, _sun, 'Запись в дневник',
                'Посадка, урожай, заметка', () {
              Navigator.pop(ctx);
              _open(DiaryEntryScreen(presetCropId: cropIdOf(info.crop.name)));
            }),
            _sheetTile(ctx, Icons.water_drop, _water, 'Отметить полив',
                WateringLog.sinceText(info.lastWater), () {
              Navigator.pop(ctx);
              _waterOne(info);
            }),
            _sheetTile(ctx, Icons.remove_circle_outline, _berry,
                'Убрать из сада', 'Дневник по культуре сохранится', () {
              Navigator.pop(ctx);
              _removeCrop(info);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(BuildContext ctx, IconData icon, Color color, String title,
      String sub, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle:
            Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _waterOne(_CropInfo info) async {
    final prev = info.lastWater;
    final now = DateTime.now();
    setState(() {
      _waterMap[info.care.key] = now;
    });
    await WateringLog.mark(info.care.key, now);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _leaf,
        content: Text('💧 ${info.crop.name}: полив отмечен'),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: _moonGold,
          onPressed: () async {
            if (prev == null) {
              await WateringLog.clear(info.care.key);
            } else {
              await WateringLog.mark(info.care.key, prev);
            }
            if (!mounted) return;
            setState(() {
              _waterMap[info.care.key] = prev;
            });
          },
        ),
      ),
    );
  }

  Future<void> _waterAll(List<_CropInfo> targets) async {
    if (targets.isEmpty) return;
    final prev = {for (final t in targets) t.care.key: t.lastWater};
    final now = DateTime.now();
    setState(() {
      for (final t in targets) {
        _waterMap[t.care.key] = now;
      }
    });
    for (final t in targets) {
      await WateringLog.mark(t.care.key, now);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _leaf,
        content: Text('💧 Отмечен полив: ${targets.length} культур'),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: _moonGold,
          onPressed: () async {
            for (final entry in prev.entries) {
              if (entry.value == null) {
                await WateringLog.clear(entry.key);
              } else {
                await WateringLog.mark(entry.key, entry.value!);
              }
            }
            if (!mounted) return;
            setState(() {
              _waterMap.addAll(prev);
            });
          },
        ),
      ),
    );
  }

  List<_CropInfo> _buildInfos(MoonInfo moon) {
    final store = GardenStore.instance;
    final list = <_CropInfo>[];
    for (final crop in store.crops) {
      final care = CropCareRepository.forCrop(crop.name);
      final last = _waterMap[care.key];
      final tracked = last != null;
      final due = WateringLog.isDue(last, care.waterEveryDays);
      final isRoot = MoonUtils.isRootCrop(crop.name);
      final favorable = !moon.isNewOrFull &&
          ((moon.isWaxing && !isRoot) || (!moon.isWaxing && isRoot));

      final cal = PlantingCalendarUtils.forCrop(crop.name);
      String windowText = 'Календарь уточняется';
      bool windowActive = false;
      int urgency = 9999;
      if (cal != null) {
        final st = PlantingCalendarUtils.getStatus(cal, _now);
        if (st.active.isNotEmpty) {
          windowActive = true;
          windowText = 'Сейчас: ${st.active.first.title}';
          urgency = 0;
        } else if (st.next != null) {
          windowText =
              '${st.next!.title} через ${st.daysUntilNext} ${WorkAgenda.daysWord(st.daysUntilNext)}';
          urgency = st.daysUntilNext;
        }
      }

      list.add(_CropInfo(
        crop: crop,
        care: care,
        lastWater: last,
        tracked: tracked,
        due: due,
        favorable: favorable,
        windowText: windowText,
        windowActive: windowActive,
        urgency: urgency,
        diaryCount:
            store.query(cropId: cropIdOf(crop.name), year: store.season).length,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _city == null) {
      return Scaffold(
        backgroundColor: _night,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MoonVisual(ageDays: 1.9, size: 110),
              const SizedBox(height: 18),
              const Text('СадовникPRO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Готовим ваш сад…',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final city = _city!;
    final store = GardenStore.instance;
    final moon = MoonUtils.getMoonInfo(_now);
    final times = MoonUtils.getMoonTimesForCoords(
        _now, city.lat, city.lon, city.utcOffset);
    final infos = _buildInfos(moon);
    final stats = store.statsFor(store.season);

    final attention = infos.where((i) => i.due).toList();
    final activeNow = infos.where((i) => i.windowActive).length;
    final agenda = WorkAgenda.build(_now);
    final next = agenda.isEmpty ? null : agenda.first;

    var visible = infos.where((i) {
      if (_query.isNotEmpty && !i.crop.name.toLowerCase().contains(_query))
        return false;
      if (_filter == 1) return i.due;
      if (_filter == 2) return i.favorable;
      return true;
    }).toList();

    if (_sortUrgency) {
      visible.sort((a, b) {
        final wa = (a.due) ? 0 : 1;
        final wb = (b.due) ? 0 : 1;
        if (wa != wb) return wa.compareTo(wb);
        return a.urgency.compareTo(b.urgency);
      });
    }

    final gardenEmpty = infos.isEmpty;

    return Scaffold(
      backgroundColor: _cream,
      floatingActionButton: gardenEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _leaf,
              foregroundColor: Colors.white,
              onPressed: () => _open(AddCropScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Добавить культуру',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: RefreshIndicator(
        color: _leaf,
        backgroundColor: Colors.white,
        onRefresh: _load,
        child: Scrollbar(
          controller: _scroll,
          thickness: 6,
          radius: const Radius.circular(3),
          thumbVisibility: true,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: _night,
                foregroundColor: Colors.white,
                titleSpacing: 12,
                title: const Flexible(
                  child: Text(
                    'СадовникPRO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Дневник',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(DiaryScreen()),
                    icon:
                        const Icon(Icons.menu_book, color: _moonGold, size: 21),
                  ),
                  IconButton(
                    tooltip: 'Мой сад',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(AddCropScreen()),
                    icon: const Icon(Icons.yard, color: _sprout, size: 21),
                  ),
                  IconButton(
                    tooltip: 'Напоминания',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(RemindersScreen()),
                    icon: Badge(
                      isLabelVisible: _notifEnabled,
                      backgroundColor: _sprout,
                      label: Text('$_notifCount',
                          style: const TextStyle(fontSize: 9)),
                      child: Icon(
                        _notifEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: _notifEnabled ? _moonGold : Colors.white70,
                        size: 21,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Экспорт',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(ExportScreen()), // Убран const
                    icon: const Icon(Icons.file_download_outlined,
                        color: Colors.white70, size: 21),
                  ),
                  IconButton(
                    tooltip: 'Севооборот',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(RotationScreen()), // Убран const
                    icon: const Icon(Icons.swap_horiz,
                        color: Colors.white70, size: 21),
                  ),
                  IconButton(
                    tooltip: 'О приложении',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _open(AboutScreen()),
                    icon: const Icon(Icons.info_outline,
                        color: Colors.white70, size: 21),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_night, _night2, Color(0xFF243B55)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _moonInfo(city, moon, times),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoonVisual(
                                  ageDays: moon.ageDays, size: 85, glow: true),
                              const SizedBox(height: 8),
                              WeatherWidget(
                                  data: _weather,
                                  latitude: city.lat,
                                  longitude: city.lon),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _stat(
                          icon: Icons.event_available,
                          color: _leaf,
                          value: activeNow > 0 ? '$activeNow' : '—',
                          label: 'окон открыто',
                          onTap: () => _open(RemindersScreen())),
                      const SizedBox(width: 10),
                      _stat(
                          icon: Icons.water_drop,
                          color: _water,
                          value: '${attention.length}',
                          label: 'требуют полива',
                          onTap: () => setState(() => _filter = 1)),
                      const SizedBox(width: 10),
                      _stat(
                          icon: Icons.menu_book,
                          color: _sun,
                          value: '${stats.plantings + stats.harvests}',
                          label: 'записей в дневнике',
                          onTap: () => _open(DiaryScreen())),
                    ],
                  ),
                ),
              ),
              if (attention.isNotEmpty)
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver:
                        SliverToBoxAdapter(child: _attentionCard(attention))),
              if (next != null)
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(child: _nextWorkCard(next))),
              if (gardenEmpty)
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                    sliver: SliverToBoxAdapter(child: _emptyGarden()))
              else ...[
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver:
                        SliverToBoxAdapter(child: _gardenHeader(infos.length))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _searchBar())),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        _chip(0, 'Все (${infos.length})'),
                        const SizedBox(width: 8),
                        _chip(1, '💧 Полить'),
                        const SizedBox(width: 8),
                        _chip(2, '🌙 Благоприятно'),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              setState(() => _sortUrgency = !_sortUrgency),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _sortUrgency
                                  ? _leaf.withValues(alpha: 0.14)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _sortUrgency
                                      ? _leaf
                                      : Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.sort,
                                size: 18,
                                color: _sortUrgency ? _leaf : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      _sortUrgency
                          ? 'Сначала срочные • ${visible.length} • свайп влево убирает культуру'
                          : 'Ваш порядок • ${visible.length} • свайп влево убирает культуру',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      sliver: SliverToBoxAdapter(child: _noResults()))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final info = visible[i];
                          return Dismissible(
                            key: ValueKey(cropIdOf(info.crop.name)),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeCrop(info),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 11),
                              decoration: BoxDecoration(
                                  color: _berry,
                                  borderRadius: BorderRadius.circular(16)),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 22),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Убрать из сада',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete_outline,
                                      color: Colors.white)
                                ],
                              ),
                            ),
                            child: _cropCard(info),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _moonInfo(City city, MoonInfo moon, MoonTimes times) {
    final dateText =
        '${_weekdays[_now.weekday - 1]}, ${_now.day} ${_monthsGen[_now.month - 1]}';
    final rise = MoonUtils.formatCityTime(times.rise, city.utcOffset);
    final set = MoonUtils.formatCityTime(times.set, city.utcOffset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateText.toUpperCase(),
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
                color: _moonGold.withValues(alpha: 0.9))),
        const SizedBox(height: 8),
        Text('${moon.lunarDay}-й лунный день',
            style: const TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        Text(
            '${moon.phaseName} • ${moon.illumination}% • ${moon.ageDays.toStringAsFixed(1)} дн.',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.78))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _heroChip(Icons.north_east, 'Восход $rise'),
          _heroChip(Icons.south_east, 'Заход $set')
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickCity,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: _sprout.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _sprout.withValues(alpha: 0.45))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 15, color: _sprout),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(city.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white))),
                const SizedBox(width: 5),
                Icon(Icons.edit,
                    size: 12, color: Colors.white.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_regionProfile != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
              _climateZone != null
                  ? '${_regionProfile!.name} • ${_climateZone!.name}'
                  : _regionProfile!.name,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _gardenHeader(int count) {
    final store = GardenStore.instance;
    return Row(
      children: [
        const Icon(Icons.yard, color: _leaf, size: 21),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Мой сад • $count',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: _leaf.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text('сезон ${store.season}',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: _leaf)),
        ),
        TextButton(
            onPressed: () => _open(AddCropScreen(initialTab: 1)),
            child: const Text('Управлять', style: TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _emptyGarden() {
    final store = GardenStore.instance;
    final suggestions = store.suggestions;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _leaf.withValues(alpha: 0.12),
              _sprout.withValues(alpha: 0.05)
            ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _leaf.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('Соберите свой сад',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Добавьте только те культуры, что реально посадили в этом году. Приложение будет считать полив, окна посадки и напоминания именно по ним.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: Colors.grey[700], height: 1.5)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _open(AddCropScreen()),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Добавить культуру',
                  style:
                      TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _leaf,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('ИЛИ БЫСТРО ДОБАВЬТЕ ПОПУЛЯРНОЕ',
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((c) {
                return InkWell(
                  onTap: () async {
                    await store.addCrop(c.name);
                    await _load();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _leaf.withValues(alpha: 0.35))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CropIcon(
                            id: cropIdOf(c.name), emoji: c.emoji, size: 16),
                        const SizedBox(width: 7),
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.add, size: 15, color: _leaf),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noResults() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Icon(Icons.search_off,
              size: 46, color: _leaf.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
              _filter == 1
                  ? 'Все культуры политы или ещё не добавлены в сад.\nОтмечайте полив каплей на карточке.'
                  : 'Ничего не найдено. Измените запрос или фильтр.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], height: 1.5)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => setState(() {
                    _filter = 0;
                    _query = '';
                    _search.clear();
                  }),
              child: const Text('Показать весь сад')),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _moonGold),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))
      ]),
    );
  }

  Widget _stat(
      {required IconData icon,
      required Color color,
      required String value,
      required String label,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Colors.grey[600]))
          ]),
        ),
      ),
    );
  }

  Widget _attentionCard(List<_CropInfo> items) {
    final names = items.take(3).map((e) => e.crop.name).join(', ');
    final more = items.length > 3 ? ' и ещё ${items.length - 3}' : '';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _sun.withValues(alpha: 0.18),
                const Color(0xFFEF6C00).withValues(alpha: 0.08)
              ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sun.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF6C00), size: 22),
            SizedBox(width: 8),
            Text('Пора полить',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 6),
          Text('$names$more',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[800], height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
                onPressed: () => _waterAll(items),
                icon: const Icon(Icons.done_all, size: 19),
                label: Text('Отметить полив всех (${items.length})'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _water,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)))),
          ),
        ],
      ),
    );
  }

  Widget _nextWorkCard(WorkItem next) {
    return InkWell(
      onTap: () => _open(RemindersScreen()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _leaf.withValues(alpha: 0.14),
                  _sprout.withValues(alpha: 0.05)
                ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _leaf.withValues(alpha: 0.32))),
        child: Row(
          children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: _leaf, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.eco, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ближайшая работа',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(
                      next.isActive
                          ? 'Сейчас: ${next.cropName} — ${next.stage.title}'
                          : '${next.cropName}: ${next.stage.title} через ${next.daysUntil} ${WorkAgenda.daysWord(next.daysUntil)}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[700],
                          height: 1.35))
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 15, color: _leaf),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
          hintText: 'Поиск в моём саду…',
          prefixIcon: const Icon(Icons.search, color: _leaf),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.withValues(alpha: 0.25))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _leaf, width: 1.6)),
          suffixIcon: _search.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  })
              : null),
    );
  }

  Widget _chip(int value, String label) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
              color: selected ? _leaf : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      selected ? _leaf : Colors.grey.withValues(alpha: 0.3))),
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.grey[700])),
        ),
      ),
    );
  }

  Widget _cropCard(_CropInfo info) {
    final accent = info.windowActive
        ? _leaf
        : (info.favorable ? _sprout : const Color(0xFF90A4AE));
    final waterLabel = !info.tracked
        ? 'Полив не отмечен'
        : (info.due ? 'Пора полить' : WateringLog.sinceText(info.lastWater));
    final waterColor =
        !info.tracked ? _sun : (info.due ? const Color(0xFFEF6C00) : _water);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(CropDetailScreen(crop: info.crop)),
          onLongPress: () => _cropSheet(info),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.20),
                            accent.withValues(alpha: 0.06)
                          ]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.3))),
                  child: Center(
                      child: CropIcon(
                          id: cropIdOf(info.crop.name),
                          emoji: info.crop.emoji,
                          size: 27)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(info.crop.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))),
                          if (info.windowActive)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _leaf,
                                    borderRadius: BorderRadius.circular(7)),
                                child: const Text('СЕЗОН',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 5, children: [
                        _miniChip(Icons.water_drop, waterLabel, waterColor),
                        _miniChip(
                            info.favorable
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            info.favorable
                                ? 'Луна благоволит'
                                : 'Луна нейтральна',
                            info.favorable ? _leaf : Colors.grey),
                        if (info.diaryCount > 0)
                          _miniChip(Icons.menu_book,
                              '${info.diaryCount} в дневнике', _sun)
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.event, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Text(info.windowText,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[600],
                                    height: 1.3)))
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  children: [
                    InkWell(
                        onTap: () => _waterOne(info),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: _water.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: _water.withValues(alpha: 0.35))),
                            child: const Icon(Icons.water_drop,
                                size: 18, color: _water))),
                    const SizedBox(height: 6),
                    InkWell(
                        onTap: () => _open(DiaryEntryScreen(
                            presetCropId: cropIdOf(info.crop.name))),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: _sun.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: _sun.withValues(alpha: 0.4))),
                            child: const Icon(Icons.edit_note,
                                size: 19, color: Color(0xFFB37F00)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: color))
      ]),
    );
  }
}
