import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme.dart';

/// «Что на снимке»: номера на старом и новом фото и список — что сохранилось, перестроено, утрачено.
class PhotoBreakdown extends StatefulWidget {
  const PhotoBreakdown({super.key, required this.place});

  final Place place;

  @override
  State<PhotoBreakdown> createState() => _PhotoBreakdownState();
}

class _PhotoBreakdownState extends State<PhotoBreakdown> {
  bool _showOld = true;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final hasOld = place.photoOld != null && place.marks.any((m) => m.old != null);
    final hasNow = place.photoNow != null && place.marks.any((m) => m.now != null);
    // Если разметка есть только на одном снимке (нет старого фото) — показываем его без переключателя.
    final showOld = hasOld && (_showOld || !hasNow);
    final asset = showOld ? place.photoOld! : place.photoNow!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasOld && hasNow)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Тогда')),
              ButtonSegment(value: false, label: Text('Сейчас')),
            ],
            selected: {showOld},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _showOld = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.accent,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.text,
              textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w500),
            ),
          ),
        if (hasOld && hasNow) const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: MarkedPhoto(
            asset: asset,
            marks: [
              for (final m in place.marks)
                if ((showOld ? m.old : m.now) case final pos?) (m, pos),
            ],
            selected: _selected,
            onTap: (n) => setState(() => _selected = _selected == n ? null : n),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final s in MarkStatus.values)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(s.label, style: AppText.caption),
              ]),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in place.marks)
          _MarkRow(
            mark: m,
            selected: _selected == m.n,
            hiddenHere: (showOld ? m.old : m.now) == null,
            onTap: () => setState(() => _selected = _selected == m.n ? null : m.n),
          ),
      ],
    );
  }
}

/// Фото целиком (без обрезки, чтобы точки совпадали с деталями) с номерами поверх.
class MarkedPhoto extends StatefulWidget {
  const MarkedPhoto({super.key, required this.asset, required this.marks, this.selected, this.onTap});

  final String asset;
  final List<(PhotoMark, (double, double))> marks;
  final int? selected;
  final ValueChanged<int>? onTap;

  @override
  State<MarkedPhoto> createState() => _MarkedPhotoState();
}

class _MarkedPhotoState extends State<MarkedPhoto> {
  double? _aspect;
  ImageStream? _stream;
  late final _listener = ImageStreamListener((info, _) {
    if (mounted) setState(() => _aspect = info.image.width / info.image.height);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(MarkedPhoto old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = AssetImage(widget.asset).resolve(createLocalImageConfiguration(context))..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspect ?? 4 / 3,
      child: LayoutBuilder(builder: (context, c) {
        return Stack(
          children: [
            Positioned.fill(child: Image.asset(widget.asset, fit: BoxFit.fill)),
            for (final (m, (x, y)) in widget.marks)
              Positioned(
                key: ValueKey(m.n),
                left: x * c.maxWidth - 15,
                top: y * c.maxHeight - 15,
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(m.n),
                  child: _MarkDot(mark: m, selected: widget.selected == m.n),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _MarkDot extends StatelessWidget {
  const _MarkDot({required this.mark, required this.selected});

  final PhotoMark mark;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mark.status.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: selected ? 4 : 2),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black45)],
      ),
      child: Text('${mark.n}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({required this.mark, required this.selected, required this.hiddenHere, required this.onTap});

  final PhotoMark mark;
  final bool selected;
  final bool hiddenHere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: mark.status.color, shape: BoxShape.circle),
              child: Text('${mark.n}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mark.title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    hiddenHere && mark.status == MarkStatus.lost
                        ? '${mark.status.label} — на современном снимке этого нет'
                        : mark.status.label,
                    style: AppText.caption.copyWith(color: mark.status.color),
                  ),
                  if (mark.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(mark.text, style: AppText.small),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
