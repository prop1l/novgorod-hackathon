import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/place.dart';
import '../services/geo.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/proximity_checker.dart';
import '../services/storage.dart';

/// Общее состояние приложения: места, позиция, гид, демо-режим.
class AppState extends ChangeNotifier {
  AppState._(this.places, this.storage, this.notifications, this.location, this._demoTrack)
      : _checker = ProximityChecker(
          places: places,
          log: storage,
          radiusScale: storage.radiusScale,
        );

  static Future<AppState> load() async {
    final places = Place.listFromJson(await rootBundle.loadString('assets/data/places.json'));
    final track = jsonDecode(await rootBundle.loadString('assets/data/demo_track.json'))
        as Map<String, dynamic>;
    final points = (track['points'] as List)
        .map((p) => ((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final step = (track['step_meters'] as num).toDouble();
    return AppState._(
      places,
      await Storage.open(),
      NotificationService(),
      LocationService(),
      densifyTrack(points, step),
    );
  }

  final List<Place> places;
  final Storage storage;
  final NotificationService notifications;
  final LocationService location;
  final List<(double, double)> _demoTrack;
  final ProximityChecker _checker;

  LocationAccess access = LocationAccess.unknown;
  (double, double)? position;
  String? locationError;

  Timer? _demoTimer;
  int _demoIndex = 0;
  ProximityChecker? _demoChecker;

  bool get demoRunning => _demoTimer != null;
  double get demoProgress => _demoTrack.isEmpty ? 0 : _demoIndex / (_demoTrack.length - 1);
  bool get guideEnabled => storage.guideEnabled;
  double get radiusScale => storage.radiusScale;
  Set<String> get visited => storage.visited;

  Place? placeById(String id) {
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  double? distanceTo(Place place) {
    final pos = position;
    return pos == null ? null : haversineMeters(pos.$1, pos.$2, place.lat, place.lon);
  }

  List<Place> placesByDistance() {
    final list = List.of(places);
    if (position != null) {
      list.sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    }
    return list;
  }

  /// Проверяет разрешения и запускает гид, если он включён.
  Future<void> refreshAccess() async {
    access = await location.checkAccess();
    notifyListeners();
    await _syncTracking();
  }

  Future<void> requestAccess() async {
    access = await location.requestAccess();
    await notifications.requestPermission();
    notifyListeners();
    await _syncTracking();
  }

  Future<void> setGuideEnabled(bool value) async {
    storage.guideEnabled = value;
    notifyListeners();
    await _syncTracking();
  }

  void setRadiusScale(double value) {
    storage.radiusScale = value;
    _checker.radiusScale = value;
    notifyListeners();
  }

  void resetProgress() {
    storage.resetProgress();
    notifyListeners();
  }

  Future<void> _syncTracking() async {
    final shouldRun = guideEnabled && access.granted && !demoRunning;
    if (shouldRun && !location.running) {
      final last = await location.lastKnown();
      if (last != null) position ??= (last.latitude, last.longitude);
      location.start(_onRealPosition, onError: (e) {
        locationError = e.toString();
        notifyListeners();
      });
    } else if (!shouldRun && location.running) {
      location.stop();
    }
    notifyListeners();
  }

  void _onRealPosition(double lat, double lon) {
    locationError = null;
    _onPosition(lat, lon, _checker);
  }

  void _onPosition(double lat, double lon, ProximityChecker checker) {
    position = (lat, lon);
    final place = checker.check(lat, lon);
    if (place != null) {
      storage.markVisited(place.id);
      notifications.showPlace(place);
    }
    notifyListeners();
  }

  /// Демо-прогулка: фейковая позиция идёт по треку раз в секунду и шлёт настоящие пуши.
  void startDemo() {
    if (demoRunning) return;
    location.stop();
    _demoIndex = 0;
    _demoChecker = ProximityChecker(
      places: places,
      log: InMemoryNotificationLog(),
      placeCooldown: const Duration(days: 1),
      globalCooldown: const Duration(seconds: 6),
      radiusScale: radiusScale,
    );
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) => _demoTick());
    _demoTick();
  }

  void _demoTick() {
    if (_demoIndex >= _demoTrack.length) {
      stopDemo();
      return;
    }
    final (lat, lon) = _demoTrack[_demoIndex++];
    _onPosition(lat, lon, _demoChecker!);
  }

  void stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoChecker = null;
    notifyListeners();
    _syncTracking();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    location.stop();
    super.dispose();
  }
}
