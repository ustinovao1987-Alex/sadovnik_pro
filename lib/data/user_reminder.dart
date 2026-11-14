import 'package:flutter/material.dart';

/// Тип напоминания. Определяет иконку, заголовок и смысл.
enum ReminderType { sowSeedling, transplant, water, harvest, custom }

class UserReminder {
  final String id;
  final String cropName;
  final String cropEmoji;
  final ReminderType type;
  final DateTime targetDate;
  final bool isActive;
  final String? customNote;

  const UserReminder({
    required this.id,
    required this.cropName,
    required this.cropEmoji,
    required this.type,
    required this.targetDate,
    this.isActive = true,
    this.customNote,
  });

  UserReminder copyWith({
    String? id,
    String? cropName,
    String? cropEmoji,
    ReminderType? type,
    DateTime? targetDate,
    bool? isActive,
    String? customNote,
  }) {
    return UserReminder(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      cropEmoji: cropEmoji ?? this.cropEmoji,
      type: type ?? this.type,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
      customNote: customNote ?? this.customNote,
    );
  }

  String get title {
    switch (type) {
      case ReminderType.sowSeedling:
        return 'Посев на рассаду';
      case ReminderType.transplant:
        return 'Высадка в грунт';
      case ReminderType.water:
        return 'Полив';
      case ReminderType.harvest:
        return 'Сбор урожая';
      case ReminderType.custom:
        return customNote ?? 'Напоминание';
    }
  }

  IconData get icon {
    switch (type) {
      case ReminderType.sowSeedling:
        return Icons.spa;
      case ReminderType.transplant:
        return Icons.yard;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.harvest:
        return Icons.agriculture;
      case ReminderType.custom:
        return Icons.notifications;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'cropEmoji': cropEmoji,
        'type': type.index,
        'targetDate': targetDate.millisecondsSinceEpoch,
        'isActive': isActive,
        'customNote': customNote,
      };

  static UserReminder? fromJson(Map<String, dynamic> json) {
    try {
      return UserReminder(
        id: json['id'] as String,
        cropName: (json['cropName'] as String?) ?? 'Культура',
        cropEmoji: (json['cropEmoji'] as String?) ?? '🌱',
        type: ReminderType.values[(json['type'] as num?)?.toInt() ?? 4],
        targetDate: DateTime.fromMillisecondsSinceEpoch(
            (json['targetDate'] as num).toInt()),
        isActive: (json['isActive'] as bool?) ?? true,
        customNote: json['customNote'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
