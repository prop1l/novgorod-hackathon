import 'dart:convert';

import 'package:flutter/material.dart';

enum PlaceCategory {
  temple('Храм', Icons.church),
  fortress('Крепость', Icons.fort),
  square('Площадь', Icons.groups),
  monastery('Монастырь', Icons.temple_buddhist),
  monument('Памятник', Icons.account_balance),
  bridge('Мост', Icons.water),
  museum('Музей', Icons.museum);

  const PlaceCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static PlaceCategory parse(String value) => PlaceCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => PlaceCategory.square,
      );
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.radius,
    required this.era,
    required this.category,
    required this.short,
    required this.history,
    required this.whatHappened,
    required this.activities,
    this.photoOld,
    this.photoNow,
    this.photoCredit = '',
  });

  final String id;
  final String name;
  final double lat;
  final double lon;

  /// Радиус срабатывания уведомления, в метрах.
  final double radius;
  final String era;
  final PlaceCategory category;
  final String? photoOld;
  final String? photoNow;
  final String photoCredit;
  final String short;
  final String history;
  final String whatHappened;
  final String activities;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        radius: (json['radius'] as num).toDouble(),
        era: json['era'] as String,
        category: PlaceCategory.parse(json['category'] as String),
        photoOld: json['photo_old'] as String?,
        photoNow: json['photo_now'] as String?,
        photoCredit: (json['photo_credit'] as String?) ?? '',
        short: json['short'] as String,
        history: json['history'] as String,
        whatHappened: json['what_happened'] as String,
        activities: (json['activities'] as String?) ?? '',
      );

  static List<Place> listFromJson(String source) => (jsonDecode(source) as List)
      .map((e) => Place.fromJson(e as Map<String, dynamic>))
      .toList();
}
