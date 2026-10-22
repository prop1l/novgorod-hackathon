import '../models/place.dart';
import 'geo.dart';

/// Где хранить, когда и о каком месте уже уведомляли.
abstract class NotificationLog {
  DateTime? lastNotified(String placeId);
  DateTime? get lastAnyNotified;
  void markNotified(String placeId, DateTime at);
}

class InMemoryNotificationLog implements NotificationLog {
  final Map<String, DateTime> _byPlace = {};
  DateTime? _last;

  @override
  DateTime? lastNotified(String placeId) => _byPlace[placeId];

  @override
  DateTime? get lastAnyNotified => _last;

  @override
  void markNotified(String placeId, DateTime at) {
    _byPlace[placeId] = at;
    _last = at;
  }
}

/// На каждое обновление GPS решает, о каком месте (если о каком-то) пора уведомить.
class ProximityChecker {
  ProximityChecker({
    required this.places,
    required this.log,
    this.placeCooldown = const Duration(hours: 12),
    this.globalCooldown = const Duration(minutes: 2),
    this.radiusScale = 1.0,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final List<Place> places;
  final NotificationLog log;
  final Duration placeCooldown;
  final Duration globalCooldown;
  double radiusScale;
  final DateTime Function() _clock;

  /// Возвращает ближайшее место в радиусе, о котором можно уведомить, и отмечает его.
  Place? check(double lat, double lon) {
    final now = _clock();
    final last = log.lastAnyNotified;
    if (last != null && now.difference(last) < globalCooldown) return null;

    Place? best;
    var bestDistance = double.infinity;
    for (final place in places) {
      final d = haversineMeters(lat, lon, place.lat, place.lon);
      if (d >= place.radius * radiusScale || d >= bestDistance) continue;
      final placeLast = log.lastNotified(place.id);
      if (placeLast != null && now.difference(placeLast) < placeCooldown) continue;
      best = place;
      bestDistance = d;
    }
    if (best != null) log.markNotified(best.id, now);
    return best;
  }
}
