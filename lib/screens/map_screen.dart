import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../models/place.dart';
import '../services/geo.dart';
import '../services/location_service.dart';
import '../theme.dart';
import '../widgets/permission_banner.dart';
import '../widgets/place_image.dart';
import 'place_screen.dart';

const _mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
const _novgorodCenter = LatLng(58.5215, 31.2755);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  bool _followDemo = true;

  void _whereAmI() {
    final state = AppScope.read(context);
    final pos = state.position;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.access.granted
            ? 'Ищем вас… Выйдите на открытое место.'
            : 'Геолокация выключена — разрешите её, чтобы увидеть себя на карте.'),
      ));
      return;
    }
    _map.move(LatLng(pos.$1, pos.$2), 17);
  }

  void _showPreview(Place place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PlacePreview(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pos = state.position;
    final visited = state.visited;

    if (state.demoRunning && _followDemo && pos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.move(LatLng(pos.$1, pos.$2), _map.camera.zoom);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _novgorodCenter,
              initialZoom: 15,
              minZoom: 11,
              maxZoom: 19,
              onPositionChanged: (_, hasGesture) {
                if (hasGesture) _followDemo = false;
              },
            ),
            children: [
              _tileLayer(),
              CircleLayer(circles: [
                for (final p in state.places)
                  CircleMarker(
                    point: LatLng(p.lat, p.lon),
                    radius: p.radius * state.radiusScale,
                    useRadiusInMeter: true,
                    color: AppColors.cinnabar.withValues(alpha: 0.06),
                    borderColor: AppColors.cinnabar.withValues(alpha: 0.25),
                    borderStrokeWidth: 1,
                  ),
              ]),
              MarkerLayer(markers: [
                for (final p in state.places)
                  Marker(
                    point: LatLng(p.lat, p.lon),
                    width: 44,
                    height: 44,
                    child: _PlaceMarker(
                      place: p,
                      visited: visited.contains(p.id),
                      onTap: () => _showPreview(p),
                    ),
                  ),
                if (pos != null)
                  Marker(
                    point: LatLng(pos.$1, pos.$2),
                    width: 28,
                    height: 28,
                    child: const _MeMarker(),
                  ),
              ]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const PermissionBanner(),
                  if (state.demoRunning) _DemoBar(progress: state.demoProgress),
                ],
              ),
            ),
          ),
          const Positioned(left: 0, bottom: 0, child: _Attribution()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'demo',
            tooltip: 'Демо-прогулка',
            onPressed: () {
              if (state.demoRunning) {
                state.stopDemo();
              } else {
                _followDemo = true;
                state.startDemo();
              }
            },
            child: Icon(state.demoRunning ? Icons.stop : Icons.directions_walk),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'me',
            tooltip: 'Где я',
            onPressed: _whereAmI,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _tileLayer() {
    if (_mapTilerKey.isNotEmpty) {
      return TileLayer(
        urlTemplate: 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}@2x.png?key={key}',
        additionalOptions: const {'key': _mapTilerKey},
        userAgentPackageName: 'ru.novgorod.skvoz_vremya',
        maxNativeZoom: 20,
      );
    }
    // Без ключа — тайлы OSM, годятся только для разработки.
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'ru.novgorod.skvoz_vremya',
      maxNativeZoom: 19,
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: Colors.white.withValues(alpha: 0.8),
      child: Text(
        _mapTilerKey.isNotEmpty
            ? '© MapTiler © OpenStreetMap contributors'
            : '© OpenStreetMap contributors',
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.place, required this.visited, required this.onTap});

  final Place place;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: visited ? AppColors.visited : AppColors.cinnabar,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Icon(place.category.icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MeMarker extends StatelessWidget {
  const _MeMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
      ),
    );
  }
}

class _DemoBar extends StatelessWidget {
  const _DemoBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: AppColors.cinnabar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Демо-прогулка по центру'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePreview extends StatelessWidget {
  const _PlacePreview({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final distance = state.distanceTo(place);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: 160, child: PlaceImage(place: place, asset: place.photoOld)),
          ),
          const SizedBox(height: 12),
          Text(place.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            [
              place.category.label,
              place.era,
              if (distance != null) formatDistance(distance),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(place.short),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..push(MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: place)));
            },
            child: const Text('Подробнее'),
          ),
        ],
      ),
    );
  }
}
