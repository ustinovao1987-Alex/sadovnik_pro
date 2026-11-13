import 'planting_calendar.dart';

/// Одна работа в ленте: культура + этап + когда.
class WorkItem {
  final String cropName;
  final PlantingStage stage;
  final bool isActive; // окно открыто прямо сейчас
  final int daysUntil; // дней до начала (если не активно)

  const WorkItem({
    required this.cropName,
    required this.stage,
    required this.isActive,
    required this.daysUntil,
  });
}

/// Лента ближайших работ по всем культурам региона.
class WorkAgenda {
  /// Собирает и сортирует работы: сначала активные, потом по близости.
  static List<WorkItem> build(DateTime now, {int horizonDays = 400}) {
    final items = <WorkItem>[];
    for (final cal in kPlantingCalendars) {
      for (final s in cal.stages) {
        final active = s.contains(now);
        final d = s.daysUntilStart(now);
        if (active || d <= horizonDays) {
          items.add(WorkItem(
            cropName: cal.name,
            stage: s,
            isActive: active,
            daysUntil: d,
          ));
        }
      }
    }
    items.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.daysUntil.compareTo(b.daysUntil);
    });
    return items;
  }

  /// Правильное склонение: 1 день, 2 дня, 5 дней.
  static String daysWord(int n) {
    final n10 = n % 10;
    final n100 = n % 100;
    if (n10 == 1 && n100 != 11) return 'день';
    if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) return 'дня';
    return 'дней';
  }
}
