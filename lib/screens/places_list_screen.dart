import 'package:flutter/material.dart';

import '../main.dart';
import '../services/geo.dart';
import '../theme.dart';
import 'place_screen.dart';

class PlacesListScreen extends StatelessWidget {
  const PlacesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final places = state.placesByDistance();
    final visited = state.visited;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Места'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Посещено ${visited.length} из ${places.length}'
                '${state.position == null ? '' : ' · сортировка по расстоянию'}',
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: places.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final place = places[i];
          final distance = state.distanceTo(place);
          final isVisited = visited.contains(place.id);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isVisited ? AppColors.visited : AppColors.cinnabar,
              foregroundColor: Colors.white,
              child: Icon(place.category.icon, size: 20),
            ),
            title: Text(place.name),
            subtitle: Text('${place.era} · ${place.short}', maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distance != null) Text(formatDistance(distance)),
                if (isVisited) const Icon(Icons.check_circle, color: AppColors.visited, size: 18),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: place)),
            ),
          );
        },
      ),
    );
  }
}
