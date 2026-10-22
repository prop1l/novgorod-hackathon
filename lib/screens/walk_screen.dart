import 'package:flutter/material.dart';

import '../main.dart';
import '../models/place.dart';
import '../models/walk.dart';
import '../services/geo.dart';
import '../theme.dart';
import '../widgets/place_image.dart';
import 'home_screen.dart';
import 'place_screen.dart';

class WalkScreen extends StatelessWidget {
  const WalkScreen({super.key, required this.walk});

  final Walk walk;

  void _goToMap(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    homeTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final stops = walk.placesIn(state.places);
    final isActive = state.activeWalk?.id == walk.id;
    final done = isActive ? state.walkDone(walk) : const <String>{};
    final next = isActive ? state.nextStop(walk) : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Text(walk.title, style: AppText.h2),
          const SizedBox(height: 8),
          Text(walk.description, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          WalkStats(walk: walk),
          if (isActive) ...[
            const SizedBox(height: 16),
            WalkProgressBar(done: done.length, total: stops.length),
          ],
          const SizedBox(height: 20),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  state.startWalk(walk);
                  _goToMap(context);
                },
                icon: const Icon(Icons.directions_walk),
                label: Text(state.activeWalk == null ? 'Начать прогулку' : 'Начать эту прогулку'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _goToMap(context),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Продолжить на карте'),
              ),
            ),
            TextButton(onPressed: state.stopWalk, child: const Text('Завершить прогулку')),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < stops.length; i++)
            _StopRow(
              index: i + 1,
              place: stops[i],
              done: done.contains(stops[i].id),
              isNext: next?.id == stops[i].id,
              distanceFromPrev: i == 0
                  ? null
                  : haversineMeters(stops[i - 1].lat, stops[i - 1].lon, stops[i].lat, stops[i].lon),
              isLast: i == stops.length - 1,
            ),
        ],
      ),
    );
  }
}

/// «7 точек · 1,9 км · 1 ч 10 мин» и эпоха снимков.
class WalkStats extends StatelessWidget {
  const WalkStats({super.key, required this.walk, this.onDark = false});

  final Walk walk;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final places = AppScope.of(context).places;
    final color = onDark ? AppColors.accentSoft : AppColors.accent;
    Widget item(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppText.caption.copyWith(color: onDark ? AppColors.onDark : AppColors.text)),
        ]);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(Icons.place_outlined, '${walk.placesIn(places).length} точек'),
        item(Icons.straighten, formatDistance(walk.distanceMeters(places))),
        item(Icons.schedule, formatDuration(walk.durationMinutes(places))),
        item(Icons.photo_camera_back_outlined, 'снимки ${walk.era}'),
      ],
    );
  }
}

class WalkProgressBar extends StatelessWidget {
  const WalkProgressBar({super.key, required this.done, required this.total, this.onDark = false});

  final int done;
  final int total;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              color: done == total ? AppColors.visited : AppColors.accent,
              backgroundColor: onDark ? AppColors.surfaceDark : AppColors.accentSoft,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$done из $total',
            style: AppText.caption.copyWith(color: onDark ? AppColors.onDark : AppColors.text)),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.index,
    required this.place,
    required this.done,
    required this.isNext,
    required this.distanceFromPrev,
    required this.isLast,
  });

  final int index;
  final Place place;
  final bool done;
  final bool isNext;
  final double? distanceFromPrev;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.visited : (isNext ? AppColors.accent : AppColors.textSecondary);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: place))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done || isNext ? color : AppColors.card,
                      shape: BoxShape.circle,
                      border: done || isNext ? null : Border.all(color: AppColors.border, width: 2),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text('$index',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isNext ? Colors.white : AppColors.textSecondary,
                            )),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(width: 56, height: 56, child: PlaceImage(place: place, asset: place.photoOld ?? place.photoNow)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(place.name, style: AppText.h3.copyWith(fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (isNext) 'Следующая',
                              if (distanceFromPrev != null) '+${formatDistance(distanceFromPrev!)}',
                              if (place.marks.isNotEmpty) 'разбор снимка',
                            ].join(' · '),
                            style: AppText.caption.copyWith(color: isNext ? AppColors.accent : null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
