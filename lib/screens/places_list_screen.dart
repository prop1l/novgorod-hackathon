import 'package:flutter/material.dart';

import '../main.dart';
import '../services/geo.dart';
import '../theme.dart';
import '../widgets/place_image.dart';
import 'place_screen.dart';

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
