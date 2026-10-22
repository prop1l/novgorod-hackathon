import 'dart:math' as math;

const double _earthRadiusMeters = 6371000;

/// Расстояние между двумя точками по формуле гаверсинусов, в метрах.
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(a)));
}

double _rad(double deg) => deg * math.pi / 180;

/// Разбивает ломаную на точки через каждые [stepMeters] — для демо-прогулки.
List<(double, double)> densifyTrack(List<(double, double)> points, double stepMeters) {
  if (points.length < 2) return List.of(points);
  final result = <(double, double)>[points.first];
  for (var i = 1; i < points.length; i++) {
    final (lat1, lon1) = points[i - 1];
    final (lat2, lon2) = points[i];
    final segment = haversineMeters(lat1, lon1, lat2, lon2);
    final steps = math.max(1, (segment / stepMeters).ceil());
    for (var s = 1; s <= steps; s++) {
      final t = s / steps;
      result.add((lat1 + (lat2 - lat1) * t, lon1 + (lon2 - lon1) * t));
    }
  }
  return result;
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} м';
  return '${(meters / 1000).toStringAsFixed(1)} км';
}
