import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novgorod_skvoz_vremya/models/place.dart';
import 'package:novgorod_skvoz_vremya/widgets/then_now_slider.dart';

Place _place({String? old}) => Place(
      id: 'p',
      name: 'p',
      lat: 0,
      lon: 0,
      radius: 50,
      era: '',
      category: PlaceCategory.temple,
      short: '',
      history: '',
      whatHappened: '',
      activities: '',
      photoOld: old,
      photoNow: 'assets/photos/missing_now.jpg',
    );

Widget _wrap(Place place) =>
    MaterialApp(home: SizedBox(width: 400, height: 300, child: ThenNowSlider(place: place)));

void main() {
  testWidgets('без старого фото — только «сейчас», без слайдера', (tester) async {
    await tester.pumpWidget(_wrap(_place()));
    expect(find.text('Тогда'), findsNothing);
    expect(find.byIcon(Icons.compare_arrows), findsNothing);
  });

  testWidgets('со старым фото — слайдер «тогда / сейчас»', (tester) async {
    await tester.pumpWidget(_wrap(_place(old: 'assets/photos/missing_old.jpg')));
    expect(find.text('Тогда'), findsOneWidget);
    expect(find.text('Сейчас'), findsOneWidget);
    expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
  });
}
