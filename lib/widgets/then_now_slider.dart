import 'package:flutter/material.dart';

import '../models/place.dart';
import 'place_image.dart';

/// Два фото друг на друге: тянешь ручку — видишь, как было и как стало.
class ThenNowSlider extends StatefulWidget {
  const ThenNowSlider({super.key, required this.place});

  final Place place;

  @override
  State<ThenNowSlider> createState() => _ThenNowSliderState();
}

class _ThenNowSliderState extends State<ThenNowSlider> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      void update(Offset local) =>
          setState(() => _split = (local.dx / width).clamp(0.0, 1.0));
      return GestureDetector(
        onHorizontalDragUpdate: (d) => update(d.localPosition),
        onTapDown: (d) => update(d.localPosition),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlaceImage(
              place: place,
              asset: place.photoNow,
              label: 'Сейчас',
              labelAlignment: Alignment.bottomRight,
            ),
            ClipRect(
              clipper: _LeftClipper(_split),
              child: PlaceImage(place: place, asset: place.photoOld, label: 'Тогда'),
            ),
            Positioned(
              left: width * _split - 18,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 3, color: Colors.white),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.compare_arrows, size: 20, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.fraction != fraction;
}
