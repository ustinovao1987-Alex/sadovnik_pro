import 'package:flutter/material.dart';

/// Виджет для отображения иконки культуры.
/// Сначала пытается загрузить PNG из assets/icons/{id}.png.
/// Если файла нет, отображает стандартный эмодзи.
class CropIcon extends StatelessWidget {
  final String id;
  final String emoji;
  final double size;

  const CropIcon({
    super.key,
    required this.id,
    required this.emoji,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$id.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Если картинки нет, показываем эмодзи
        return Text(
          emoji,
          style: TextStyle(fontSize: size),
        );
      },
    );
  }
}
