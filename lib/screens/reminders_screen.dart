import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/user_reminder.dart';
import '../services/reminder_service.dart';
import '../utils/notification_service.dart';
import '../widgets/add_reminder_sheet.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _enabled = false;
  bool _busy = false;
  bool _exactGranted = true;
  List<UserReminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final exact = await NotificationService.canScheduleExact();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool('notifications_enabled') ?? false;
      _exactGranted = exact;
      _reminders = ReminderService.instance.reminders;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);

    if (value) {
      // 1. Обычное разрешение на уведомления (Android 13+)
      final notifGranted = await NotificationService.requestPermission();
      if (!notifGranted) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Разрешите уведомления: Настройки → Приложения → СадовникPRO → Уведомления.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // 2. Разрешение на точные уведомления (Android 12+)
      if (!_exactGranted) {
        await NotificationService.requestExactPermission();
        _exactGranted = await NotificationService.canScheduleExact();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
      await NotificationService.rescheduleAll();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      await NotificationService.cancelAll();
    }

    if (!mounted) return;
    setState(() {
      _enabled = value;
      _busy = false;
    });
  }

  Future<void> _requestExact() async {
    await NotificationService.requestExactPermission();
    final granted = await NotificationService.canScheduleExact();
    if (!mounted) return;
    setState(() => _exactGranted = granted);
    if (granted) {
      await NotificationService.rescheduleAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text('✅ Точные уведомления включены'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Разрешение не выдано. Уведомления будут приходить в течение часа.'),
        ),
      );
    }
  }

  Future<void> _add() async {
    await showAddReminderSheet(context);
    _load();
  }

  Future<void> _showRecommendation(UserReminder r) async {
    final text = await ReminderService.instance.recommendation(r);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r.cropEmoji} ${r.cropName}'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              value: _enabled,
              onChanged: _busy ? null : _toggle,
              title: const Text('Напоминания о посадках'),
              subtitle: Text(
                _exactGranted
                    ? 'Уведомление приходит точно в 9:00'
                    : 'Уведомление приходит в течение часа после 9:00',
              ),
            ),
          ),
          // ✅ Карточка точных уведомлений (только если не разрешено)
          if (!_exactGranted) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.alarm, color: Colors.orange, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Точные напоминания выключены',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Без разрешения уведомление может прийти на 1–2 часа позже. '
                      'Разрешите «Будильники и напоминания», чтобы получать '
                      'сигнал ровно в 9:00.',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _requestExact,
                        icon: const Icon(Icons.alarm_on, size: 18),
                        label: const Text('Разрешить точные напоминания'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Пока нет напоминаний.\nНажмите «Добавить», чтобы создать.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            )
          else
            ..._reminders.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading:
                      Text(r.cropEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text('${r.cropName}: ${r.title}'),
                  subtitle: Text(
                    '${r.targetDate.day}.${r.targetDate.month}.${r.targetDate.year} в 9:00',
                  ),
                  onTap: () => _showRecommendation(r),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: r.isActive,
                        onChanged: (v) async {
                          await ReminderService.instance.toggle(r.id, v);
                          await NotificationService.rescheduleAll();
                          _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ReminderService.instance.remove(r.id);
                          await NotificationService.rescheduleAll();
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
