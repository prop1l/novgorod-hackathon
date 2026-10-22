import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme.dart';

/// Фото места из assets; если файла нет — заглушка с иконкой категории.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.place, required this.asset, this.label});

  final Place place;
  final String? asset;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final path = asset;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (path == null)
          _placeholder()
        else
          Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder()),
        if (label != null)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.ochre, AppColors.cinnabar],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(place.category.icon, size: 72, color: Colors.white70),
      );
}
