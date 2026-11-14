import 'package:flutter/material.dart';
import '../data/crops_data.dart';

/// Универсальный виджет для отображения изображения культуры.
/// Если для культуры есть фото в assets/icons, показывает его.
/// Иначе показывает эмодзи.
class CropImage extends StatelessWidget {
  final Crop crop;
  final double size;
  final BoxFit fit;

  const CropImage({
    super.key,
    required this.crop,
    this.size = 52,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Формируем путь к файлу на основе id культуры
    // Например, для 'tomato' путь будет 'assets/icons/tomato.png'
    final imagePath = 'assets/icons/${crop.id}.png';

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(size * 0.27), // Скругление как у карточек
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: fit,
        // Если файла нет, показываем эмодзи
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                crop.emoji,
                style: TextStyle(fontSize: size * 0.6),
              ),
            ),
          );
        },
      ),
    );
  }
}
