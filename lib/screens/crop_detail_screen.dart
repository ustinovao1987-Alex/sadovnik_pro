import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cities.dart';
import '../data/crop_care_data.dart';
import '../data/crops_data.dart';
import '../data/planting_calendar.dart';
import '../utils/moon_utils.dart';
import '../widgets/add_reminder_sheet.dart';
import 'care_screen.dart';
import 'city_picker_screen.dart';
import 'problems_screen.dart';
import 'reminders_screen.dart';
import '../data/climate_engine.dart';

class CropDetailScreen extends StatefulWidget {
  final Crop crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  City? _city;
  bool _isLoading = true;
  DateTime? _lastWater;
  bool _notifEnabled = false;
  int _notifCount = 0;
  late final CropCare _care;

  @override
  void initState() {
    super.initState();
    _care = CropCareRepository.forCrop(widget.crop.name);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await CityRepository.instance.loadCities();

    final savedLat = prefs.getDouble('loc_lat');
    final savedLon = prefs.getDouble('loc_lon');
    final savedName = prefs.getString('loc_name');

    City resolved;
    if (savedLat != null && savedLon != null && savedName != null) {
      resolved = City(
        name: savedName,
        region: prefs.getString('loc_region') ?? '',
        district: prefs.getString('loc_district') ?? '',
        lat: savedLat,
        lon: savedLon,
        utcOffset: prefs.getInt('loc_utc') ?? 4,
      );
    } else {
      final legacyName = prefs.getString('selected_city');
      resolved = CityRepository.instance.findByName(legacyName) ??
          CityRepository.instance.defaultCity;
    }

    final lastWater = await WateringLog.last(_care.key);
    if (!mounted) return;
    setState(() {
      _city = resolved;
      _lastWater = lastWater;
      _notifEnabled = prefs.getBool('notifications_enabled') ?? false;
      _notifCount = prefs.getInt('notifications_count') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _refreshLive() async {
    final prefs = await SharedPreferences.getInstance();
    final lastWater = await WateringLog.last(_care.key);
    if (!mounted) return;
    setState(() {
      _lastWater = lastWater;
      _notifEnabled = prefs.getBool('notifications_enabled') ?? false;
      _notifCount = prefs.getInt('notifications_count') ?? 0;
    });
  }

  Future<void> _saveCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loc_name', city.name);
    await prefs.setDouble('loc_lat', city.lat);
    await prefs.setDouble('loc_lon', city.lon);
    await prefs.setString('loc_region', city.region);
    await prefs.setString('loc_district', city.district);
    await prefs.setInt('loc_utc', city.utcOffset);
  }

  Future<void> _pickCity() async {
    final current = _city;
    if (current == null) return;
    final picked = await Navigator.push<City>(
      context,
      MaterialPageRoute(
        builder: (context) => CityPickerScreen(currentCity: current),
      ),
    );
    if (picked == null) return;
    await _saveCity(picked);
    if (!mounted) return;
    setState(() {
      _city = picked;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _refreshLive();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _city == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.crop.name),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final city = _city!;
    final now = DateTime.now();
    final moon = MoonUtils.getMoonInfo(now);
    final times = MoonUtils.getMoonTimesForCoords(
        now, city.lat, city.lon, city.utcOffset);
    final isRoot = MoonUtils.isRootCrop(widget.crop.name);
    final isFavorable = !moon.isNewOrFull &&
        ((moon.isWaxing && !isRoot) || (!moon.isWaxing && isRoot));
    final advice = MoonUtils.getPlantingAdvice(widget.crop.name, moon);

    final cal = PlantingCalendarUtils.forCrop(widget.crop.name);
    final calStatus =
        cal == null ? null : PlantingCalendarUtils.getStatus(cal, now);
    final calendarAdvice = PlantingCalendarUtils.buildAdvice(
      cal: cal,
      status: calStatus,
      isWaxing: moon.isWaxing,
      isNewOrFull: moon.isNewOrFull,
      isRoot: isRoot,
    );

    String riseSetText;
    if (times.rise == null && times.set == null) {
      final up = MoonUtils.altitudeAt(now, city.lat, city.lon) > 0;
      riseSetText = up ? 'Луна не заходит сегодня' : 'Луна не всходит сегодня';
    } else {
      riseSetText =
          'Восход: ${MoonUtils.formatCityTime(times.rise, city.utcOffset)}   •   '
          'Заход: ${MoonUtils.formatCityTime(times.set, city.utcOffset)}';
    }

    final diseases =
        _care.problems.where((p) => p.kind == ProblemKind.disease).length;
    final pests =
        _care.problems.where((p) => p.kind == ProblemKind.pest).length;
    final waterDue = WateringLog.isDue(_lastWater, _care.waterEveryDays);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crop.name),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(widget.crop.emoji,
                    style: const TextStyle(fontSize: 110))),
            const SizedBox(height: 16),
            Text(widget.crop.name,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Основная информация',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Text(widget.crop.description,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🌙 Лунная карточка
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFavorable
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isFavorable
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(moon.phaseEmoji, style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${moon.lunarDay}-й лунный день',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                                '${moon.phaseName} • ${moon.illumination}% • возраст ${moon.ageDays.toStringAsFixed(1)} дн.',
                                style: TextStyle(
                                    fontSize: 13.5, color: Colors.grey[700])),
                          ]),
                    ),
                  ]),
                  const Divider(height: 24),
                  Row(children: [
                    const Icon(Icons.nightlight_round,
                        size: 20, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(riseSetText,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickCity,
                    child: Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('📍 ${city.name}  (нажмите для смены)',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                decoration: TextDecoration.underline)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Координаты: ${city.lat.toStringAsFixed(4)}, ${city.lon.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              isFavorable
                                  ? Icons.check_circle
                                  : Icons.pause_circle_outline,
                              color:
                                  isFavorable ? Colors.green : Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(advice,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4))),
                        ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📅 Климатический календарь
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.blueGrey.withValues(alpha: 0.25)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_month, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Календарь посадок • ${ClimateEngine.currentRegionName()}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(calendarAdvice,
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                    ),
                    if (cal != null) ...[
                      const SizedBox(height: 12),
                      ...cal.stages
                          .map((s) => _buildStageRow(s, s.contains(now))),
                    ],
                    const SizedBox(height: 8),
                    Text(
                        'Ориентиры региона: ${ClimateEngine.currentFrostPeriodText()}. '
                        'Сроки могут сдвигаться на 1–2 недели. '
                        'Лунные подсказки — народная традиция; решают температура почвы и погода.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4)),
                  ]),
            ),
            const SizedBox(height: 20),

            // 🔔 Кнопка «Напомнить о посадке»
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showAddReminderSheet(
                  context,
                  initialCropName: widget.crop.name,
                  initialCropEmoji: widget.crop.emoji,
                ),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Напомнить о посадке'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 💧 Живая карточка ухода
            _navCard(
              icon: Icons.water_drop,
              color: const Color(0xFF1E88E5),
              title: 'Уход и полив',
              subtitle: _lastWater == null
                  ? 'Трекер полива, подкормки, чек-лист'
                  : waterDue
                      ? '💧 Пора полить • ${WateringLog.sinceText(_lastWater)}'
                      : '✅ ${WateringLog.sinceText(_lastWater)}',
              onTap: () => _open(CareScreen(crop: widget.crop)),
            ),
            const SizedBox(height: 12),

            // 🐛 Живая карточка проблем
            _navCard(
              icon: Icons.bug_report,
              color: const Color(0xFFC62828),
              title: 'Болезни и вредители',
              subtitle: _care.problems.isEmpty
                  ? 'Общие правила защиты и профилактики'
                  : 'Болезни: $diseases • Вредители: $pests • лечение и профилактика',
              onTap: () => _open(ProblemsScreen(crop: widget.crop)),
            ),
            const SizedBox(height: 12),

            // 🔔 Живая карточка напоминаний
            _navCard(
              icon: Icons.notifications_active,
              color: const Color(0xFF2E7D32),
              title: 'Напоминания',
              subtitle: _notifEnabled
                  ? 'Включены • запланировано: $_notifCount'
                  : 'Выключены — настройте уведомления',
              onTap: () => _open(const RemindersScreen()),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.grey[700], height: 1.3)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ]),
      ),
    );
  }

  Widget _buildStageRow(PlantingStage s, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(s.isPlanting ? Icons.eco : Icons.shopping_basket,
            size: 20, color: active ? Colors.green : Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600)),
            Text(s.rangeText + (s.note.isNotEmpty ? ' • ${s.note}' : ''),
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
        if (active)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.green, borderRadius: BorderRadius.circular(8)),
            child: const Text('СЕЙЧАС',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}
