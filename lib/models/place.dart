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

/// Что стало с деталью старого снимка.
enum MarkStatus {
  kept('Сохранилось', Color(0xFF22A06B)),
  changed('Перестроено', Color(0xFF1B6EF1)),
  lost('Утрачено', Color(0xFFD64545));

  const MarkStatus(this.label, this.color);

  final String label;
  final Color color;

  static MarkStatus parse(String v) => switch (v) {
        'kept' => kept,
        'lost' => lost,
        _ => changed,
      };
}

/// Точка разбора снимка: одна деталь, отмеченная на старом и (если уцелела) на новом фото.
/// Координаты — доли ширины и высоты кадра, 0…1.
class PhotoMark {
  const PhotoMark({
    required this.n,
    required this.status,
    required this.title,
    required this.text,
    this.old,
    this.now,
  });

  final int n;
  final MarkStatus status;
  final String title;
  final String text;
  final (double, double)? old;
  final (double, double)? now;

  static (double, double)? _point(Object? v) =>
      v is List ? ((v[0] as num).toDouble(), (v[1] as num).toDouble()) : null;

  factory PhotoMark.fromJson(Map<String, dynamic> json) => PhotoMark(
        n: json['n'] as int,
        status: MarkStatus.parse(json['status'] as String),
        title: json['title'] as String,
        text: (json['text'] as String?) ?? '',
        old: _point(json['old']),
        now: _point(json['now']),
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
    this.marks = const [],
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

  /// Разбор снимка «что сохранилось, что перестроено, что исчезло».
  final List<PhotoMark> marks;

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
        marks: [
          for (final m in (json['marks'] as List?) ?? const [])
            PhotoMark.fromJson(m as Map<String, dynamic>),
        ],
      );

  static List<Place> listFromJson(String source) => (jsonDecode(source) as List)
      .map((e) => Place.fromJson(e as Map<String, dynamic>))
      .toList();
}
