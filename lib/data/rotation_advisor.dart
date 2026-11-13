import 'crop_catalog.dart';
import 'garden_store.dart';

class RotationAdvisor {
  static RotationAdvice checkRotation({
    required String cropId,
    required String plotId,
    required List<DiaryEntry> history,
  }) {
    final crop = CropCatalog.byId(cropId);
    if (crop == null) {
      return RotationAdvice(
          allowed: false,
          reason: 'Культура не найдена',
          level: AdviceLevel.error);
    }

    final plotHistory = history
        .where((e) => e.kind == DiaryKind.planting)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentCrops = <String>[];
    final now = DateTime.now();
    for (final entry in plotHistory) {
      if (now.difference(entry.date).inDays > 1460) break; // 4 года
      if (!recentCrops.contains(entry.cropId)) recentCrops.add(entry.cropId);
    }

    final family = crop.family;
    final sameFamilyCount = recentCrops.where((id) {
      final other = CropCatalog.byId(id);
      return other?.family == family;
    }).length;

    if (sameFamilyCount > 0) {
      return RotationAdvice(
        allowed: false,
        reason:
            'На этом участке в последние 3-4 года росли ${familyTitle(family)}. Посадите культуру из другого семейства.',
        level: AdviceLevel.warning,
        waitYears: 4 - sameFamilyCount,
      );
    }

    final badPredecessors = getBadPredecessors(family);
    final goodPredecessors = getGoodPredecessors(family);

    if (recentCrops.isNotEmpty) {
      final lastCrop = CropCatalog.byId(recentCrops.first);
      if (lastCrop != null) {
        if (badPredecessors.contains(lastCrop.family)) {
          return RotationAdvice(
            allowed: false,
            reason:
                '${lastCrop.name} — плохой предшественник для ${crop.name}.',
            level: AdviceLevel.error,
          );
        }
        if (goodPredecessors.contains(lastCrop.family)) {
          return RotationAdvice(
            allowed: true,
            reason: '${lastCrop.name} — отличный предшественник!',
            level: AdviceLevel.success,
          );
        }
      }
    }

    return RotationAdvice(
        allowed: true,
        reason: 'Участок свободен или давно не использовался',
        level: AdviceLevel.info);
  }

  static List<CropRecord> recommendCrops(
      {required String plotId, required List<DiaryEntry> history}) {
    final allCrops = CropCatalog.all;
    final scores = <CropRecord, int>{};

    for (final crop in allCrops) {
      int score = 0;
      final advice =
          checkRotation(cropId: crop.id, plotId: plotId, history: history);
      if (!advice.allowed) {
        score = -100;
      } else {
        if (advice.level == AdviceLevel.success) score += 50;
        score += 10;
        scores[crop] = score;
      }
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(10).toList();
  }

  static List<CropFamily> getBadPredecessors(CropFamily family) {
    switch (family) {
      case CropFamily.solanaceae:
        return [CropFamily.solanaceae];
      case CropFamily.brassicaceae:
        return [CropFamily.brassicaceae];
      case CropFamily.cucurbitaceae:
        return [CropFamily.cucurbitaceae];
      case CropFamily.apiaceae:
        return [CropFamily.apiaceae];
      case CropFamily.amaryllidaceae:
        return [CropFamily.amaryllidaceae];
      case CropFamily.asteraceae:
        return [CropFamily.asteraceae];
      case CropFamily.amaranthaceae:
        return [CropFamily.amaranthaceae];
      default:
        return [];
    }
  }

  static List<CropFamily> getGoodPredecessors(CropFamily family) {
    switch (family) {
      case CropFamily.solanaceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      case CropFamily.brassicaceae:
        return [CropFamily.fabaceae, CropFamily.solanaceae];
      case CropFamily.cucurbitaceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      case CropFamily.apiaceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      case CropFamily.amaryllidaceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      case CropFamily.fabaceae:
        return [CropFamily.brassicaceae, CropFamily.solanaceae];
      case CropFamily.asteraceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      case CropFamily.amaranthaceae:
        return [CropFamily.fabaceae, CropFamily.brassicaceae];
      default:
        return [CropFamily.fabaceae];
    }
  }

  static String familyTitle(CropFamily f) {
    switch (f) {
      case CropFamily.solanaceae:
        return 'паслёновые';
      case CropFamily.cucurbitaceae:
        return 'тыквенные';
      case CropFamily.brassicaceae:
        return 'капустные';
      case CropFamily.apiaceae:
        return 'зонтичные';
      case CropFamily.amaryllidaceae:
        return 'луковые';
      case CropFamily.fabaceae:
        return 'бобовые';
      case CropFamily.asteraceae:
        return 'астровые';
      case CropFamily.amaranthaceae:
        return 'амарантовые';
      case CropFamily.poaceae:
        return 'злаки';
      case CropFamily.polygonaceae:
        return 'гречишные';
      case CropFamily.lamiaceae:
        return 'яснотковые';
      case CropFamily.rosaceae:
        return 'розоцветные';
    }
  }
}

class RotationAdvice {
  final bool allowed;
  final String reason;
  final AdviceLevel level;
  final int? waitYears;
  const RotationAdvice(
      {required this.allowed,
      required this.reason,
      required this.level,
      this.waitYears});
}

enum AdviceLevel { success, info, warning, error }
