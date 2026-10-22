import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/services/geo.dart';

void main() {
  final places = Place.listFromJson(File('assets/data/places.json').readAsStringSync());

  test('в каталоге 21 место с уникальными id', () {
    expect(places, hasLength(21));
    expect(places.map((p) => p.id).toSet(), hasLength(21));
  });

  test('все места в пределах 5 км от центра Великого Новгорода', () {
    for (final p in places) {
      expect(haversineMeters(58.5215, 31.2755, p.lat, p.lon), lessThan(5000), reason: p.id);
    }
  });

  test('у каждого места заполнены тексты и радиус', () {
    for (final p in places) {
      expect(p.radius, inInclusiveRange(20, 300), reason: p.id);
      expect(p.short, isNotEmpty, reason: p.id);
      expect(p.history, isNotEmpty, reason: p.id);
      expect(p.whatHappened, isNotEmpty, reason: p.id);
    }
  });

  test('у каждого существующего фото указан источник', () {
    for (final p in places) {
      final hasPhoto = [p.photoOld, p.photoNow].any((f) => f != null && File(f).existsSync());
      if (hasPhoto) expect(p.photoCredit, isNotEmpty, reason: p.id);
    }
  });
}
