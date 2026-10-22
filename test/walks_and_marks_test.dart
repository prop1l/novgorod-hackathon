import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/models/walk.dart';
import 'package:novgorod_skvoz_vremya/services/geo.dart';
import 'package:novgorod_skvoz_vremya/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final places = Place.listFromJson(File('assets/data/places.json').readAsStringSync());
  final walks = Walk.listFromJson(File('assets/data/walks.json').readAsStringSync());
  final ids = places.map((p) => p.id).toSet();

  group('прогулки', () {
    test('три маршрута, все точки есть в каталоге и не повторяются', () {
      expect(walks, hasLength(3));
      expect(walks.map((w) => w.id).toSet(), hasLength(3));
      for (final w in walks) {
        expect(w.stops.toSet(), hasLength(w.stops.length), reason: w.id);
        for (final s in w.stops) {
          expect(ids, contains(s), reason: '${w.id} → $s');
        }
        expect(w.placesIn(places), hasLength(w.stops.length));
      }
    });

    test('длина и время правдоподобные для пешей прогулки', () {
      for (final w in walks) {
        final km = w.distanceMeters(places) / 1000;
        expect(km, inInclusiveRange(0.3, 5), reason: w.id);
        expect(w.durationMinutes(places), inInclusiveRange(20, 150), reason: w.id);
      }
    });

    test('Торговая сторона: 7 точек, начинается у моста', () {
      final w = walks.firstWhere((w) => w.id == 'torg_side');
      expect(w.stops.first, 'bridge');
      expect(w.stops, hasLength(7));
    });

    test('расстояние по-русски, с запятой', () {
      expect(formatDistance(850), '850 м');
      expect(formatDistance(1300), '1,3 км');
    });

    test('formatDuration', () {
      expect(formatDuration(45), '45 мин');
      expect(formatDuration(60), '1 ч');
      expect(formatDuration(75), '1 ч 15 мин');
    });

    test('пройденные точки хранятся отдельно для каждой прогулки и сбрасываются', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await Storage.open();
      s.activeWalk = 'torg_side';
      s.markWalkStop('torg_side', 'bridge');
      s.markWalkStop('detinets', 'kokuy');
      expect(s.walkStops('torg_side'), {'bridge'});
      s.clearWalk('torg_side');
      expect(s.walkStops('torg_side'), isEmpty);
      expect(s.walkStops('detinets'), {'kokuy'});
      s.resetProgress();
      expect(s.activeWalk, isNull);
      expect(s.walkStops('detinets'), isEmpty);
    });
  });

  group('разбор снимков', () {
    final withMarks = places.where((p) => p.marks.isNotEmpty).toList();

    test('разбор есть у каждого места', () {
      for (final p in places) {
        expect(p.marks, isNotEmpty, reason: p.id);
      }
    });

    test('номера уникальны, точки внутри кадра, у каждой есть хотя бы одна позиция', () {
      for (final p in withMarks) {
        if (p.marks.any((m) => m.old != null)) expect(p.photoOld, isNotNull, reason: p.id);
        if (p.marks.any((m) => m.now != null)) expect(p.photoNow, isNotNull, reason: p.id);
        expect(p.marks.map((m) => m.n).toSet(), hasLength(p.marks.length), reason: p.id);
        for (final m in p.marks) {
          expect(m.old != null || m.now != null, isTrue, reason: '${p.id} #${m.n}');
          for (final pt in [m.old, m.now]) {
            if (pt == null) continue;
            expect(pt.$1, inInclusiveRange(0, 1), reason: '${p.id} #${m.n}');
            expect(pt.$2, inInclusiveRange(0, 1), reason: '${p.id} #${m.n}');
          }
          expect(m.title, isNotEmpty);
        }
      }
    });

    test('в разборе встречаются все три статуса', () {
      final statuses = {for (final p in withMarks) for (final m in p.marks) m.status};
      expect(statuses, MarkStatus.values.toSet());
    });
  });
}
