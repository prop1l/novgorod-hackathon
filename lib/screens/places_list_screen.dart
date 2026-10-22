import 'package:flutter/material.dart';

import '../main.dart';
import '../models/achievement.dart';
import '../models/walk.dart';
import '../services/geo.dart';
import '../theme.dart';
import '../widgets/place_image.dart';
import 'achievements_screen.dart';
import 'place_screen.dart';
import 'walk_screen.dart';

class PlacesListScreen extends StatelessWidget {
  const PlacesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final places = state.placesByDistance();
    final visited = state.visited;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.paddingOf(context).bottom + 24),
          itemCount: places.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Места', style: AppText.screenTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Посещено ${visited.length} из ${places.length}'
                      '${state.position == null ? '' : ' · по расстоянию'}',
                      style: AppText.small.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: 20),
                    const Text('Прогулки', style: AppText.h3),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: state.walks.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => _WalkCard(walk: state.walks[i]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AchievementsEntry(unlocked: state.unlockedAchievements.length),
                    const SizedBox(height: 12),
                    const Text('Все места', style: AppText.h3),
                  ],
                ),
              );
            }
            final place = places[i - 1];
            final distance = state.distanceTo(place);
            final isVisited = visited.contains(place.id);
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: place)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: PlaceImage(place: place, asset: place.photoNow ?? place.photoOld),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: AppText.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            [place.era, if (distance != null) formatDistance(distance)].join(' · '),
                            style: AppText.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(place.short, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    isVisited
                        ? const Icon(Icons.check_circle, color: AppColors.visited, size: 22)
                        : const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AchievementsEntry extends StatelessWidget {
  const _AchievementsEntry({required this.unlocked});

  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Достижения',
                        style: AppText.body.copyWith(color: AppColors.onDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Получено $unlocked из ${achievements.length}',
                        style: AppText.caption.copyWith(color: AppColors.accentSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.onDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkCard extends StatelessWidget {
  const _WalkCard({required this.walk});

  final Walk walk;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.activeWalk?.id == walk.id;
    final total = walk.placesIn(state.places).length;
    return SizedBox(
      width: 280,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WalkScreen(walk: walk))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: active ? Border.all(color: AppColors.accent, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.route_outlined, color: AppColors.accent, size: 20),
                  const SizedBox(width: 6),
                  Text(active ? 'Идёт прогулка' : 'Прогулка',
                      style: AppText.caption.copyWith(color: AppColors.accent)),
                ]),
                const SizedBox(height: 6),
                Text(walk.title, style: AppText.h3.copyWith(fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                if (active)
                  WalkProgressBar(done: state.walkDone(walk).length, total: total)
                else
                  WalkStats(walk: walk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
