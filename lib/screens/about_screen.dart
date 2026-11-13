import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _cream = Color(0xFFF7F5EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _leaf,
        foregroundColor: Colors.white,
        title: const Text('О приложении'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 16),
          _card(
            icon: Icons.science,
            title: 'Лунный календарь',
            color: Colors.indigo,
            child: const Text(
              'Расчёт фаз Луны, восхода и захода выполнен по астрономической '
              'теории Мееуса. Точность ±1–2 минуты для ваших координат.\n\n'
              'Лунные рекомендации по посадкам — народная традиция. '
              'Погода и сроки посадки всегда важнее лунной фазы.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            icon: Icons.cloud,
            title: 'Погода и климат',
            color: Colors.blue,
            child: const Text(
              'Данные о погоде предоставлены сервисами:\n'
              '• Open-Meteo.com (лицензия CC BY 4.0)\n'
              '• Gismeteo (при наличии вашего API-ключа)\n\n'
              'Прогноз является расчётным. Для критических решений '
              'сверяйтесь с официальными данными Росгидромета.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            icon: Icons.water_drop,
            title: 'Модель полива',
            color: Colors.teal,
            child: const Text(
              'Расчёт норм полива выполнен по методике FAO-56 '
              '(испаряемость Пенмана-Монтейта, коэффициент культуры, '
              'температура почвы).\n\n'
              'Значения являются расчётной оценкой. '
              'Для точного управления используйте датчик влажности почвы.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            icon: Icons.eco,
            title: 'Агрономические данные',
            color: _leaf,
            child: const Text(
              'Календари посадки, сроки, глубина заделки и пороги температуры '
              'взяты из общедоступных агрономических справочников.\n\n'
              'Перед применением сверяйтесь с местными условиями: климат, '
              'тип почвы, микроклимат участка могут влиять на сроки.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'СадовникPRO • версия 1.0.0\nСделано с ❤️ для дачников',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_leaf, Color(0xFF3E8E43), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Column(
        children: [
          Text('🌱', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('СадовникPRO',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 6),
          Text('Умный помощник для дачников',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
