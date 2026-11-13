import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherDetailScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeatherDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _water = Color(0xFF1E88E5);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _frost = Color(0xFF4FC3F7);
  static const Color _danger = Color(0xFFE53935);
  static const Color _cream = Color(0xFFF7F5EF);

  WeatherData? _weather;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    await WeatherService.instance.clearCache();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final weather = await WeatherService.instance.fetchAndUpdate(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );

    if (!mounted) return;

    setState(() {
      _weather = weather;
      _loading = false;
      if (weather == null) {
        _errorMessage =
            'Не удалось загрузить погоду. Проверьте интернет-соединение или попробуйте позже.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _water,
        foregroundColor: Colors.white,
        title: const Text('Погода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: _water),
                  const SizedBox(height: 16),
                  Text('Загружаем прогноз...',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Проверяем доступность серверов',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            )
          : _weather == null
              ? _errorView()
              : _contentView(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Погода недоступна',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Неизвестная ошибка',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _water,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentView() {
    final w = _weather!;

    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_water, Color(0xFF2196F3), _leaf],
                ),
              ),
              child: Column(
                children: [
                  Icon(w.weatherIcon, size: 80, color: Colors.white),
                  const SizedBox(height: 12),
                  Text('${w.currentTemp.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1)),
                  const SizedBox(height: 8),
                  Text(w.weatherDescription,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2), // <-- ИСПРАВЛЕНО ЗДЕСЬ
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Источник: ${w.source}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (w.hasFrostWarning) _frostWarningCard(w),
                if (w.hasHeatWarning) _heatWarningCard(),
                _currentConditionsCard(w),
                const SizedBox(height: 14),
                _soilTemperatureCard(w),
                const SizedBox(height: 14),
                _forecastCard(w),
                const SizedBox(height: 14),
                _infoCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frostWarningCard(WeatherData w) {
    final frostDays =
        w.forecast.where((f) => f.tempMin < 0 && f.daysAhead <= 3).toList();
    final minTemp = frostDays.isNotEmpty
        ? frostDays.map((f) => f.tempMin).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _frost.withValues(alpha: 0.25),
            _water.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _frost.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _frost.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.ac_unit, color: _frost, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❄️ Заморозки в ближайшие дни',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Минимум ${minTemp.toStringAsFixed(0)}°C ночью. '
                  'Укройте теплолюбивые культуры спанбондом.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _danger.withValues(alpha: 0.2),
            _sun.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.thermostat, color: _danger, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 Жара в ближайшие дни',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Увеличьте полив, притените культуры от солнца',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentConditionsCard(WeatherData w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _water.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny, color: _water, size: 22),
              SizedBox(width: 8),
              Text('Текущие условия',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _conditionItem(
                  Icons.opacity,
                  'Влажность',
                  '${w.currentHumidity.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _conditionItem(
                  Icons.air,
                  'Ветер',
                  '${w.windSpeed.toStringAsFixed(0)} км/ч',
                ),
              ),
              Expanded(
                child: _conditionItem(
                  Icons.umbrella,
                  'Осадки',
                  '${(w.precipitation ?? 0).toStringAsFixed(1)} мм',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Обновлено ${_formatTime(w.lastUpdated)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return '${diff.inDays} дн назад';
  }

  Widget _conditionItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: _water.withValues(alpha: 0.7)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _soilTemperatureCard(WeatherData w) {
    final canPlant = w.soilTemp >= 12;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _leaf.withValues(alpha: 0.12),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _leaf.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _leaf.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.thermostat, color: _leaf, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Температура почвы',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('На глубине 6 см',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text('${w.soilTemp.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: _leaf)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canPlant
                  ? _leaf.withValues(alpha: 0.1)
                  : _sun.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  canPlant ? Icons.check_circle : Icons.schedule,
                  color: canPlant ? _leaf : _sun,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    canPlant
                        ? 'Почва прогрелась — можно сажать теплолюбивые культуры'
                        : 'Почва ещё холодная — подождите или используйте теплицу',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastCard(WeatherData w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _water.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: _water, size: 22),
              SizedBox(width: 8),
              Text('Прогноз на 7 дней',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...w.forecast.map((f) => _forecastRow(f)),
        ],
      ),
    );
  }

  Widget _forecastRow(DailyForecast f) {
    final weekdays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    final weekday = weekdays[f.date.weekday % 7];
    final dayMonth = '${f.date.day}/${f.date.month}';
    final isToday = f.daysAhead == 0;
    final isTomorrow = f.daysAhead == 1;

    String dayLabel = '$weekday $dayMonth';
    if (isToday) dayLabel = 'Сегодня';
    if (isTomorrow) dayLabel = 'Завтра';

    final isFrost = f.tempMin < 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isFrost ? _frost.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
          Icon(f.weatherIcon, size: 22, color: _water),
          const SizedBox(width: 10),
          Expanded(
            child: Text(f.weatherDescription,
                style: const TextStyle(fontSize: 12.5)),
          ),
          const SizedBox(width: 8),
          Text('${f.tempMax.toStringAsFixed(0)}°',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('/ ${f.tempMin.toStringAsFixed(0)}°',
              style: TextStyle(
                  fontSize: 12.5,
                  color: isFrost ? _frost : Colors.grey[600],
                  fontWeight: isFrost ? FontWeight.bold : FontWeight.normal)),
          if (f.precipitation > 0.5) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _water.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${f.precipitation.toStringAsFixed(0)} мм',
                  style: const TextStyle(
                      fontSize: 10.5,
                      color: _water,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Данные предоставлены Open-Meteo.com (CC BY 4.0). '
        'Температура почвы измеряется на глубине 6 см — это критический '
        'показатель для посева. Большинство культур требуют +12°C для '
        'прорастания семян. Заморозки до −2°C переносят морковь, лук, '
        'чеснок и капуста. Теплолюбивые культуры (томаты, огурцы, перец) '
        'погибают при 0°C.',
        style: TextStyle(fontSize: 11.5, height: 1.5, color: Colors.grey),
      ),
    );
  }
}
