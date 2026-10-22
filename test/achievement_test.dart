import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/achievement.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/services/geo.dart';
import 'package:novgorod_skvoz_vremya/services/proximity_checker.dart';
import 'package:novgorod_skvoz_vremya/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final places = Place.listFromJson(File('assets/data/places.json').readAsStringSync());
  final ids = places.map((p) => p.id).toSet();
  AchievementProgress p(String id, Set<String> visited) => achievementById(id)!.progress(visited, places);

  test('у достижений уникальные id и существующие места', () {
    expect(achievements.map((a) => a.id).toSet(), hasLength(achievements.length));
    for (final a in achievements) {
      for (final id in a.placeIds ?? const <String>{}) {
        expect(ids, contains(id), reason: '${a.id} → $id');
      }
      expect(a.progress(const {}, places).target, greaterThan(0), reason: a.id);
    }
  });

  test('ничего не получено без посещений, всё — когда посещено всё', () {
    for (final a in achievements) {
      expect(a.progress(const {}, places).unlocked, isFalse, reason: a.id);
      expect(a.progress(ids, places).unlocked, isTrue, reason: a.id);
    }
  });

  test('набор мест: Знаток Детинца', () {
    expect(p('detinets', {'sofia', 'kokuy'}).done, 2);
    expect(p('detinets', {'sofia', 'kokuy'}).target, 6);
    expect(p('detinets', {'kremlin', 'sofia', 'millennium', 'granovitaya', 'kokuy', 'vhod_ierusalim'}).unlocked, isTrue);
  });

  test('категория: Паломник — 5 храмов, монастыри не считаются', () {
    final temples = places.where((x) => x.category == PlaceCategory.temple).map((x) => x.id).toList();
    expect(p('pilgrim', {...temples.take(4), 'yuriev'}).done, 4);
    expect(p('pilgrim', temples.take(5).toSet()).unlocked, isTrue);
    expect(p('pilgrim', temples.toSet()).done, 5, reason: 'прогресс не больше цели');
  });

  test('количество: Первый шаг и Хранитель истории', () {
    expect(p('first_step', {'bridge'}).unlocked, isTrue);
    expect(p('keeper', ids.take(20).toSet()).unlocked, isFalse);
    expect(p('keeper', ids).target, places.length);
  });

  test('полученные достижения сохраняются и сбрасываются вместе с прогрессом', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    final first = DateTime(2026, 10, 22, 12);
    storage.markAchievements(['first_step'], first);
    storage.markAchievements(['first_step', 'bridge'], DateTime(2026, 10, 23));
    expect(storage.unlockedAchievements.keys, unorderedEquals(['first_step', 'bridge']));
    expect(storage.unlockedAchievements['first_step'], first, reason: 'дата первого получения не меняется');
    storage.resetProgress();
    expect(storage.unlockedAchievements, isEmpty);
  });

  test('демо-прогулка открывает достижения для показа на защите', () {
    final track = jsonDecode(File('assets/data/demo_track.json').readAsStringSync()) as Map<String, dynamic>;
    final points = densifyTrack(
      [for (final x in track['points'] as List) ((x[0] as num).toDouble(), (x[1] as num).toDouble())],
      (track['step_meters'] as num).toDouble(),
    );
    var now = DateTime(2026, 10, 22, 12);
    final checker = ProximityChecker(
      places: places,
      log: InMemoryNotificationLog(),
      placeCooldown: const Duration(days: 1),
      globalCooldown: const Duration(seconds: 6),
      clock: () => now,
    );
    final visited = <String>{};
    for (final (lat, lon) in points) {
      final place = checker.check(lat, lon);
      if (place != null) visited.add(place.id);
      now = now.add(const Duration(seconds: 1));
    }
    final unlocked = [for (final a in achievements) if (a.progress(visited, places).unlocked) a.id];
    expect(unlocked, containsAll(['first_step', 'torgovaya', 'bridge', 'explorer']), reason: visited.join(', '));
  });
}
