import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'garden_store.dart';

class DiaryExporter {
  static String generateCSV(
      {required int year, required List<DiaryEntry> entries}) {
    final buffer = StringBuffer();
    buffer.writeln('Дата;Тип;Культура;Количество;Ед.изм.;Примечание');

    final byMonth = <int, List<DiaryEntry>>{};
    for (final entry in entries) {
      if (entry.date.year != year) continue;
      byMonth.putIfAbsent(entry.date.month, () => []).add(entry);
    }

    final months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];

    for (final month in byMonth.keys.toList()..sort()) {
      buffer.writeln('\n=== ${months[month - 1]} ===');
      for (final entry in byMonth[month]!) {
        buffer.writeln(
          '${entry.date.day}.${entry.date.month}.${entry.date.year};'
          '${_typeToString(entry.kind)};'
          '${entry.cropName};'
          '${entry.amount ?? ""};'
          '${entry.unit};'
          '${entry.note}',
        );
      }
    }

    buffer.writeln('\n=== СТАТИСТИКА ЗА $year ГОД ===');
    final stats = _calculateStats(entries, year);
    buffer.writeln('Всего записей: ${stats['totalEntries']}');
    buffer.writeln('Посадок: ${stats['plantings']}');
    buffer.writeln('Урожаев: ${stats['harvests']}');
    buffer.writeln('Заметок: ${stats['notes']}');

    return buffer.toString();
  }

  static Future<void> exportAndShare(
      {required int year, required List<DiaryEntry> entries}) async {
    try {
      final csv = generateCSV(year: year, entries: entries);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sadovnik_diary_$year.csv');
      await file.writeAsString(csv, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Дневник садовода $year',
        text: 'Экспорт дневника из СадовникPRO',
      );
    } catch (e) {
      debugPrint('❌ Ошибка экспорта: $e');
    }
  }

  static Map<String, dynamic> _calculateStats(
      List<DiaryEntry> entries, int year) {
    final filtered = entries.where((e) => e.date.year == year).toList();
    return {
      'totalEntries': filtered.length,
      'plantings': filtered.where((e) => e.kind == DiaryKind.planting).length,
      'harvests': filtered.where((e) => e.kind == DiaryKind.harvest).length,
      'notes': filtered.where((e) => e.kind == DiaryKind.note).length,
    };
  }

  static String _typeToString(DiaryKind type) {
    switch (type) {
      case DiaryKind.planting:
        return 'Посадка';
      case DiaryKind.harvest:
        return 'Урожай';
      case DiaryKind.note:
        return 'Заметка';
      case DiaryKind.care:
        return 'Уход';
    }
  }
}
