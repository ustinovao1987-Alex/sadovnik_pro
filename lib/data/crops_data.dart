import 'crop_catalog.dart';

/// Модель культуры для интерфейса. Совместима со всеми экранами.
class Crop {
  final String name;
  final String emoji;
  final String description;

  const Crop({
    required this.name,
    required this.emoji,
    required this.description,
  });
}

/// Список культур строится из каталога — единственный источник правды.
final List<Crop> availableCrops = CropCatalog.all
    .map((r) => Crop(name: r.name, emoji: r.emoji, description: r.desc))
    .toList(growable: false);

/// Категории для фильтрации в каталоге.
Map<CropCategory, List<Crop>> get cropsByCategory {
  final map = <CropCategory, List<Crop>>{};
  for (final r in CropCatalog.all) {
    map.putIfAbsent(r.category, () => []).add(
          Crop(name: r.name, emoji: r.emoji, description: r.desc),
        );
  }
  return map;
}
