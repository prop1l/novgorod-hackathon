import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/services/geo.dart';
import 'package:novgorod_skvoz_vremya/services/proximity_checker.dart';

void main() {
  test('демо-прогулка вызывает уведомления о местах центра', () {
    final places = Place.listFromJson(File('assets/data/places.json').readAsStringSync());
    final track = jsonDecode(File('assets/data/demo_track.json').readAsStringSync())
        as Map<String, dynamic>;
    final points = densifyTrack(
      [for (final p in track['points'] as List) ((p[0] as num).toDouble(), (p[1] as num).toDouble())],
      (track['step_meters'] as num).toDouble(),
    );

    // Те же настройки, что в AppState.startDemo: шаг раз в секунду, антиспам 6 с.
    var now = DateTime(2026, 10, 22, 12);
    final checker = ProximityChecker(
      places: places,
      log: InMemoryNotificationLog(),
      placeCooldown: const Duration(days: 1),
      globalCooldown: const Duration(seconds: 6),
      clock: () => now,
    );
    final notified = <String>[];
    for (final (lat, lon) in points) {
      final place = checker.check(lat, lon);
      if (place != null) notified.add(place.id);
      now = now.add(const Duration(seconds: 1));
    }

    expect(notified.toSet(), hasLength(notified.length), reason: 'без повторов');
    expect(notified, containsAll(['kokuy', 'sofia', 'bridge', 'ilyina_spas']));
    expect(notified.length, greaterThanOrEqualTo(8), reason: notified.join(', '));
    // Прогулка укладывается в несколько минут — удобно на защите.
    expect(points.length, lessThan(400));
  });
}
