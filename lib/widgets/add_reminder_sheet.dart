import 'package:flutter/material.dart';

import '../data/user_reminder.dart';
import '../services/reminder_service.dart';
import '../utils/notification_service.dart';

/// Универсальный лист создания напоминания.
/// Можно вызывать из карточки культуры, из экрана напоминаний или откуда угодно.
Future<void> showAddReminderSheet(
  BuildContext context, {
  String? initialCropName,
  String? initialCropEmoji,
  ReminderType? initialType,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddReminderSheet(
      initialCropName: initialCropName,
      initialCropEmoji: initialCropEmoji,
      initialType: initialType,
    ),
  );
}

class AddReminderSheet extends StatefulWidget {
  final String? initialCropName;
  final String? initialCropEmoji;
  final ReminderType? initialType;

  const AddReminderSheet({
    super.key,
    this.initialCropName,
    this.initialCropEmoji,
    this.initialType,
  });

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  late final TextEditingController _nameCtrl;
  late ReminderType _type;
  DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialCropName ?? '');
    _type = widget.initialType ?? ReminderType.custom;
    _date = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Когда напомнить?',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _date == null) return;

    setState(() => _saving = true);

    final reminder = UserReminder(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      cropName: name,
      cropEmoji: widget.initialCropEmoji ?? '🌱',
      type: _type,
      targetDate: _date!,
      customNote: _type == ReminderType.custom
          ? (name.isEmpty ? 'Напоминание' : null)
          : null,
    );

    await ReminderService.instance.add(reminder);
    await NotificationService.rescheduleAll();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F5EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Новое напоминание',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Культура',
                    hintText: 'Например, Помидоры',
                    prefixIcon: Icon(Icons.eco),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Тип напоминания',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReminderType.values.map((t) {
                    final selected = _type == t;
                    return ChoiceChip(
                      label: Text(_labelFor(t)),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _date == null
                                ? 'Выберите дату'
                                : '${_date!.day}.${_date!.month}.${_date!.year}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Сохранить напоминание'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(ReminderType t) {
    switch (t) {
      case ReminderType.sowSeedling:
        return 'Рассада';
      case ReminderType.transplant:
        return 'В грунт';
      case ReminderType.water:
        return 'Полив';
      case ReminderType.harvest:
        return 'Урожай';
      case ReminderType.custom:
        return 'Другое';
    }
  }
}
