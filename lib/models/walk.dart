import 'dart:convert';

import '../services/geo.dart';
import 'place.dart';

/// Прогулка: маршрут по местам в заданном порядке.
class Walk {
  const Walk({
    required this.id,
    required this.title,
    required this.era,
    required this.description,
    required this.stops,
  });

  final String id;
  final String title;

  /// Время, к которому относятся снимки маршрута, например «1880–1910-е».
  final String era;
  final String description;

  /// id мест по порядку обхода.
  final List<String> stops;

  static const walkingSpeedKmh = 4.5;
  static const minutesPerStop = 7;

  factory Walk.fromJson(Map<String, dynamic> json) => Walk(
        id: json['id'] as String,
        title: json['title'] as String,
        era: json['era'] as String,
        description: json['description'] as String,
        stops: [for (final s in json['stops'] as List) s as String],
      );

  static List<Walk> listFromJson(String source) => (jsonDecode(source) as List)
      .map((e) => Walk.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Места маршрута по порядку (неизвестные id пропускаются).
  List<Place> placesIn(List<Place> places) => [
        for (final id in stops)
          for (final p in places)
            if (p.id == id) p,
      ];

  /// Длина маршрута по прямой между остановками, в метрах.
  double distanceMeters(List<Place> places) {
    final ps = placesIn(places);
    var sum = 0.0;
    for (var i = 1; i < ps.length; i++) {
      sum += haversineMeters(ps[i - 1].lat, ps[i - 1].lon, ps[i].lat, ps[i].lon);
    }
    return sum;
  }

  /// Примерное время: шаг 4,5 км/ч плюс несколько минут на каждую точку.
  int durationMinutes(List<Place> places) {
    final walking = distanceMeters(places) / 1000 / walkingSpeedKmh * 60;
    return (walking + placesIn(places).length * minutesPerStop).round();
  }
}

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes мин';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h ч' : '$h ч $m мин';
}
