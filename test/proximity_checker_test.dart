import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/services/geo.dart';
import 'package:novgorod_skvoz_vremya/services/proximity_checker.dart';

Place _place(String id, double lat, double lon, {double radius = 50}) => Place(
      id: id,
      name: id,
      lat: lat,
      lon: lon,
      radius: radius,
      era: '',
      category: PlaceCategory.temple,
      short: '',
      history: '',
      whatHappened: '',
      activities: '',
    );

void main() {
  group('haversineMeters', () {
    test('ноль для одной точки', () {
      expect(haversineMeters(58.52, 31.27, 58.52, 31.27), 0);
    });

    test('Софийский собор → памятник Тысячелетию ≈ 140 м', () {
      final d = haversineMeters(58.52212, 31.27672, 58.52113, 31.27529);
      expect(d, closeTo(138, 8));
    });

    test('один градус широты ≈ 111 км', () {
      expect(haversineMeters(58, 31, 59, 31), closeTo(111195, 50));
    });
  });

  group('densifyTrack', () {
    test('шаг не больше заданного и концы совпадают', () {
      final track = densifyTrack([(58.5200, 31.2700), (58.5210, 31.2700)], 10);
      expect(track.first, (58.5200, 31.2700));
      expect(track.last.$1, closeTo(58.5210, 1e-9));
      for (var i = 1; i < track.length; i++) {
        final (a, b) = track[i - 1];
        final (c, d) = track[i];
        expect(haversineMeters(a, b, c, d), lessThanOrEqualTo(10.01));
      }
    });
  });

  group('ProximityChecker', () {
    late DateTime now;
    late ProximityChecker checker;
    final sofia = _place('sofia', 58.52212, 31.27672);
    final monument = _place('monument', 58.52113, 31.27529);

    setUp(() {
      now = DateTime(2026, 10, 22, 12);
      checker = ProximityChecker(
        places: [sofia, monument],
        log: InMemoryNotificationLog(),
        clock: () => now,
      );
    });

    test('срабатывает внутри радиуса', () {
      expect(checker.check(58.52212, 31.27672), sofia);
    });

    test('молчит вне радиуса', () {
      expect(checker.check(58.5300, 31.2900), isNull);
    });

    test('глобальный антиспам: второй пуш не раньше чем через 2 минуты', () {
      expect(checker.check(58.52212, 31.27672), sofia);
      now = now.add(const Duration(seconds: 30));
      expect(checker.check(58.52113, 31.27529), isNull);
      now = now.add(const Duration(minutes: 2));
      expect(checker.check(58.52113, 31.27529), monument);
    });

    test('кулдаун места 12 часов', () {
      expect(checker.check(58.52212, 31.27672), sofia);
      now = now.add(const Duration(hours: 1));
      expect(checker.check(58.52212, 31.27672), isNull);
      now = now.add(const Duration(hours: 12));
      expect(checker.check(58.52212, 31.27672), sofia);
    });

    test('выбирает ближайшее из перекрывающихся мест', () {
      final big = ProximityChecker(
        places: [
          _place('far', 58.52212, 31.27672, radius: 500),
          _place('near', 58.52113, 31.27529, radius: 500),
        ],
        log: InMemoryNotificationLog(),
        clock: () => now,
      );
      expect(big.check(58.52110, 31.27530)?.id, 'near');
    });

    test('radiusScale расширяет зону', () {
      // ~111 м севернее собора, радиус 50 м
      expect(checker.check(58.52312, 31.27672), isNull);
      checker.radiusScale = 3;
      expect(checker.check(58.52312, 31.27672), sofia);
    });
  });
}
