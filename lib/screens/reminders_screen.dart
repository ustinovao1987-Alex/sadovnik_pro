import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/planting_calendar.dart';
import '../data/work_agenda.dart';
import '../utils/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _enabled = false;
  bool _busy = false;
  int _scheduled = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool('notifications_enabled') ?? false;
      _scheduled = prefs.getInt('notifications_count') ?? 0;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _busy = true;
    });
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Разрешите уведомления: Настройки → Приложения → СадовникPRO → Уведомления.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      await prefs.setBool('notifications_enabled', true);
      final n = await NotificationService.rescheduleAll();
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _scheduled = n;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔔 Запланировано напоминаний: $n')),
      );
    } else {
      await prefs.setBool('notifications_enabled', false);
      await NotificationService.cancelAll();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _scheduled = 0;
        _busy = false;
      });
    }
  }

  Future<void> _testNow() async {
    await NotificationService.showTest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Тестовое уведомление отправлено — проверьте шторку.')),
    );
  }

  Future<void> _testScheduled() async {
    await NotificationService.scheduleTest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Тест по расписанию: уведомление придёт примерно через минуту.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = WorkAgenda.build(now);
    final active = items.where((i) => i.isActive).toList();
    final upcoming = items.where((i) => !i.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ближайшие работы'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _enabled,
                  onChanged: _busy ? null : _toggle,
                  title: const Text(
                    'Напоминания о посадках',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _busy
                        ? 'Подождите…'
                        : _enabled
                            ? 'Включены • запланировано: $_scheduled'
                            : 'Выключены — нажмите, чтобы включить',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  secondary: _busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active,
                          color: Colors.green),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testNow,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Тест сейчас'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testScheduled,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Тест через 1 мин'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Календарь работ • $kRegionName',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Ориентиры: последние весенние заморозки ~$kLastSpringFrost, '
            'первые осенние ~$kFirstAutumnFrost.',
            style:
                TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 16),
          if (active.isNotEmpty) ...[
            _sectionHeader('🟢 СЕЙЧАС В РАБОТЕ'),
            ...active.map(_card),
            const SizedBox(height: 12),
          ],
          _sectionHeader('🗓️ БЛИЖАЙШИЕ ОКНА'),
          ...upcoming.map(_card),
          const SizedBox(height: 12),
          Text(
            'Сроки ориентировочные и могут сдвигаться на 1–2 недели — '
            'следите за прогнозом погоды и температурой почвы. '
            'Напоминания приходят за 3 дня до окна и в день его открытия.',
            style:
                TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card(WorkItem item) {
    final s = item.stage;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            item.isActive ? Colors.green.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isActive
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            s.isPlanting ? Icons.eco : Icons.shopping_basket,
            size: 26,
            color: item.isActive ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.cropName} — ${s.title}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  s.rangeText + (s.note.isNotEmpty ? ' • ${s.note}' : ''),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: item.isActive
                  ? Colors.green
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.isActive
                  ? 'СЕЙЧАС'
                  : 'через ${item.daysUntil} ${WorkAgenda.daysWord(item.daysUntil)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item.isActive ? Colors.white : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
