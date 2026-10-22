import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../models/place.dart';
import '../models/walk.dart';
import '../services/geo.dart';
import '../services/location_service.dart';
import '../theme.dart';
import '../widgets/permission_banner.dart';
import '../widgets/place_image.dart';
import 'place_screen.dart';
import 'walk_screen.dart';

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
  String? _fittedWalk;

  /// При старте прогулки показываем весь маршрут.
  void _fitWalk(Walk walk, List<Place> stops) {
    if (_fittedWalk == walk.id || stops.length < 2) return;
    _fittedWalk = walk.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map.fitCamera(CameraFit.coordinates(
        coordinates: [for (final p in stops) LatLng(p.lat, p.lon)],
        padding: const EdgeInsets.fromLTRB(48, 220, 48, 220),
      ));
    });
  }

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlacePreview(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pos = state.position;
    final visited = state.visited;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final walk = state.activeWalk;
    final stops = walk?.placesIn(state.places) ?? const <Place>[];
    final stopIndex = {for (var i = 0; i < stops.length; i++) stops[i].id: i + 1};
    final walkDone = walk == null ? const <String>{} : state.walkDone(walk);
    final next = walk == null ? null : state.nextStop(walk);
    if (walk != null) {
      _fitWalk(walk, stops);
    } else {
      _fittedWalk = null;
    }

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
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderColor: AppColors.accent.withValues(alpha: 0.3),
                    borderStrokeWidth: 1,
                  ),
                if (pos != null)
                  CircleMarker(
                    point: LatLng(pos.$1, pos.$2),
                    radius: 40,
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
              ]),
              if (stops.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [for (final p in stops) LatLng(p.lat, p.lon)],
                    color: AppColors.accent,
                    strokeWidth: 5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ]),
              MarkerLayer(markers: [
                for (final p in state.places)
                  if (stopIndex[p.id] case final n?)
                    Marker(
                      point: LatLng(p.lat, p.lon),
                      width: next?.id == p.id ? 48 : 38,
                      height: next?.id == p.id ? 48 : 38,
                      child: _StopMarker(
                        number: n,
                        done: walkDone.contains(p.id),
                        isNext: next?.id == p.id,
                        onTap: () => _showPreview(p),
                      ),
                    )
                  else
                    Marker(
                      point: LatLng(p.lat, p.lon),
                      width: 44,
                      height: 44,
                      child: Opacity(
                        opacity: walk == null ? 1 : 0.45,
                        child: _PlaceMarker(
                          place: p,
                          visited: visited.contains(p.id),
                          onTap: () => _showPreview(p),
                        ),
                      ),
                    ),
                if (pos != null)
                  Marker(
                    point: LatLng(pos.$1, pos.$2),
                    width: 22,
                    height: 22,
                    child: const _MeMarker(),
                  ),
              ]),
            ],
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const PermissionBanner(),
                  if (walk != null) _WalkBar(walk: walk, stops: stops, done: walkDone, next: next),
                  if (state.demoRunning) _DemoBar(progress: state.demoProgress),
                ],
              ),
            ),
          ),
          Positioned(left: 0, bottom: bottomInset, child: const _Attribution()),
          Positioned(
            right: 20,
            bottom: bottomInset + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundButton(
                  size: 44,
                  background: AppColors.card,
                  foreground: AppColors.accent,
                  icon: state.demoRunning ? Icons.stop : Icons.directions_walk,
                  tooltip: state.demoRunning ? 'Остановить демо' : 'Демо-прогулка',
                  onTap: () {
                    if (state.demoRunning) {
                      state.stopDemo();
                    } else {
                      _followDemo = true;
                      state.startDemo();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _RoundButton(
                  size: 56,
                  background: AppColors.accent,
                  foreground: Colors.white,
                  icon: Icons.my_location,
                  tooltip: 'Где я',
                  onTap: _whereAmI,
                ),
              ],
            ),
          ),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final Color background;
  final Color foreground;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: AppColors.bgDark.withValues(alpha: 0.4),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: foreground)),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: Colors.white.withValues(alpha: 0.85),
      child: Text(
        _mapTilerKey.isNotEmpty
            ? '© MapTiler © OpenStreetMap contributors'
            : '© OpenStreetMap contributors',
        style: const TextStyle(fontSize: 10, color: AppColors.text),
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
          color: visited ? AppColors.visited : AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black26)],
        ),
        child: Icon(place.category.icon, color: Colors.white, size: 22),
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
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black38)],
      ),
    );
  }
}

class _DemoBar extends StatelessWidget {
  const _DemoBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: AppColors.onDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Демо-прогулка по центру',
                    style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surfaceDark,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(height: 170, child: PlaceImage(place: place, asset: place.photoOld ?? place.photoNow)),
          ),
          const SizedBox(height: 14),
          Text(place.name, style: AppText.h2.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            [place.category.label, place.era, if (distance != null) formatDistance(distance)].join(' · '),
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          Text(place.short, style: AppText.body),
          const SizedBox(height: 18),
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

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.number, required this.done, required this.isNext, required this.onTap});

  final int number;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? AppColors.visited : (isNext ? AppColors.accent : AppColors.bgDark),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black38)],
        ),
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text('$number',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isNext ? 18 : 15)),
      ),
    );
  }
}

class _WalkBar extends StatelessWidget {
  const _WalkBar({required this.walk, required this.stops, required this.done, required this.next});

  final Walk walk;
  final List<Place> stops;
  final Set<String> done;
  final Place? next;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final n = next;
    final dist = n == null ? null : state.distanceTo(n);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WalkScreen(walk: walk))),
                  child: Text(walk.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w600)),
                ),
              ),
              IconButton(
                tooltip: 'Завершить прогулку',
                visualDensity: VisualDensity.compact,
                onPressed: state.stopWalk,
                icon: const Icon(Icons.close, color: AppColors.onDark, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (n != null)
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: n))),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Следующая: ', style: TextStyle(color: AppColors.accentSoft)),
                  TextSpan(text: '${stops.indexOf(n) + 1}. ${n.name}'),
                  if (dist != null) TextSpan(text: ' · ${formatDistance(dist)}', style: const TextStyle(color: AppColors.accentSoft)),
                ]),
                maxLines: 2,
                style: const TextStyle(color: AppColors.onDark, fontSize: 14),
              ),
            )
          else
            const Text('Прогулка пройдена! Все точки отмечены.',
                style: TextStyle(color: AppColors.onDark, fontSize: 14)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WalkProgressBar(done: done.length, total: stops.length, onDark: true),
          ),
        ],
      ),
    );
  }
}
