import 'package:flutter/material.dart';
import '../data/cities.dart';
import '../utils/location_service.dart';

class CityPickerScreen extends StatefulWidget {
  final City currentCity;

  const CityPickerScreen({super.key, required this.currentCity});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final TextEditingController _controller = TextEditingController();

  List<City> _allCities = const [];
  List<City> _results = const [];
  bool _isLoading = true;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cities = await CityRepository.instance.loadCities();
      if (!mounted) return;

      setState(() {
        _allCities = cities;
        _results = cities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки городов: $e')),
      );
    }
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = _normalize(query.trim());

    if (normalizedQuery.isEmpty) {
      setState(() {
        _results = _allCities;
      });
      return;
    }

    final startsWith = _allCities
        .where((c) => _normalize(c.name).startsWith(normalizedQuery))
        .toList();

    final contains = _allCities
        .where((c) =>
            !_normalize(c.name).startsWith(normalizedQuery) &&
            _normalize(c.name).contains(normalizedQuery))
        .toList();

    setState(() {
      _results = [...startsWith, ...contains];
    });
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll('ё', 'е');
  }

  // 🌍 УЛУЧШЕНО: без showDialog. Прогресс — на кнопке и в плашке под ней.
  // Навигация — ровно ОДИН Navigator.pop после получения города.
  Future<void> _detectCurrentCity() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    City? detectedCity;
    String? errorMessage;

    try {
      detectedCity = await LocationService.getCurrentCity()
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      final s = e.toString();
      if (s.contains('TimeoutException')) {
        errorMessage =
            'GPS не ответил за 20 секунд. Выйдите на открытое место или '
            'выберите город вручную из списка ниже.';
      } else {
        errorMessage = 'Ошибка геолокации: $s';
      }
    } catch (e) {
      errorMessage = 'Ошибка: $e';
    }

    if (!mounted) return;

    setState(() => _isLocating = false);

    if (detectedCity != null) {
      // ✅ РОВНО ОДИН pop — возвращаемся на главный экран с новым городом.
      Navigator.pop(context, detectedCity);
      return;
    }

    // Не смогли — оранжевый SnackBar, остаёмся на экране выбора
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage ??
              'Не удалось определить местоположение. Проверьте интернет, '
                  'GPS и разрешение «Местоположение» в настройках.',
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.orange.shade800,
        action: SnackBarAction(
          label: 'ОК',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите город'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          // 🔘 БОЛЬШАЯ КНОПКА АВТООПРЕДЕЛЕНИЯ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _detectCurrentCity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  disabledBackgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                icon: _isLocating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location, size: 28),
                label: Text(
                  _isLocating
                      ? 'Ищем спутники…'
                      : 'Найти мой город автоматически',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // ✅ Плашка «Ищем спутники…» — показывается ТОЛЬКО когда идёт поиск.
          // Никакого диалога — просто строка под кнопкой.
          if (_isLocating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Определяем местоположение… Это может занять до 20 секунд. '
                        'Для точности выйдите на открытое место.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Поисковая строка
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Или начните вводить название...',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, size: 28),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Список результатов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Ничего не найдено.\n\nПопробуйте написать короче,\nнапример: "Сам", "Толь", "Кинель".',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                height: 1.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final city = _results[index];
                          final isCurrent =
                              city.name == widget.currentCity.name;

                          final parts = <String>[city.region];
                          if (city.district.isNotEmpty) {
                            parts.add(city.district);
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              leading: Icon(Icons.location_city,
                                  size: 30,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(city.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(parts.join(' • '),
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600])),
                              trailing: isCurrent
                                  ? Icon(Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary)
                                  : Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey[400]),
                              onTap: () {
                                Navigator.pop(context, city);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
