import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../screens/weather_detail_screen.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData? data;
  final double latitude;
  final double longitude;

  const WeatherWidget({
    super.key,
    this.data,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, color: Colors.white54, size: 22),
                SizedBox(height: 6),
                Text(
                  'Погода',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'нажмите для\nобновления',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = data!;
    final frostRisk = d.hasFrostRisk;
    final severeFrost = d.hasSevereFrost;
    final offline = d.isFallback;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: offline
                ? Colors.amber.withValues(alpha: 0.5)
                : frostRisk
                    ? (severeFrost
                        ? Colors.red.withValues(alpha: 0.6)
                        : Colors.orange.withValues(alpha: 0.6))
                    : Colors.white.withValues(alpha: 0.2),
            width: (offline || frostRisk) ? 1.5 : 1.0,
          ),
        ),
        // ✅ ГЛАВНАЯ ЗАЩИТА: если содержимое не влезает — уменьшится,
        // а не вызовет RenderFlex overflow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Температура + иконка + (⚠️ если офлайн)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(d.weatherIcon, color: Colors.white70, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${d.currentTemp.round()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  if (offline) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 14),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Почва
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grass, color: Colors.green[300], size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Почва ${d.soilTemp.round()}°',
                    style: TextStyle(
                      color: Colors.green[200],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Плашка "примерные/устаревшие данные"
              if (offline) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.source == 'Сезонные данные'
                        ? 'примерные данные'
                        : 'устаревшие данные',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              // Плашка "заморозки"
              if (frostRisk && !offline) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severeFrost
                        ? Colors.red.withValues(alpha: 0.25)
                        : Colors.orange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ac_unit,
                        color:
                            severeFrost ? Colors.red[300] : Colors.orange[300],
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        severeFrost ? 'Заморозки!' : 'Риск заморозков',
                        style: TextStyle(
                          color: severeFrost
                              ? Colors.red[200]
                              : Colors.orange[200],
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailScreen(
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }
}
